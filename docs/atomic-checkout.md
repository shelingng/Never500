# SCRUM-15: reserve the cart when Pay is pressed

This is a review branch. The hosted Supabase project has NOT been changed.

## Behaviour

Adding to cart does not reserve a session. Pay calls `reserve_cart` once for the
whole cart. The first committed server reservation wins. The loser gets a conflict
before any payment. A successful response is a 10-minute unpaid hold, not a paid
booking. An identical request UUID and payload return the same order after a
network retry. A changed payload cannot reuse that UUID.

The database resolves UI names such as `Badminton Court 01` to the existing
`Badminton Court 1`, verifies approved schedules and future one-hour sessions,
calculates the price from the stored profile category and facility prices, and
checks it against the total the customer reviewed. Every item references the
actual shared `time_slots.id`. All inserts roll back on any conflict.

Expired holds are excluded immediately from availability. The next successful
checkout changes expired rows to `expired` and reclaims them. No cron is required.
Confirmed items remain blocked. Availability responses contain no customer data.

## Deployment order / existing data

1. Review the branch and take a database backup. Test on a staging copy first.
2. Review the following legacy records with the team. The November 18 audit found
   **seven active items without real slot references**. Do not delete them or
   silently choose a winner where two customers share the same session.

   ```sql
   select b.id,b.booking_reference,b.status,b.admin_note,
          i.id as item_id,i.time_slot_id,i.status as item_status
   from public.bookings b
   left join public.booking_items i on i.booking_id=b.id
   left join public.time_slots s on s.id=i.time_slot_id
   where lower(b.status) in ('confirmed','pending_payment')
     and (i.id is null or s.id is null);
   ```

   Reconcile each active booking into the real facility/date/hour sessions using
   its original note and payment evidence. Resolve conflicting historical claims
   with KRP/the team. Keep an audit trail; do not mark an actual payment unpaid.
   Inactive orphan records are retained by a NOT VALID foreign key; new records
   must reference real slots. Reconciliation is a separate reviewed data action.
3. Run `database/atomic_checkout.sql` as owner after reconciliation. It is an
   atomic, one-time versioned deployment script, not yet a Supabase CLI migration.
   Do not rerun it after success. Any preflight/unique-index error aborts it all.
   If adopting it into the team's migration system, use `supabase migration new`
   with the team's installed CLI and copy the reviewed SQL into that generated file.
4. Keep `checkout_private` OUT of the Data API exposed schemas. Public RPCs are
   invoker wrappers. Private definer implementations check `auth.uid()`, use a
   fixed empty search_path, and have no anonymous/PUBLIC execute grants.
5. Deploy the Flutter branch only after the SQL. Older clients' direct booking
   and payment writes will now be denied: all testers need the coordinated update.
6. Re-run Supabase security advisors, then repeat the two-browser test below.

Table write grants for students are revoked on bookings/items/payments, prices,
and schedules. Existing admin policies remain but administrator writes now need
trusted backend operations. Profile updates allow only name/contact/matric;
registration remains self-only with a student role. This intentionally prevents
browser clients from setting their role/category or declaring money received.
Other unrelated report/storage policies are outside this change.

## Payment limitation / teammate handoff

The existing sandbox draft accepts client amounts and unsigned callbacks. Its
routes now return 503 before executing that old code. Both Flutter payment paths
cannot write `successful` payments. No service key is added to Flutter.

Until SCRUM-17 integrates a verified gateway, the customer sees an unpaid hold,
its deadline, and that payments are unavailable. No bill is launched and no money
is taken. This branch does NOT claim full payment integration.

The gateway adapter must accept an existing reservation ID, authenticate the
owner, use the stored amount, verify signatures and the provider bill/amount,
and confirm payment plus all items in one server transaction. It must serialize
with the same `krp_checkout_v1` transaction lock, reject expired/cancelled holds,
and never reinstate a slot reassigned to another order. Late paid callbacks need
an evidence-backed refund/recovery record. Browser redirects are not payment proof.

## Verification

`database/tests/checkout.test.mjs` uses two independent PostgreSQL connections.
Run ONLY in an empty disposable database; the test refuses a nonempty database.
Install the isolated test dependencies and run:

```sh
npm --prefix database/tests ci
DATABASE_URL=postgresql://localhost/checkout_test \
CHECKOUT_TEST_DISPOSABLE=yes node database/tests/checkout.test.mjs
```

Covers first-winner contention, rollback of a multi-item losing cart, idempotent
retry, altered payload, expiry and reclaim, confirmed-slot protection, ownership,
anonymous access, client payment/role/price tampering, schedule alignment, past
dates, duplicate slots, management blocks and legacy-data deployment failure.

Local database results: all groups passed on PostgreSQL 18.6. Hosted project is
PostgreSQL 17; repeat against staging before deployment. Dart formatting/parser
checks and `node --check krp_play/backend/app.js` passed. Full Flutter analysis
and the five added widget tests were NOT run: automatic approval review blocked
Flutter tooling when it attempted a cloud metadata request. Run locally:

```sh
cd krp_play
flutter pub get
flutter analyze
flutter test test/atomic_checkout_test.dart
```

The pre-existing widget_test.dart includes old demo expectations and is not
evidence of acceptance of the new database flow.

Two-browser acceptance after staging deployment:

1. Log in with two distinct accounts; both add the same facility/date/hour.
2. Press Pay in browser A. Expect one pending hold and no payment-success message.
3. Press Pay in B. Expect reserved/conflict; verify no B order/payment was created.
4. Repeat simultaneously. Only one holds the session.
5. Retry A's request: no additional order. Wait for expiry: B can reserve it.
6. Try a cart with a free slot and a taken slot: neither is partially reserved.

The local facility drawings are carried forward from Jiayie's supplied file.
When bringing this branch onto a Mac with uncommitted UI edits, commit those
edits on the current feature branch first and merge this review branch there.
Do not overwrite the local file with an older copy.
