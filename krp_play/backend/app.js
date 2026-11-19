require('dotenv').config();
const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
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
    if (!isValidBillplzSignature(req.body)) {
        console.warn('⚠️ Rejected webhook with invalid X Signature');
        return res.status(403).send('Invalid signature');
    }

    const {
        id: billplzId,
        paid,
        state,
        paid_amount: paidAmount,
        paid_at: paidAt,
        transaction_id: transactionId,
    } = req.body;

    if (paid !== 'true' || state !== 'paid') {
        return res.status(200).send('OK'); // Not paid (yet); nothing to do.
    }

    try {
        const { data: payment, error: paymentError } = await supabase
            .from('payments')
            .select('id, booking_id, amount, status')
            .eq('billplz_id', billplzId)
            .maybeSingle();

        if (paymentError) throw paymentError;
        if (!payment) {
            console.warn(`⚠️ Paid callback for unknown bill ${billplzId}`);
            return res.status(200).send('OK');
        }
        if (payment.status === 'paid') {
            return res.status(200).send('OK'); // Billplz retries callbacks; already handled.
        }

        const expectedCents = Math.round(Number(payment.amount) * 100);
        if (Number(paidAmount) !== expectedCents) {
            console.error(`❌ Bill ${billplzId}: paid ${paidAmount} cents, expected ${expectedCents}. Needs manual review.`);
            return res.status(200).send('OK');
        }

        const { error: payUpdateError } = await supabase
            .from('payments')
            .update({
                status: 'paid',
                paid_at: paidAt ? new Date(paidAt).toISOString() : new Date().toISOString(),
                transaction_reference: transactionId || billplzId,
            })
            .eq('id', payment.id);
        if (payUpdateError) throw payUpdateError;

        // Only confirm a booking that is still holding its slots.
        const { data: confirmed, error: bookingUpdateError } = await supabase
            .from('bookings')
            .update({ status: 'confirmed' })
            .eq('id', payment.booking_id)
            .eq('status', 'pending_payment')
            .select('id');
        if (bookingUpdateError) throw bookingUpdateError;

        if (!confirmed?.length) {
            console.error(`❌ Booking ${payment.booking_id} was paid (bill ${billplzId}) but is no longer pending. Needs refund/manual review.`);
            return res.status(200).send('OK');
        }

        const { error: itemsUpdateError } = await supabase
            .from('booking_items')
            .update({ status: 'confirmed' })
            .eq('booking_id', payment.booking_id)
            .eq('status', 'pending_payment');
        if (itemsUpdateError) throw itemsUpdateError;

        console.log(`✅ Booking ${payment.booking_id} CONFIRMED (bill ${billplzId}).`);
        res.status(200).send('OK');
    } catch (error) {
        console.error('❌ [WEBHOOK ERROR]:', error.message);
        // Non-2xx makes Billplz retry the callback later.
        res.status(500).send('Error');
    }
});

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

app.get('/health', (_req, res) => res.json({ ok: true }));

app.listen(PORT, () => {
    console.log(`🚀 Payment backend listening on port ${PORT}`);
});
