import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:krp_play/models/booking.dart';
import 'package:krp_play/screens/facilities_screen.dart';
import 'package:krp_play/services/booking_service.dart';

class CheckoutFake extends BookingService {
  final keys = <String>[];
  Completer<Map<String, dynamic>>? pending;
  Object? error;
  bool availabilityFails = false;

  @override
  Future<List<Map<String, dynamic>>> getFacilities() async => [
    {'name': 'Badminton Court 1', 'krp_price': 6, 'non_krp_price': 8},
    {'name': 'Badminton Court 2', 'krp_price': 6, 'non_krp_price': 8},
  ];

  @override
  Future<List<Booking>> getBookingsForDate(DateTime date) async {
    if (availabilityFails) throw StateError('offline');
    return [];
  }

  @override
  Future<Map<String, dynamic>> reserveCart(
    List<Booking> cart, {
    required String requestId,
  }) async {
    keys.add(requestId);
    if (error != null) throw error!;
    return pending?.future ??
        Future.value({
          'id': 'test-order',
          'reference': 'KRP-test',
          'total_amount': 6,
          'status': 'pending_payment',
          'payment_deadline': DateTime.now()
              .add(const Duration(minutes: 10))
              .toIso8601String(),
        });
  }
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openPayment(WidgetTester tester, CheckoutFake fake) async {
  tester.view.physicalSize = const Size(1200, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: FacilitiesScreen(
        category: 'krp',
        email: 'test@example.com',
        bookingService: fake,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tapText(tester, 'Badminton');
  await tapText(tester, 'Add to cart');
  await tapText(tester, 'View order');
  await tapText(tester, 'Pay RM6.00');
  await tapText(tester, 'E-Wallet');
  expect(
    fake.keys,
    isEmpty,
    reason: 'Cart and method selection do not acquire a hold',
  );
}

void main() {
  testWidgets(
    'Pay creates a pending reservation and never claims payment success',
    (tester) async {
      final fake = CheckoutFake();
      await openPayment(tester, fake);
      await tapText(tester, 'Pay Now');
      expect(fake.keys, hasLength(1));
      expect(find.text('Reserved - awaiting payment'), findsOneWidget);
      expect(find.textContaining('No payment has been taken'), findsOneWidget);
      expect(find.text('Booking confirmed'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('double click submits once while the reservation is in flight', (
    tester,
  ) async {
    final fake = CheckoutFake()..pending = Completer<Map<String, dynamic>>();
    await openPayment(tester, fake);
    final pay = find.text('Pay Now');
    await tester.ensureVisible(pay);
    await tester.tap(pay);
    await tester.tap(pay);
    await tester.pump();
    expect(fake.keys, hasLength(1));
    expect(find.text('Reserving...'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    fake.pending!.complete({
      'reference': 'ignored-after-dispose',
      'total_amount': 6,
      'payment_deadline': DateTime.now().toIso8601String(),
    });
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('network retry reuses its request ID', (tester) async {
    final fake = CheckoutFake()..error = StateError('connection lost');
    await openPayment(tester, fake);
    await tapText(tester, 'Pay Now');
    fake.error = null;
    await tapText(tester, 'Pay Now');
    expect(fake.keys, hasLength(2));
    expect(fake.keys[0], fake.keys[1]);
    expect(find.text('Reserved - awaiting payment'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('server conflict returns to selection without payment success', (
    tester,
  ) async {
    final fake = CheckoutFake()
      ..error = const PostgrestException(
        message: 'SLOT_UNAVAILABLE',
        code: '23505',
      );
    await openPayment(tester, fake);
    await tapText(tester, 'Pay Now');
    expect(find.text('02 Choose your court'), findsOneWidget);
    expect(find.textContaining('reserved or booked'), findsOneWidget);
    expect(find.text('Reserved - awaiting payment'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'availability errors do not make all facilities appear available',
    (tester) async {
      final fake = CheckoutFake()..availabilityFails = true;
      await tester.pumpWidget(
        MaterialApp(
          home: FacilitiesScreen(
            category: 'krp',
            email: 'test@example.com',
            bookingService: fake,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Badminton');
      final add = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add to cart'),
      );
      expect(add.onPressed, isNull);
      expect(
        find.textContaining('Availability could not be loaded'),
        findsOneWidget,
      );
    },
  );
}
