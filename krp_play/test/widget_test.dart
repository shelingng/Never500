import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:krp_play/main.dart';
import 'package:krp_play/screens/login_screen.dart';
import 'package:krp_play/screens/facilities_screen.dart';
import 'package:krp_play/screens/profile_screen.dart';
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

  checkoutTestWidgets('signed-out app opens authentication', (tester) async {
    await tester.pumpWidget(const KrpPlayApp());
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  checkoutTestWidgets('reports show an empty state without fictional records', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            email: 'student@example.com',
            initialTab: 3,
            navigationSection: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No reports submitted'), findsOneWidget);
    expect(find.text('Wrong table'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  checkoutTestWidgets(
    'profile shows supplied student details on light background',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileScreen(
              email: 'student@example.com',
              fullName: 'Test Student',
              initialTab: 0,
              navigationSection: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final background = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(ProfileScreen),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(background.color, const Color(0xFFF4F6F4));
      expect(find.text('Test Student'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  checkoutTestWidgets(
    'cart preserves sport labels and totals different facilities',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fake = CheckoutFake();
      await tester.pumpWidget(
        MaterialApp(
          home: FacilitiesScreen(
            category: 'krp',
            email: 'student@example.com',
            bookingService: fake,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Badminton');
      await tapText(tester, 'Add to cart');
      await tapText(tester, 'Dart');
      await tapText(tester, 'Add to cart');
      await tapText(tester, 'View order');
      expect(find.text('03 Your order'), findsOneWidget);
      expect(find.text('Badminton'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Pay RM9.00'), findsOneWidget);
      expect(fake.keys, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
