// SCRUM-48: booking history grouping, labels, KL times and screen states.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krp_play/models/booking_order.dart';
import 'package:krp_play/services/booking_service.dart';
import 'package:krp_play/widgets/booking_history.dart';

// 24 Nov 2026, 3:00 PM in Kuala Lumpur.
final now = DateTime.utc(2026, 11, 24, 7);

Map<String, dynamic> row({
  String status = 'confirmed',
  String date = '2026-11-25',
  List<String> starts = const ['21:00:00'],
  String? deadline,
  List<Map<String, dynamic>> payments = const [],
  bool demo = false,
}) => {
  'id': 'b-$status-$date',
  'booking_reference': 'KRP-$status-$date',
  'status': status,
  'total_amount': 6 * starts.length,
  'payment_deadline': deadline,
  'created_at': '2026-11-24T06:00:00Z',
  'is_demo': demo,
  'booking_items': [
    for (final s in starts)
      {
        'price': 6,
        'status': status,
        'time_slots': {
          'slot_date': date,
          'start_time': s,
          'end_time':
              '${(int.parse(s.split(':').first) + 1).toString().padLeft(2, '0')}:00:00',
          'facilities': {'name': 'Badminton Court 1'},
        },
      },
  ],
  'payments': payments,
};

BookingOrder order(Map<String, dynamic> r) => BookingOrder.fromRow(r);

class HistoryFake extends BookingService {
  HistoryFake(this.result);
  FutureOr<List<BookingOrder>> Function() result;
  int calls = 0;

  @override
  Future<List<BookingOrder>> getMyOrders() async {
    calls++;
    return result();
  }
}

void main() {
  group('grouping keeps each status type separate', () {
    test('paid session still to come is upcoming', () {
      final o = order(row());
      expect(o.groupAt(now), OrderGroup.upcoming);
      expect(o.statusLabelAt(now), 'Paid & confirmed');
    });

    test('paid session already played is past', () {
      final o = order(row(date: '2026-11-20'));
      expect(o.groupAt(now), OrderGroup.past);
      expect(o.statusLabelAt(now), 'Completed');
    });

    test('active hold is pending, ended hold is cancelled', () {
      final active = order(
        row(status: 'pending_payment', deadline: '2026-11-24T07:05:00Z'),
      );
      final ended = order(
        row(status: 'pending_payment', deadline: '2026-11-24T06:55:00Z'),
      );
      expect(active.groupAt(now), OrderGroup.pending);
      expect(active.statusLabelAt(now), 'Awaiting payment');
      expect(ended.groupAt(now), OrderGroup.cancelled);
      expect(ended.statusLabelAt(now), 'Expired - not paid');
    });

    test(
      'expired, closed and refunded are cancelled with their own labels',
      () {
        expect(
          order(row(status: 'expired')).statusLabelAt(now),
          'Expired - not paid',
        );
        expect(
          order(row(status: 'Closed (Maintenance)')).statusLabelAt(now),
          'Closed by KRP (Maintenance)',
        );
        expect(order(row(status: 'Refunded')).statusLabelAt(now), 'Refunded');
        for (final s in [
          'expired',
          'Closed (Maintenance)',
          'Refunded',
          'cancelled',
        ]) {
          expect(
            order(row(status: s)).groupAt(now),
            OrderGroup.cancelled,
            reason: s,
          );
        }
      },
    );

    test('demo booking is labelled as demo', () {
      expect(order(row(demo: true)).statusLabelAt(now), 'Confirmed (demo)');
    });
  });

  group('details match saved sessions and payment', () {
    test('every session of a combined order is kept, in time order', () {
      final o = order(row(starts: ['22:00:00', '21:00:00']));
      expect(o.sessions.map((s) => s.interval), [
        '9:00 PM - 10:00 PM',
        '10:00 PM - 11:00 PM',
      ]);
      expect(o.total, 12);
    });

    test('order with one session still upcoming is not past', () {
      final o = order(
        row(date: '2026-11-24', starts: ['13:00:00', '21:00:00']),
      );
      expect(o.groupAt(now), OrderGroup.upcoming);
    });

    test('payment time is shown in KL time', () {
      final o = order(
        row(
          payments: [
            {
              'status': 'paid',
              'payment_method': 'fpx',
              'payment_gateway': 'billplz',
              'transaction_reference': 'TX-1',
              'paid_at': '2026-11-24T07:40:00+00:00',
              'amount': 6,
            },
          ],
        ),
      );
      final p = o.settledPayment!;
      expect(p.reference, 'TX-1');
      expect(p.methodLabel, 'FPX online banking');
      expect(formatKlInstant(p.paidAt!), '24 Nov 2026, 3:40 PM');
    });
  });

  group('screen states', () {
    Future<void> pump(WidgetTester tester, HistoryFake fake) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BookingHistoryView(service: fake, clock: () => now),
              ),
            ),
          ),
        );

    testWidgets('shows loading, then the order with all sessions', (
      tester,
    ) async {
      final done = Completer<List<BookingOrder>>();
      final fake = HistoryFake(() => done.future);
      await pump(tester, fake);
      expect(find.text('Loading your bookings...'), findsOneWidget);

      done.complete([
        order(row(starts: ['21:00:00', '22:00:00'])),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Upcoming (1)'), findsOneWidget);
      expect(find.text('Paid & confirmed'), findsOneWidget);
      expect(find.text('2 sessions'), findsOneWidget);
      expect(find.textContaining('9:00 PM - 10:00 PM'), findsOneWidget);
      expect(find.textContaining('10:00 PM - 11:00 PM'), findsOneWidget);
    });

    testWidgets('shows an error with a working retry', (tester) async {
      var fail = true;
      final fake = HistoryFake(
        () => fail ? throw StateError('offline') : <BookingOrder>[],
      );
      await pump(tester, fake);
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(fake.calls, 2);
      expect(find.text('No upcoming bookings'), findsOneWidget);
    });

    testWidgets('tabs filter by group and show empty messages', (tester) async {
      final fake = HistoryFake(
        () => [
          order(
            row(status: 'pending_payment', deadline: '2026-11-24T07:05:00Z'),
          ),
          order(row(status: 'expired', date: '2026-11-26')),
        ],
      );
      await pump(tester, fake);
      await tester.pumpAndSettle();

      // Opens the first tab with records: Pending payment.
      expect(find.text('Awaiting payment'), findsOneWidget);
      expect(find.textContaining('Slots are held until'), findsOneWidget);

      await tester.tap(find.text('Cancelled (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Expired - not paid'), findsOneWidget);
      expect(find.text('Awaiting payment'), findsNothing);

      await tester.tap(find.text('Past (0)'));
      await tester.pumpAndSettle();
      expect(find.text('No past bookings'), findsOneWidget);
    });
  });
}
