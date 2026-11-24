# Cart and order review: evidence (SCRUM-82, part of SCRUM-16)

The cart and order review screen already existed. This page shows that they work,
where the code is, and who wrote each part.

All code is in [`krp_play/lib/screens/facilities_screen.dart`](../krp_play/lib/screens/facilities_screen.dart).

## What works and who wrote it

| What it does | Where | Written by |
|---|---|---|
| Add different facilities, dates and times to one order | `_addSelectedToCart` (line 1130) | Chan Siew Ching `658b985`, tanjiayie `f814e57` |
| Remove an item from the order | `_removeCartItem` (line 1184) | Chan Siew Ching `658b985`, tanjiayie `942d8c5` |
| Total price and hours update after every add or remove | `cartTotal` (line 345) | tanjiayie `f814e57`, shelingng `d002bea` |
| Order review page with each item's exact time, e.g. `9:00 PM - 11:00 PM` | `_buildStep3ReviewBooking` (line 871) | YUXIANG `b46e233`, Chan Siew Ching `658b985`, tanjiayie `f814e57` |
| Cart bar showing items and total | `_buildCartBar` (line 1055) | Chan Siew Ching `658b985` |
| Removes items that someone else booked first | `_removeConflictingCartItems` (line 1661) | tanjiayie `5d79c9c` (PR #28) |

## Small fixes in this PR

- The same time slot can no longer be added twice. Before, the total doubled and payment failed later.
- Item prices now show two decimals (`RM6.00`), the same as the total.

## How I tested it

1. Added Badminton Court 1, tomorrow, 9 PM for 2 hours.
2. Added Snooker Table 1, tomorrow, 5 PM for 1 hour.
3. Tried to add Badminton Court 1 at 10 PM again: it was blocked with a message.
4. Opened the order review: both items showed their exact times and the correct total.
5. Removed the Snooker item: the total and hours went down straight away.

Screenshots are in the pull request.

## Limitations

- The cart is lost if you leave the booking page or refresh.
- Adding to the cart does not hold the slot; it is only held after Pay Now.
- The final price is checked again by the server when you pay.
- There is no automated test for the cart yet.
