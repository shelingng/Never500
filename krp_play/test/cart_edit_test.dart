import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:krp_play/models/booking.dart';
import 'package:krp_play/screens/facilities_screen.dart';

import 'support/checkout_fake.dart';

Booking item(String id, {String time = '9:00 PM'}) => Booking(
  id: id,
  userId: 'test@example.com',
  facilityName: 'Badminton Court 01',
  date: DateUtils.dateOnly(DateTime.now().add(const Duration(days: 2))),
  timeSlots: [time],
  pricePerSession: 6,
  totalPrice: 6,
);

Future<void> openCart(
  WidgetTester tester,
  CheckoutFake fake,
  List<Booking> items,
) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: FacilitiesScreen(
        category: 'krp',
        email: 'test@example.com',
        bookingService: fake,
        initialCart: items,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tapText(tester, 'View order');
}

Future<void> editFirst(WidgetTester tester) async {
  final edit = find.byTooltip('Edit booking').first;
  await tester.ensureVisible(edit);
  await tester.tap(edit);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const prefs = MethodChannel('plugins.flutter.io/shared_preferences');
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          prefs,
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
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
        .setMockMethodCallHandler(prefs, null);
  });

  checkoutTestWidgets('editing replaces one item and recalculates the total', (
    tester,
  ) async {
    final fake = CheckoutFake();
    await openCart(tester, fake, [item('first')]);
    await editFirst(tester);
    expect(find.text('Start: 9:00 PM'), findsOneWidget);
    expect(find.text('Selected: Court 01'), findsOneWidget);
    await tapText(tester, 'Duration: 1 hour');
    await tapText(tester, 'Save changes');
    expect(find.byTooltip('Edit booking'), findsOneWidget);
    expect(find.text('Pay RM12.00'), findsOneWidget);
    expect(fake.keys, isEmpty, reason: 'Editing does not reserve or charge');
  });

  checkoutTestWidgets('cancel keeps the original item and total', (
    tester,
  ) async {
    await openCart(tester, CheckoutFake(), [item('first')]);
    await editFirst(tester);
    await tapText(tester, 'Duration: 1 hour');
    await tapText(tester, 'Cancel edit');
    expect(find.text('Pay RM6.00'), findsOneWidget);
    expect(find.byTooltip('Edit booking'), findsOneWidget);
  });

  checkoutTestWidgets('another cart item still blocks an overlapping edit', (
    tester,
  ) async {
    final fake = CheckoutFake();
    final secondCourt = Booking(
      id: 'other-user',
      userId: 'other',
      facilityName: 'Badminton Court 02',
      date: item('x').date,
      timeSlots: ['9:00 PM', '10:00 PM'],
      pricePerSession: 6,
      totalPrice: 12,
      status: 'confirmed',
    );
    fake.occupied.add(secondCourt);
    await openCart(tester, fake, [
      item('first'),
      item('second', time: '10:00 PM'),
    ]);
    await editFirst(tester);
    await tapText(tester, 'Duration: 1 hour');
    final save = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Save changes'),
    );
    expect(save.onPressed, isNull);
    await tapText(tester, 'Cancel edit');
    expect(find.text('Pay RM12.00'), findsOneWidget);
    expect(find.byTooltip('Edit booking'), findsNWidgets(2));
  });

  checkoutTestWidgets(
    'availability failure blocks saving without removing the item',
    (tester) async {
      final fake = CheckoutFake();
      await openCart(tester, fake, [item('first')]);
      fake.availabilityFails = true;
      await editFirst(tester);
      final save = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save changes'),
      );
      expect(save.onPressed, isNull);
      await tapText(tester, 'Cancel edit');
      expect(find.text('Pay RM6.00'), findsOneWidget);
    },
  );
}
