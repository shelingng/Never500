import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:krp_play/models/checkout_recovery.dart';
import 'package:krp_play/screens/facilities_screen.dart';
import 'support/checkout_fake.dart';

CheckoutRecovery savedOrder({
  String status = 'pending_payment',
  bool expired = false,
}) {
  return CheckoutRecovery.fromRow({
    'id': 'existing-order',
    'user_id': 'test-owner',
    'checkout_request_id': 'existing-request',
    'booking_reference': 'KRP-existing',
    'status': status,
    'is_demo': false,
    'total_amount': 9,
    'payment_deadline': expired
        ? '2020-01-01T00:00:00Z'
        : '2099-01-01T00:00:00Z',
    'booking_items': [
      {
        'price': 6,
        'time_slots': {
          'slot_date': '2098-12-31',
          'start_time': '17:00:00',
          'end_time': '18:00:00',
          'facilities': {'name': 'Badminton Court 1'},
        },
      },
      {
        'price': 3,
        'time_slots': {
          'slot_date': '2098-12-31',
          'start_time': '18:00:00',
          'end_time': '19:00:00',
          'facilities': {'name': 'Dart Board 1'},
        },
      },
    ],
  });
}

class RecoveryFake extends CheckoutFake {
  CheckoutRecovery? saved = savedOrder();
  final resumedIds = <String>[];
  bool failRecovery = false;
  int recoveryCalls = 0;

  @override
  bool get usesRealPayment => true;
  @override
  String? get checkoutUserId => 'test-owner';
  @override
  Future<CheckoutRecovery?> getCheckoutForRecovery({String? bookingId}) async {
    recoveryCalls++;
    if (failRecovery) throw StateError('offline');
    return saved;
  }

  @override
  Future<String> createBillplzPayment(String bookingId) async {
    resumedIds.add(bookingId);
    return 'https://www.billplz-sandbox.com/bills/test';
  }
}

Future<void> showCheckout(WidgetTester tester, RecoveryFake fake) async {
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
}

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

  test('recovery retains server reference, request ID and every session', () {
    final saved = savedOrder();
    expect(saved.requestId, 'existing-request');
    expect(saved.order.reference, 'KRP-existing');
    expect(saved.cart.map((b) => b.facilityName), [
      'Badminton Court 1',
      'Dart Board 1',
    ]);
    expect(saved.cart.map((b) => b.timeSlots.first), ['5:00 PM', '6:00 PM']);
    expect(saved.cart.fold<num>(0, (sum, b) => sum + (b.totalPrice as num)), 9);
    expect(saved.canResumeAt(DateTime.utc(2026)), isTrue);
    expect(savedOrder(expired: true).canResumeAt(DateTime.utc(2026)), isFalse);
    expect(
      savedOrder(status: 'confirmed').canResumeAt(DateTime.utc(2026)),
      isFalse,
    );
  });

  checkoutTestWidgets('resume uses the same booking without reserving again', (
    tester,
  ) async {
    final fake = RecoveryFake();
    await showCheckout(tester, fake);
    expect(find.text('Resume payment'), findsOneWidget);
    expect(fake.keys, isEmpty);
    await tapText(tester, 'Resume payment');
    expect(fake.resumedIds, ['existing-order']);
    expect(fake.keys, isEmpty);
    expect(find.text('Open Billplz payment page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  checkoutTestWidgets('reopening restores the server order again', (
    tester,
  ) async {
    final fake = RecoveryFake();
    await showCheckout(tester, fake);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 51));
    await tester.pump(const Duration(seconds: 7));
    await showCheckout(tester, fake);
    expect(find.text('Resume payment'), findsOneWidget);
    expect(fake.recoveryCalls, 2);
    expect(fake.keys, isEmpty);
  });

  checkoutTestWidgets(
    'expired recovery restores cart without creating a bill',
    (tester) async {
      final fake = RecoveryFake()..saved = savedOrder(expired: true);
      await showCheckout(tester, fake);
      expect(find.text('02 Choose your court'), findsOneWidget);
      expect(find.text('View order'), findsOneWidget);
      expect(fake.resumedIds, isEmpty);
      expect(fake.keys, isEmpty);
    },
  );

  checkoutTestWidgets(
    'failed recovery blocks new checkout until retry succeeds',
    (tester) async {
      final fake = RecoveryFake()..failRecovery = true;
      await showCheckout(tester, fake);
      expect(find.text('Retry checkout recovery'), findsOneWidget);
      expect(find.text('01 Choose your sport'), findsNothing);
      fake.failRecovery = false;
      await tapText(tester, 'Retry checkout recovery');
      expect(find.text('Resume payment'), findsOneWidget);
      expect(fake.keys, isEmpty);
    },
  );

  checkoutTestWidgets(
    'already confirmed order is not charged again on resume',
    (tester) async {
      final fake = RecoveryFake();
      await showCheckout(tester, fake);
      fake.saved = savedOrder(status: 'confirmed');
      await tapText(tester, 'Resume payment');
      expect(find.text('Payment received. See you on court!'), findsOneWidget);
      expect(fake.resumedIds, isEmpty);
      expect(fake.keys, isEmpty);
    },
  );
}
