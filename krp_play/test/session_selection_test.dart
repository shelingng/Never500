import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:krp_play/models/session_selection.dart';
import 'package:krp_play/screens/facilities_screen.dart';
import 'support/checkout_fake.dart';

List<Map<String, dynamic>> hours(int day) => [
  {
    'day_of_week': day,
    'start_time': '17:00:00',
    'end_time': '19:00:00',
    'slot_minutes': 60,
    'is_active': true,
  },
  {
    'day_of_week': day,
    'start_time': '21:00:00',
    'end_time': '23:00:00',
    'slot_minutes': 60,
    'is_active': true,
  },
];

class HoursFake extends CheckoutFake {
  bool offline = false;
  bool empty = false;
  @override
  Future<List<Map<String, dynamic>>> getOperatingSchedules() async {
    if (offline) throw StateError('hours offline');
    if (empty) return <Map<String, dynamic>>[];
    return super.getOperatingSchedules();
  }
}

Future<void> openSelection(WidgetTester tester, CheckoutFake fake) async {
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

  test(
    'whole-hour starts follow the active schedule for the selected weekday',
    () {
      final starts = SessionSelection.startsForDate(
        hours(1),
        DateTime(2026, 11, 30),
      );
      expect(starts, [1020, 1080, 1260, 1320]);
      expect(
        SessionSelection.startsForDate(hours(1), DateTime(2026, 12, 1)),
        isEmpty,
      );
    },
  );

  test(
    'two hours at opening are valid; two hours at the last start cross closing',
    () {
      final starts = [1020, 1080, 1260, 1320];
      expect(
        SessionSelection.error(allowedStarts: starts, start: 1020, hours: 2),
        isNull,
      );
      expect(
        SessionSelection.error(allowedStarts: starts, start: 1260, hours: 2),
        isNull,
      );
      for (final start in [1080, 1320]) {
        expect(
          SessionSelection.error(allowedStarts: starts, start: start, hours: 1),
          isNull,
        );
        expect(
          SessionSelection.error(allowedStarts: starts, start: start, hours: 2),
          contains('crosses a closed period'),
        );
      }
    },
  );

  test('weekend daytime hours retain the lunch and evening breaks', () {
    final rows = [
      {
        'day_of_week': 6,
        'start_time': '10:00:00',
        'end_time': '13:00:00',
        'slot_minutes': 60,
        'is_active': true,
      },
      {
        'day_of_week': 6,
        'start_time': '15:00:00',
        'end_time': '19:00:00',
        'slot_minutes': 60,
        'is_active': true,
      },
    ];
    final starts = SessionSelection.startsForDate(rows, DateTime(2026, 11, 28));
    expect(starts, [600, 660, 720, 900, 960, 1020, 1080]);
    expect(
      SessionSelection.error(allowedStarts: starts, start: 660, hours: 2),
      isNull,
    );
    expect(
      SessionSelection.error(allowedStarts: starts, start: 720, hours: 2),
      isNotNull,
    );
    expect(
      SessionSelection.error(allowedStarts: starts, start: 1080, hours: 2),
      isNotNull,
    );
  });

  test(
    'inactive, malformed and unsupported slot grids do not become bookable',
    () {
      final rows = [
        ...hours(1).map((r) => {...r, 'is_active': false}),
        {...hours(1).first, 'start_time': 'invalid'},
        {...hours(1).first, 'slot_minutes': 30},
      ];
      expect(
        SessionSelection.startsForDate(rows, DateTime(2026, 11, 30)),
        isEmpty,
      );
      expect(
        SessionSelection.error(allowedStarts: [], start: 1020, hours: 1),
        contains('No bookable sessions'),
      );
      expect(
        SessionSelection.error(allowedStarts: [1020], start: 1000, hours: 1),
        contains('within operating hours'),
      );
      expect(
        SessionSelection.error(allowedStarts: [1020], start: 1020, hours: 3),
        contains('1 or 2 hours'),
      );
    },
  );

  test(
    'overlapping schedules deduplicate starts and retain the interval grid',
    () {
      final rows = [
        ...hours(1),
        {...hours(1).first, 'start_time': '17:30:00', 'end_time': '19:30:00'},
        ...hours(1),
      ];
      expect(SessionSelection.startsForDate(rows, DateTime(2026, 11, 30)), [
        1020,
        1050,
        1080,
        1110,
        1260,
        1320,
      ]);
    },
  );

  test('midnight-wrapping hour is excluded to match server validation', () {
    final rows = [
      {...hours(1).first, 'start_time': '22:00:00', 'end_time': '24:00:00'},
    ];
    expect(SessionSelection.startsForDate(rows, DateTime(2026, 11, 30)), [
      1320,
    ]);
  });

  checkoutTestWidgets(
    'closed-period selection is explained and cannot be added',
    (tester) async {
      final fake = CheckoutFake();
      await openSelection(tester, fake);
      await tapText(tester, 'Badminton');
      await tapText(tester, 'Start: 9:00 PM');
      await tapText(tester, '6:00 PM');
      await tapText(tester, 'Duration: 1 hour');
      expect(find.textContaining('crosses a closed period'), findsOneWidget);
      final add = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add to cart'),
      );
      expect(add.onPressed, isNull);
      expect(fake.keys, isEmpty);
      await tapText(tester, 'Duration: 2 hours');
      await tapText(tester, 'Add to cart');
      await tapText(tester, 'View order');
      expect(find.text('6:00 PM - 7:00 PM'), findsOneWidget);
      expect(find.text('Pay RM6.00'), findsOneWidget);
    },
  );

  checkoutTestWidgets('valid two-hour review and submitted slots agree', (
    tester,
  ) async {
    final fake = CheckoutFake();
    await openSelection(tester, fake);
    await tapText(tester, 'Badminton');
    await tapText(tester, 'Start: 9:00 PM');
    await tapText(tester, '5:00 PM');
    await tapText(tester, 'Duration: 1 hour');
    await tapText(tester, 'Add to cart');
    await tapText(tester, 'View order');
    expect(find.text('5:00 PM - 7:00 PM'), findsOneWidget);
    await tapText(tester, 'Pay RM12.00');
    await tapText(tester, 'E-Wallet');
    await tapText(tester, 'Pay Now');
    expect(fake.submitted.single.timeSlots, ['5:00 PM', '6:00 PM']);
    expect(fake.submitted.single.totalPrice, 12);
    expect(fake.keys, hasLength(1));
  });

  checkoutTestWidgets(
    'hours loading failure has a retry without advertising guessed times',
    (tester) async {
      final fake = HoursFake()..offline = true;
      await openSelection(tester, fake);
      expect(
        find.text('Operating hours could not be loaded. Retry'),
        findsOneWidget,
      );
      fake.offline = false;
      await tapText(tester, 'Operating hours could not be loaded. Retry');
      await tapText(tester, 'Badminton');
      expect(find.text('02 Choose your court'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  checkoutTestWidgets(
    'a date without operating hours explains why adding is disabled',
    (tester) async {
      final fake = HoursFake()..empty = true;
      await openSelection(tester, fake);
      await tapText(tester, 'Badminton');
      expect(
        find.text('No bookable sessions are scheduled for this date.'),
        findsOneWidget,
      );
      final add = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add to cart'),
      );
      expect(add.onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
