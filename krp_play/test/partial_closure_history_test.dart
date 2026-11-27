import 'package:flutter_test/flutter_test.dart';
import 'package:krp_play/models/booking_order.dart';

Map<String, dynamic> row() => {
  'id': 'order',
  'booking_reference': 'TEST',
  'status': 'confirmed',
  'total_amount': 12,
  'booking_items': [
    for (final hour in [21, 22])
      {
        'price': 6,
        'status': hour == 22 ? 'cancelled_by_management' : 'confirmed',
        'time_slots': {
          'slot_date': '2026-11-27',
          'start_time': '$hour:00:00',
          'end_time': '${hour + 1}:00:00',
          'facilities': {'name': 'Badminton Court 2'},
        },
      },
  ],
  'payments': [
    {'status': 'paid', 'amount': 12, 'payment_method': 'fpx'},
  ],
};

void main() {
  test(
    'partial closure preserves original total and individual session status',
    () {
      final order = BookingOrder.fromRow(row());
      expect(order.total, 12);
      expect(order.sessions.length, 2);
      expect(order.sessions.first.isCancelled, isFalse);
      expect(order.sessions.last.isCancelled, isTrue);
      expect(order.sessions.last.price, 6);
    },
  );
  test('active unaffected hour remains upcoming', () {
    final order = BookingOrder.fromRow(row());
    expect(order.groupAt(DateTime.utc(2026, 11, 27, 12)), OrderGroup.upcoming);
    expect(
      order.statusLabelAt(DateTime.utc(2026, 11, 27, 12)),
      contains('Partially cancelled'),
    );
  });
  test(
    'future cancelled hour does not keep a completed playable hour upcoming',
    () {
      final order = BookingOrder.fromRow(row());
      expect(
        order.groupAt(DateTime.utc(2026, 11, 27, 14, 30)),
        OrderGroup.past,
      );
    },
  );
  test('whole cancelled order is in cancelled tab', () {
    final data = row()..['status'] = 'cancelled_by_management';
    final order = BookingOrder.fromRow(data);
    expect(order.groupAt(DateTime.utc(2026, 11, 27, 12)), OrderGroup.cancelled);
    expect(
      order.statusLabelAt(DateTime.utc(2026, 11, 27, 12)),
      'Cancelled by management',
    );
  });
  test('refunded session remains cancelled without hiding another confirmed session', () {
    final data = row();
    (data['booking_items'] as List).last['status'] = 'refunded';
    final order = BookingOrder.fromRow(data);
    expect(order.sessions.last.sessionStatusLabel, 'Refunded session');
    expect(order.sessions.first.sessionStatusLabel, 'Confirmed session');
  });
}
