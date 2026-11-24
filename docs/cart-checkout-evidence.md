# Cart checkout, all or nothing: evidence (SCRUM-83, part of SCRUM-16)

When a student presses **Pay Now**, the whole cart is reserved in one step, or
nothing is. This was built in SCRUM-15. This page shows that it works and where
the code is. No code was changed for this ticket.

## What works and who wrote it

| What it does | Where | Written by |
|---|---|---|
| Sends the whole cart in one call to `reserve_cart` | `krp_play/lib/services/booking_service.dart` line 146 | tanjiayie `942d8c5` |
| All or nothing: if one slot is taken, no item is reserved | `reserve_cart` in `database/atomic_checkout.sql` | tanjiayie `942d8c5` |
| Shows which slot is taken and removes it from the cart | `facilities_screen.dart` lines 1661 and 1770 | tanjiayie `942d8c5`, `5d79c9c` (PR #28) |
| Same booking reference on retry (no second booking) | `facilities_screen.dart` line 1726 (one request ID per cart) | tanjiayie `942d8c5` |
| Shows the reference after reserving ("Slots reserved - complete your payment") | `facilities_screen.dart` lines 1736 and 1463 | tanjiayie `942d8c5`; Chan Siew Ching `ff69b02` (SCRUM-78) |
| Clear messages for expired hold and changed price | `facilities_screen.dart` lines 1774 and 1781 | tanjiayie `942d8c5` |

The database test `database/tests/checkout.test.mjs` also checks this, including
*"multi-item conflict rolls back free item and parent order"* and
*"stable retry returns same order"*.

## How I tested it

Two student accounts, A and B, in two browser windows.

1. **B** added Badminton Court 1 (tomorrow, 9 PM) and a free Dart Board 1 slot to the cart, but did not pay yet.
2. **A** added the same Badminton slot and pressed Pay Now. A `KRP-...` reference appeared.
3. **B** then pressed Pay Now. B saw "Selected slot is no longer available" and the taken slot was removed
   from the cart. In Supabase, **B had no new booking**, not even for the free Dart slot.

(Once A has the hold, B cannot add that slot at all, so B has to add it to the cart first to test this.)
4. **Retry:** with the payment backend stopped, A added another slot and pressed Pay Now. The slot was reserved but
   the payment page could not open. After starting the backend, A pressed Pay Now again: a reference appeared,
   and Supabase showed **only one** booking for that cart.

Screenshots are in the pull request.

## Limitations

- The reference is long (`KRP-` plus a UUID), so it is hard to read out.
- After a conflict the student must press Pay Now again for the remaining items.
- The 10-minute hold starts at Pay Now, not when items are added to the cart.
- An unpaid hold shows as **"Booked"** to other students instead of **"Reserved"**, so they may think the slot is
  gone for good. It is released after 10 minutes if not paid.
