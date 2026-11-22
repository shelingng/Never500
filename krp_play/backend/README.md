# Payment backend (Billplz sandbox)

Small Express server that creates Billplz bills, receives the Billplz
payment callback and confirms bookings in Supabase. It holds the secret keys,
so the Flutter app never sees them.

| Endpoint | Purpose |
|---|---|
| `POST /api/create-payment` | Creates a Billplz bill for a `pending_payment` booking (needs the user's Supabase token) |
| `POST /api/webhook` | Billplz callback; checks the X Signature, then marks the payment `paid` and the booking `confirmed` |
| `GET /api/payment-status/:bookingId` | Lets the app check the booking and the last payment attempt |
| `GET /payment/complete` | Page the user's browser lands on after paying |
| `GET /health` | Returns `{"ok":true}` to show the server is up |

## 1. Billplz sandbox account

1. Sign up at https://www.billplz-sandbox.com (separate from live Billplz, fake money).
2. **Settings → Keys & Integration**: copy the **API Secret Key** and the
   **X Signature Key** (switch X Signature on if it is off).
3. **Billing → Collections → Create Collection**: copy the **Collection ID**.

## 2. Stable public URL with ngrok

Billplz has to reach the callback from the internet, so `localhost` is not enough.

1. Sign up at https://dashboard.ngrok.com and run once:
   ```powershell
   ngrok config add-authtoken <your-authtoken>
   ```
2. In the ngrok dashboard, open **Domains** and claim your free static domain
   (for example `something.ngrok-free.dev`). It stays the same every time, so
   `.env` does not need changing after a restart.

## 3. Create `.env`

**Copy** (do not rename) the example file, so `.env.example` stays in git:

```powershell
cd krp_play/backend
copy .env.example .env
```

Fill in the values. The two URLs use your ngrok domain:

```
BILLPLZ_CALLBACK_URL=https://<your-ngrok-domain>/api/webhook
BILLPLZ_REDIRECT_URL=https://<your-ngrok-domain>/payment/complete
```

`.env` is ignored by git. Never commit it: it contains the Billplz secret key
and the Supabase `service_role` key, which bypasses Row Level Security.

## 4. Run it

Terminal 1 (backend):
```powershell
cd krp_play/backend
npm install
npm start
```
Expect `🚀 Payment backend listening on port 3000`. If it says
`Missing environment variables`, a value in `.env` is empty.

Terminal 2 (tunnel):
```powershell
ngrok http --url=<your-ngrok-domain> 3000
```

Check: open `https://<your-ngrok-domain>/health` and click through ngrok's
warning page. You should see `{"ok":true}`.

Terminal 3 (app):
```powershell
cd krp_play
.\run_web.ps1
```
This points the app at `http://localhost:3000`. On a real phone, pass the
ngrok URL instead: `.\run_web.ps1 https://<your-ngrok-domain>`.

## 5. Test a sandbox payment

1. Check out a booking in the app; the Billplz sandbox page opens.
2. Pick any bank and choose **success** (or **failure** to test the unpaid path).
3. On success: the backend logs `✅ Booking ... CONFIRMED`, the `payments` row is
   `paid` and the `bookings` row is `confirmed`.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `Payment creation failed` / 401 from Billplz | Wrong secret key, or a live key used with the sandbox URL |
| `Rejected webhook with invalid X Signature` | Wrong X Signature key, or X Signature is off in Billplz |
| Paid but booking stays `pending_payment` | ngrok not running, or wrong `BILLPLZ_CALLBACK_URL`; restart `npm start` after editing `.env` |
| `ERR_NGROK_...` when starting ngrok | The `--url` domain is not the one claimed on your ngrok account |

## Payment request security (SCRUM-77)

`POST /api/create-payment` in `app.js`:

| Check | Code | Tested result |
|---|---|---|
| Must be signed in | app.js line 84 | No token → 401 |
| Only the booking owner can pay | app.js line 93 | Other user's booking → 404 |
| Hold must not be expired | app.js line 104 | Expired booking → 409 |
| Amount calculated by server | app.js line 108, from `bookings.total_amount` set by `reserve_cart` (database/atomic_checkout.sql) | Sent `"amount": 1` → ignored, Billplz showed the real price |
| Payment method and gateway reference saved | app.js lines 161-164 | payments row has billplz_id, payment_method = fpx, payment_gateway = billplz |

### Limitations
- `payment_method` is always saved as `fpx`; the method the user actually picks on Billplz is not recorded.
- Tests are manual; there are no automated backend tests yet.
- CORS allows any website, and there is no rate limiting.