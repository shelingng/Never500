import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:krp_play/screens/booking_records_screen.dart';
import 'package:krp_play/screens/facilities_screen.dart';

import 'support/checkout_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const preferences = MethodChannel('plugins.flutter.io/shared_preferences');
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(preferences, (call) async {
          if (call.method == 'getAll') return <String, Object>{};
          return true;
        });
    // No real account, persisted session, or production project is used.
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-publishable-key',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
    );
  });

  tearDownAll(() async {
    await Supabase.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(preferences, null);
  });

  checkoutTestWidgets('Pay confirms a clearly labelled demo booking', (
    tester,
  ) async {
    final fake = CheckoutFake();
    await openPayment(tester, fake);
    await tapText(tester, 'Pay Now');
    expect(fake.keys, hasLength(1));
    expect(find.text('Booking confirmed!'), findsOneWidget);
    expect(
      find.text('Demo payment only. No money was charged.'),
      findsOneWidget,
    );
    expect(find.text('Demo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  checkoutTestWidgets('View my bookings opens Booking Records, not Home', (
    tester,
  ) async {
    final fake = CheckoutFake();
    await openPayment(tester, fake);
    await tapText(tester, 'Pay Now');

    final button = find.byKey(const ValueKey('view-my-bookings'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byType(BookingRecordsScreen), findsOneWidget);
    expect(find.byType(FacilitiesScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  checkoutTestWidgets(
    'double click submits once while the reservation is in flight',
    (tester) async {
      final fake = CheckoutFake()..pending = Completer<Map<String, dynamic>>();
      await openPayment(tester, fake);
      final pay = find.text('Pay Now');
      await tester.ensureVisible(pay);
      await tester.tap(pay);
      await tester.tap(pay);
      await tester.pump();
      expect(fake.keys, hasLength(1));
      expect(find.text('Processing...'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      fake.pending!.complete({
        'reference': 'ignored-after-dispose',
        'total_amount': 6,
        'payment_deadline': DateTime.now().toIso8601String(),
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  checkoutTestWidgets('network retry reuses its request ID', (tester) async {
    final fake = CheckoutFake()..error = StateError('connection lost');
    await openPayment(tester, fake);
    await tapText(tester, 'Pay Now');
    fake.error = null;
    await tapText(tester, 'Pay Now');
    expect(fake.keys, hasLength(2));
    expect(fake.keys[0], fake.keys[1]);
    expect(
      find.text('Booking confirmed!'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  checkoutTestWidgets(
    'server conflict returns to selection without payment success',
    (tester) async {
      final fake = CheckoutFake()
        ..error = const PostgrestException(
          message: 'SLOT_UNAVAILABLE',
          code: '23505',
        );
      await openPayment(tester, fake);
      await tapText(tester, 'Pay Now');
      expect(find.text('02 Choose your court'), findsOneWidget);
      expect(find.text('Selected slot is no longer available'), findsOneWidget);
      expect(
        find.textContaining('have been removed from your cart'),
        findsOneWidget,
      );
      await tapText(tester, 'Choose another slot');
      expect(find.text('Booked'), findsOneWidget);
      expect(find.text('In Cart'), findsNothing);
      expect(find.text('View order'), findsNothing);
      expect(
        find.text('Booking confirmed!'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  checkoutTestWidgets(
    'conflict removes only the booked item and recalculates total',
    (tester) async {
      final fake = CheckoutFake()
        ..error = const PostgrestException(
          message: 'SLOT_UNAVAILABLE',
          code: '23505',
        );
      await openPayment(tester, fake, addDart: true);
      await tapText(tester, 'Pay Now');
      expect(fake.submitted, hasLength(2));
      expect(find.text('Selected slot is no longer available'), findsOneWidget);
      expect(find.textContaining('Badminton Court 01'), findsWidgets);
      expect(
        find.text('Booking confirmed!'),
        findsNothing,
      );
      await tapText(tester, 'Choose another slot');
      await tapText(tester, 'View order');
      expect(find.text('Badminton'), findsNothing);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Pay RM3.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  checkoutTestWidgets(
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
