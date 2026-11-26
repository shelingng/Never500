import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krp_play/screens/admin/reservations.dart';
import 'package:krp_play/services/admin_reservations_source.dart';

Map<String, dynamic> reservation(int i, {bool multi = false}) => {
  'id': 'order-$i',
  'booking_reference': 'KRP-$i',
  'status': 'confirmed',
  'total_amount': multi ? 9 : 6,
  'is_demo': false,
  'profiles': {
    'full_name': 'Student $i',
    'matric_number': 'A24-$i',
    'phone_number': '0123456789',
    'student_category': 'krp',
  },
  'booking_items': [
    {
      'price': 6,
      'time_slots': {
        'slot_date': '2026-11-27',
        'start_time': '17:00:00',
        'end_time': '18:00:00',
        'facilities': {'name': 'Badminton Court 1'},
      },
    },
    if (multi)
      {
        'price': 3,
        'time_slots': {
          'slot_date': '2026-11-28',
          'start_time': '21:00:00',
          'end_time': '22:00:00',
          'facilities': {'name': 'Dart Board 1'},
        },
      },
  ],
  'payments': [
    {
      'status': 'paid',
      'payment_method': 'fpx',
      'payment_gateway': 'billplz',
      'transaction_reference': 'transaction-$i',
      'billplz_id': 'bill-$i',
      'paid_at': '2026-11-26T08:00:00Z',
      'amount': multi ? 9 : 6,
    },
  ],
};

class ReservationsFake implements AdminReservationsSource {
  ReservationsFake(this.read);
  Future<List<Map<String, dynamic>>> Function() read;
  @override
  Future<List<Map<String, dynamic>>> loadAll() => read();
}

Future<void> openReservations(
  WidgetTester tester,
  AdminReservationsSource source,
) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: AdminBookingsTab(source: source)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('server pagination reads beyond the default 1000-row cap', () async {
    final data = List.generate(1005, (i) => reservation(i));
    final requests = <int>[];
    final rows = await readReservationPages((from, to) async {
      requests.add(from);
      return data.skip(from).take(to - from + 1).toList();
    });
    expect(rows, hasLength(1005));
    expect(rows.last['id'], 'order-1004');
    expect(requests, [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]);
  });

  test(
    'a failed later page fails the complete load instead of hiding records',
    () async {
      await expectLater(
        readReservationPages((from, to) async {
          if (from > 0) throw StateError('offline');
          return List.generate(100, (i) => reservation(i));
        }),
        throwsStateError,
      );
    },
  );

  test(
    'pagination stops when a server repeatedly returns the same page',
    () async {
      await expectLater(
        readReservationPages(
          (from, to) async => List.generate(100, (i) => reservation(i)),
        ),
        throwsStateError,
      );
    },
  );

  testWidgets(
    'pagination and search find an order beyond the first screen page',
    (tester) async {
      final source = ReservationsFake(
        () async => List.generate(21, (i) => reservation(i, multi: i == 20)),
      );
      await openReservations(tester, source);
      expect(find.text('KRP-0'), findsOneWidget);
      expect(find.text('KRP-20'), findsNothing);
      await tapVisible(tester, find.text('Next page'));
      expect(find.text('Page 2 of 3 · 21 reservation(s)'), findsOneWidget);
      await tapVisible(tester, find.text('Next page'));
      expect(find.text('KRP-20'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'A24-0');
      await tester.pumpAndSettle();
      expect(find.text('KRP-0'), findsOneWidget);
      expect(find.text('Page 1 of 1 · 1 reservation(s)'), findsOneWidget);
    },
  );

  testWidgets(
    'facility filter matches the second session and keeps complete details',
    (tester) async {
      final source = ReservationsFake(
        () async => List.generate(21, (i) => reservation(i, multi: i == 20)),
      );
      await openReservations(tester, source);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('facility-All Facilities')),
      );
      await tapVisible(tester, find.text('Dart Board 1').last);
      expect(find.text('KRP-20'), findsOneWidget);
      expect(find.text('KRP-0'), findsNothing);
      await tapVisible(tester, find.text('Details').first);
      expect(find.text('Badminton Court 1'), findsOneWidget);
      expect(find.text('Dart Board 1'), findsWidgets);
      expect(find.text('transaction-20'), findsOneWidget);
      expect(find.text('bill-20'), findsOneWidget);
      expect(find.text('28 Nov 2026'), findsOneWidget);
    },
  );

  testWidgets(
    'loading is visible before the response and empty state follows',
    (tester) async {
      final response = Completer<List<Map<String, dynamic>>>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminBookingsTab(
              source: ReservationsFake(() => response.future),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      response.complete([]);
      await tester.pumpAndSettle();
      expect(
        find.text('No bookings match your search and filters.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'load error has a working retry and does not masquerade as empty data',
    (tester) async {
      var offline = true;
      final source = ReservationsFake(() async {
        if (offline) throw StateError('offline');
        return [reservation(0)];
      });
      await openReservations(tester, source);
      expect(
        find.text('Could not load reservations. Please retry.'),
        findsOneWidget,
      );
      expect(
        find.text('No bookings match your search and filters.'),
        findsNothing,
      );
      offline = false;
      await tapVisible(tester, find.text('Retry reservations'));
      expect(find.text('KRP-0'), findsOneWidget);
    },
  );

  testWidgets('access denied displays no reservation data', (tester) async {
    await openReservations(
      tester,
      ReservationsFake(() async {
        throw const AdminAccessDenied();
      }),
    );
    expect(
      find.text('Administrator access is required to view reservations.'),
      findsOneWidget,
    );
    expect(find.text('KRP-0'), findsNothing);
  });

  testWidgets('mobile layout keeps facility and status filters usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminBookingsTab(
            source: ReservationsFake(() async => [reservation(0)]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Facility'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('late refresh responses cannot replace newer data', (
    tester,
  ) async {
    final old = Completer<List<Map<String, dynamic>>>();
    var calls = 0;
    final source = ReservationsFake(() {
      calls++;
      return calls == 1 ? old.future : Future.value([reservation(1)]);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AdminBookingsTab(source: source)),
      ),
    );
    await tester.tap(find.byTooltip('Refresh database'));
    await tester.pumpAndSettle();
    expect(find.text('KRP-1'), findsOneWidget);
    old.complete([reservation(0)]);
    await tester.pumpAndSettle();
    expect(find.text('KRP-1'), findsOneWidget);
    expect(find.text('KRP-0'), findsNothing);
  });

  testWidgets(
    'missing profile, session and payment relationships remain readable',
    (tester) async {
      final legacy = reservation(0)
        ..['profiles'] = null
        ..['booking_items'] = []
        ..['payments'] = [];
      await openReservations(tester, ReservationsFake(() async => [legacy]));
      expect(find.text('KRP-0'), findsOneWidget);
      expect(find.text('No payment record'), findsOneWidget);
      expect(find.text('Session details unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
