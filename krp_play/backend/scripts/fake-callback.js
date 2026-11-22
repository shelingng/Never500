// SCRUM-79 test tool: sends a signed Billplz-style callback to the local backend.
// Usage (from krp_play/backend):
//   node scripts/fake-callback.js <billplz_id> <paid_cents> [paid|failed] [badsig|othercollection]
require('dotenv').config();
const crypto = require('crypto');

const [billId, cents, outcome = 'paid', mode] = process.argv.slice(2);
if (!billId || !cents) {
    console.log('Usage: node scripts/fake-callback.js <billplz_id> <paid_cents> [paid|failed] [badsig|othercollection]');
    process.exit(1);
}
const paid = outcome === 'paid';

const params = {
    id: billId,
    collection_id: mode === 'othercollection' ? 'someone-else' : process.env.BILLPLZ_COLLECTION_ID,
    paid: String(paid),
    state: paid ? 'paid' : 'due',
    amount: cents,
    paid_amount: paid ? cents : '0',
    paid_at: new Date().toISOString(),
    transaction_id: `TEST-${Date.now()}`,
    transaction_status: paid ? 'completed' : 'failed',
};

// Same signing rule as isValidBillplzSignature in app.js.
const source = Object.keys(params)
    .map((key) => `${key}${params[key]}`)
    .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()))
    .join('|');
params.x_signature = crypto.createHmac('sha256', process.env.BILLPLZ_X_SIGNATURE_KEY).update(source).digest('hex');
if (mode === 'badsig') params.x_signature = 'tampered';

fetch(`http://localhost:${process.env.PORT || 3000}/api/webhook`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(params),
})
    .then(async (r) => console.log(`HTTP ${r.status}: ${await r.text()}`))
    .catch((e) => console.error('Request failed:', e.message));