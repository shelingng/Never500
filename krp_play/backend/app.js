require('dotenv').config();
const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const nodemailer = require('nodemailer');
const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
const REQUIRED_ENV = [
    'SUPABASE_URL',
    'SUPABASE_KEY',
    'BILLPLZ_SECRET_KEY',
    'BILLPLZ_X_SIGNATURE_KEY',
    'BILLPLZ_COLLECTION_ID',
    'BILLPLZ_CALLBACK_URL',
    'BILLPLZ_REDIRECT_URL',
];
const missing = REQUIRED_ENV.filter((name) => !process.env[name]);
if (missing.length) {
    console.error(`❌ Missing environment variables: ${missing.join(', ')}`);
    process.exit(1);
}

const PORT = Number(process.env.PORT) || 3000;
const BILLPLZ_API_BASE_URL = (process.env.BILLPLZ_API_BASE_URL || 'https://www.billplz-sandbox.com/api/v3').replace(/\/+$/, '');
const billplzAuth = { auth: { username: process.env.BILLPLZ_SECRET_KEY, password: '' } };
const RECONCILE_EVERY_MS = 2 * 60 * 1000; // SCRUM-80: check uncertain payments every 2 minutes
// Service-role client: bypasses RLS, so it must only ever live on this server.
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
});

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Resolve the signed-in Supabase user from the "Authorization: Bearer <jwt>" header.
async function getUserFromRequest(req) {
    const header = req.get('authorization') || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) return null;
    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data?.user) return null;
    return data.user;
}

const mailer = nodemailer.createTransport({
    service: 'gmail',
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
});

// SCRUM-18: email the confirmation once. Runs after the booking is confirmed,
// so a failure here never undoes the payment; it can be retried later.
async function sendConfirmationEmail(bookingId) {
    const { data: booking, error } = await supabase
        .from('bookings')
        .select(`id, user_id, booking_reference, total_amount, status, confirmation_email_sent_at,
                booking_items(price, time_slots(slot_date, start_time, facilities(name))),
                payments(status, paid_at, transaction_reference, billplz_id)`)
        .eq('id', bookingId)
        .maybeSingle();
    if (error) throw error;
    if (!booking || booking.status !== 'confirmed') return 'not_confirmed';
    if (booking.confirmation_email_sent_at) return 'already_sent';

    const { data: userData, error: userError } = await supabase.auth.admin.getUserById(booking.user_id);
    if (userError || !userData?.user?.email) throw userError || new Error('User has no email');

    const sessions = (booking.booking_items || [])
        .map((item) => item.time_slots)
        .filter(Boolean)
        .sort((a, b) => `${a.slot_date} ${a.start_time}`.localeCompare(`${b.slot_date} ${b.start_time}`))
        .map((s) => `- ${s.facilities?.name || 'Facility'}: ${s.slot_date}, ${String(s.start_time).slice(0, 5)} (1 hour)`)
        .join('\n');
    const paid = (booking.payments || []).find((p) => p.status === 'paid');

    await mailer.sendMail({
        from: `"KRP Play" <${process.env.SMTP_USER}>`,
        to: userData.user.email,
        subject: `Booking confirmed: ${booking.booking_reference}`,
        text: [
            `Your booking ${booking.booking_reference} is confirmed.`,
            '',
            'Sessions:',
            sessions,
            '',
            `Amount paid: RM${Number(booking.total_amount).toFixed(2)}`,
            `Payment ref: ${paid?.transaction_reference || paid?.billplz_id || '-'}`,
            `Paid at: ${paid?.paid_at ? new Date(paid.paid_at).toLocaleString('en-MY') : '-'}`,
        ].join('\n'),
    });

    await supabase
        .from('bookings')
        .update({ confirmation_email_sent_at: new Date().toISOString() })
        .eq('id', booking.id);
    return 'sent';
}

// Log what confirm_billplz_payment decided (used by the webhook and the reconcile job).
function logPaymentResult(billplzId, result, paidAmount) {
    switch (result) {
        case 'confirmed':
            return console.log(`✅ Booking for bill ${billplzId} CONFIRMED.`);
        case 'confirmed_late':
            return console.log(`✅ Late payment for bill ${billplzId}: sessions still free, booking CONFIRMED.`);
        case 'refund_required':
            return console.error(`💸 Late payment for bill ${billplzId}: session no longer available. Refund opened.`);
        case 'already_paid':
            return console.log(`↩️ Repeated result for bill ${billplzId}; already handled.`);
        case 'amount_mismatch':
            return console.error(`❌ Bill ${billplzId}: paid ${paidAmount} cents does not match. Needs manual review.`);
        default:
            return console.warn(`⚠️ Paid result for unknown bill ${billplzId}`);
    }
}

// Billplz X Signature: every param except x_signature becomes "key+value",
// sorted case-insensitively, joined with "|", then HMAC-SHA256 with the
// X Signature key. https://www.billplz.com/api#x-signature
function isValidBillplzSignature(params) {
    const received = params.x_signature;
    if (typeof received !== 'string') return false;

    const source = Object.keys(params)
        .filter((key) => key !== 'x_signature')
        .map((key) => `${key}${params[key] ?? ''}`)
        .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()))
        .join('|');

    const expected = crypto
        .createHmac('sha256', process.env.BILLPLZ_X_SIGNATURE_KEY)
        .update(source)
        .digest('hex');

    const a = Buffer.from(expected, 'utf8');
    const b = Buffer.from(received, 'utf8');
    return a.length === b.length && crypto.timingSafeEqual(a, b);
}

// ---------------------------------------------------------------------------
// SCRUM-17: Create a Billplz bill for a reserved booking
// ---------------------------------------------------------------------------
// The amount is read from the booking created by reserve_cart
// (database/atomic_checkout.sql); the client only sends which booking to pay.
app.post('/api/create-payment', async (req, res) => {
    try {
        const user = await getUserFromRequest(req);
        if (!user) return res.status(401).json({ error: 'Not signed in' });

        const { bookingId } = req.body;
        if (!bookingId) return res.status(400).json({ error: 'Missing bookingId' });

        const { data: booking, error: bookingError } = await supabase
            .from('bookings')
            .select('id, user_id, booking_reference, total_amount, status, payment_deadline')
            .eq('id', bookingId)
            .eq('user_id', user.id)
            .maybeSingle();

        if (bookingError) {
            console.error('❌ [SUPABASE ERROR]:', bookingError.message);
            return res.status(500).json({ error: 'Could not load booking' });
        }
        if (!booking) return res.status(404).json({ error: 'Booking not found' });
        if (booking.status !== 'pending_payment') {
            return res.status(409).json({ error: `Booking is ${booking.status}, not awaiting payment` });
        }
        if (booking.payment_deadline && new Date(booking.payment_deadline) <= new Date()) {
            return res.status(409).json({ error: 'Payment window has expired. Please check out again.' });
        }

        const amountCents = Math.round(Number(booking.total_amount) * 100);
        if (!Number.isFinite(amountCents) || amountCents <= 0) {
            return res.status(409).json({ error: 'Booking has no payable amount' });
        }

        // Reuse an unpaid bill for this booking instead of creating duplicates.
        const { data: existing } = await supabase
            .from('payments')
            .select('billplz_id')
            .eq('booking_id', booking.id)
            .eq('status', 'pending')
            .not('billplz_id', 'is', null)
            .order('created_at', { ascending: false })
            .limit(1)
            .maybeSingle();
        if (existing?.billplz_id) {
            try {
                const { data: bill } = await axios.get(`${BILLPLZ_API_BASE_URL}/bills/${existing.billplz_id}`, {
                    auth: { username: process.env.BILLPLZ_SECRET_KEY, password: '' },
                });
                if (bill.state === 'due' && Number(bill.amount) === amountCents) {
                    return res.status(200).json({ paymentUrl: bill.url, billId: bill.id });
                }
            } catch (lookupError) {
                console.warn(`⚠️ Could not reuse bill ${existing.billplz_id}:`, lookupError.response?.data || lookupError.message);
            }
        }

        const { data: profile } = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();

        const params = new URLSearchParams();
        params.append('collection_id', process.env.BILLPLZ_COLLECTION_ID);
        params.append('email', user.email);
        params.append('name', profile?.full_name || user.email);
        params.append('amount', String(amountCents));
        params.append('description', `KRP Booking Ref: ${booking.booking_reference || booking.id}`);
        params.append('callback_url', process.env.BILLPLZ_CALLBACK_URL);
        params.append('redirect_url', process.env.BILLPLZ_REDIRECT_URL);
        params.append('reference_1_label', 'Booking ID');
        params.append('reference_1', String(booking.id));

        const response = await axios.post(`${BILLPLZ_API_BASE_URL}/bills`, params, {
            auth: { username: process.env.BILLPLZ_SECRET_KEY, password: '' },
        });

        const { id: billplzId, url: paymentUrl } = response.data;

        const { error: insertError } = await supabase.from('payments').insert([{
            booking_id: booking.id,
            billplz_id: billplzId,
            amount: booking.total_amount,
            // Must match payments_payment_method_allowed_check (e.g. fpx, touch_n_go_ewallet).
            payment_method: 'fpx',
            payment_gateway: 'billplz',
            status: 'pending',
        }]);

        if (insertError) {
            console.error('❌ [SUPABASE ERROR]:', insertError.message);
            return res.status(500).json({ error: 'Could not record payment' });
        }

        console.log(`✅ Bill ${billplzId} created for booking ${booking.id}`);
        res.status(200).json({ paymentUrl, billId: billplzId });
    } catch (error) {
        console.error('❌ [CREATE PAYMENT ERROR]:', error.response?.data || error.message);
        res.status(502).json({ error: 'Payment creation failed' });
    }
});

// ---------------------------------------------------------------------------
// SCRUM-18: Billplz callback (server-to-server)
// ---------------------------------------------------------------------------
app.post('/api/webhook', async (req, res) => {
    // 1. Authenticity: the X Signature proves the callback came from Billplz.
    if (!isValidBillplzSignature(req.body)) {
        console.warn('⚠️ Rejected webhook with invalid X Signature');
        return res.status(403).send('Invalid signature');
    }

    const {
        id: billplzId,
        collection_id: collectionId,
        paid,
        state,
        paid_amount: paidAmount,
        paid_at: paidAt,
        transaction_id: transactionId,
    } = req.body;

    // 2. Reference: only accept bills from our own collection.
    if (collectionId !== process.env.BILLPLZ_COLLECTION_ID) {
        console.warn(`⚠️ Ignored callback for bill ${billplzId} from another collection (${collectionId})`);
        return res.status(200).send('OK');
    }

    // 3. Only trusted success changes anything. Failed/out-of-order callbacks are ignored.
    if (paid !== 'true' || state !== 'paid') {
        return res.status(200).send('OK');
    }

    try {
        // 4. Amount check + payment + booking + items saved in ONE transaction
        //    (database/confirm_payment.sql). Repeats return 'already_paid'.
        const { data: result, error } = await supabase.rpc('confirm_billplz_payment', {
            p_billplz_id: billplzId,
            p_paid_cents: Number(paidAmount),
            p_paid_at: paidAt ? new Date(paidAt).toISOString() : new Date().toISOString(),
            p_transaction_ref: transactionId || billplzId,
        });
        if (error) throw error;

        logPaymentResult(billplzId, result, paidAmount);
        res.status(200).send('OK');

        if (result === 'confirmed' || result === 'confirmed_late') {
            sendConfirmationEmailForBill(billplzId);
        }
    } catch (error) {
        console.error('❌ [WEBHOOK ERROR]:', error.message);
        // Non-2xx makes Billplz retry; the transaction means nothing was half-saved.
        res.status(500).send('Error');
    }
});

// SCRUM-18 email, sent after the reply; a failure only gets logged.
async function sendConfirmationEmailForBill(billplzId) {
    try {
        const { data: payment } = await supabase
            .from('payments').select('booking_id').eq('billplz_id', billplzId).maybeSingle();
        if (!payment) return;
        const result = await sendConfirmationEmail(payment.booking_id);
        console.log(`📧 Confirmation email for ${payment.booking_id}: ${result}`);
    } catch (err) {
        console.error(`❌ [EMAIL ERROR] bill ${billplzId}:`, err.message);
    }
}

// ---------------------------------------------------------------------------
// Payment status for the app's "check status" button
// ---------------------------------------------------------------------------
// Booking confirmation still only comes from the signed webhook. This endpoint
// additionally reports the latest Billplz attempt so the app can show "failed".
app.get('/api/payment-status/:bookingId', async (req, res) => {
    try {
        const user = await getUserFromRequest(req);
        if (!user) return res.status(401).json({ error: 'Not signed in' });

        const { data: booking, error: bookingError } = await supabase
            .from('bookings')
            .select('id, status, payment_deadline')
            .eq('id', req.params.bookingId)
            .eq('user_id', user.id)
            .maybeSingle();
        if (bookingError) throw bookingError;
        if (!booking) return res.status(404).json({ error: 'Booking not found' });

        const result = {
            bookingStatus: booking.status,
            paymentDeadline: booking.payment_deadline,
            lastAttempt: null, // 'completed' | 'failed' | 'pending' | null
        };
        if (booking.status === 'confirmed') return res.json(result);

        const { data: payment } = await supabase
            .from('payments')
            .select('billplz_id')
            .eq('booking_id', booking.id)
            .not('billplz_id', 'is', null)
            .order('created_at', { ascending: false })
            .limit(1)
            .maybeSingle();

        if (payment?.billplz_id) {
            const { data } = await axios.get(
                `${BILLPLZ_API_BASE_URL}/bills/${payment.billplz_id}/transactions`,
                { auth: { username: process.env.BILLPLZ_SECRET_KEY, password: '' } },
            );
            const attempts = [...(data.transactions || [])].sort((a, b) =>
                String(b.completed_at || '').localeCompare(String(a.completed_at || '')));
            result.lastAttempt = attempts[0]?.status || null;
        }
        res.json(result);
    } catch (error) {
        console.error('❌ [PAYMENT STATUS ERROR]:', error.response?.data || error.message);
        res.status(502).json({ error: 'Could not check payment status' });
    }
});

// Where Billplz sends the user's browser after paying (BILLPLZ_REDIRECT_URL).
// Display only: the booking is confirmed by the signed webhook, not by this page.
app.get('/payment/complete', (req, res) => {
    // Express 5's default query parser keeps "billplz[paid]" as a flat key.
    const paid = (req.query['billplz[paid]'] ?? req.query.billplz?.paid) === 'true';
    const title = paid ? 'Payment successful' : 'Payment not completed';
    const message = paid
        ? 'Your booking will be confirmed shortly. You can return to the app.'
        : 'Your payment did not go through. Return to the app to try again.';
    res.send(`<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title></head>
<body style="font-family:sans-serif;text-align:center;padding:48px 16px">
<h1>${paid ? '✅' : '❌'} ${title}</h1><p>${message}</p></body></html>`);
});

// SCRUM-18: retry a confirmation email that failed earlier.
app.post('/api/resend-confirmation/:bookingId', async (req, res) => {
    const user = await getUserFromRequest(req);
    if (!user) return res.status(401).json({ error: 'Not signed in' });

    const { data: booking } = await supabase
        .from('bookings')
        .select('id')
        .eq('id', req.params.bookingId)
        .eq('user_id', user.id)
        .maybeSingle();
    if (!booking) return res.status(404).json({ error: 'Booking not found' });

    try {
        res.json({ result: await sendConfirmationEmail(booking.id) });
    } catch (err) {
        console.error('❌ [EMAIL ERROR]:', err.message);
        res.status(502).json({ error: 'Email could not be sent. Try again later.' });
    }
});

// ---------------------------------------------------------------------------
// SCRUM-80: resolve pending, expired and late-success payments
// ---------------------------------------------------------------------------
// Callbacks can be lost (backend or tunnel down), so we also ask Billplz
// directly. Billplz's own bill record is the evidence; the app's word is never used.
let reconciling = false;

async function reconcilePayments() {
    if (reconciling) return; // the previous run is still going
    reconciling = true;
    try {
        // 1. Release holds whose 10 minutes are over.
        const { data: released, error: expireError } = await supabase.rpc('expire_unpaid_bookings');
        if (expireError) throw expireError;
        if (released) console.log(`⏰ Released ${released} expired hold(s).`);

        // 2. Check every bill we still think is unpaid (last 2 days).
        const since = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString();
        const { data: pending, error } = await supabase
            .from('payments')
            .select('billplz_id, bookings(status)')
            .eq('status', 'pending')
            .not('billplz_id', 'is', null)
            .gte('created_at', since);
        if (error) throw error;

        for (const p of pending || []) {
            try {
                const { data: bill } = await axios.get(`${BILLPLZ_API_BASE_URL}/bills/${p.billplz_id}`, billplzAuth);

                if (bill.paid) {
                    // Paid on Billplz but we never got the callback.
                    const { data: tx } = await axios.get(
                        `${BILLPLZ_API_BASE_URL}/bills/${bill.id}/transactions`, billplzAuth);
                    const done = (tx.transactions || []).find((t) => t.status === 'completed');
                    const { data: result, error: rpcError } = await supabase.rpc('confirm_billplz_payment', {
                        p_billplz_id: bill.id,
                        p_paid_cents: Number(bill.paid_amount),
                        p_paid_at: done?.completed_at ? new Date(done.completed_at).toISOString() : new Date().toISOString(),
                        p_transaction_ref: done?.id || bill.id,
                    });
                    if (rpcError) throw rpcError;
                    console.log(`🔎 Recovered missed callback for bill ${bill.id}`);
                    logPaymentResult(bill.id, result, bill.paid_amount);
                    if (result === 'confirmed' || result === 'confirmed_late') {
                        sendConfirmationEmailForBill(bill.id);
                    }
                } else if (bill.state === 'due' && p.bookings?.status !== 'pending_payment') {
                    // Hold is gone: close the bill so nobody can pay for it late.
                    await axios.delete(`${BILLPLZ_API_BASE_URL}/bills/${bill.id}`, billplzAuth);
                    console.log(`🗑️ Closed unpaid bill ${bill.id} (booking is ${p.bookings?.status}).`);
                }
            } catch (err) {
                console.error(`❌ [RECONCILE] bill ${p.billplz_id}:`, err.response?.data || err.message);
            }
        }
    } catch (err) {
        console.error('❌ [RECONCILE ERROR]:', err.message);
    } finally {
        reconciling = false;
    }
}

app.get('/health', (_req, res) => res.json({ ok: true }));

app.listen(PORT, () => {
    console.log(`🚀 Payment backend listening on port ${PORT}`);
    reconcilePayments(); // once at start-up, then every 2 minutes
    setInterval(reconcilePayments, RECONCILE_EVERY_MS);
});
