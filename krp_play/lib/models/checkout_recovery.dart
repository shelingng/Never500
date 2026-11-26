import 'booking.dart';
import 'booking_order.dart';

/// Server-owned checkout state. Never use a saved client value as payment proof.
class CheckoutRecovery {
  final BookingOrder order;
  final String? requestId;
  final String userId;

  const CheckoutRecovery({
    required this.order,
    required this.requestId,
    required this.userId,
  });

  factory CheckoutRecovery.fromRow(Map<String, dynamic> row) =>
      CheckoutRecovery(
        order: BookingOrder.fromRow(row),
        requestId: row['checkout_request_id']?.toString(),
        userId: row['user_id']?.toString() ?? '',
      );

  bool canResumeAt(DateTime now) => !order.isDemo && order.holdActiveAt(now);

  List<Booking> get cart => [
    for (var i = 0; i < order.sessions.length; i++)
      Booking(
        id: 'recovered-${order.id}-$i',
        userId: userId,
        facilityName: order.sessions[i].facilityName,
        date: order.sessions[i].date,
        timeSlots: [formatSessionTime(order.sessions[i].startTime)],
        pricePerSession: order.sessions[i].price,
        totalPrice: order.sessions[i].price,
        status: 'pending_payment',
      ),
  ];
}
