import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krp_play/main.dart';
import 'package:krp_play/screens/facilities_screen.dart';
import 'package:krp_play/screens/profile_screen.dart';

void main() {
  testWidgets('KrpPlayApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KrpPlayApp());
    expect(find.textContaining('KRP PLAY'), findsWidgets);
  });

  testWidgets('student reports display all admin status examples', (
    WidgetTester tester,
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

    expect(find.text('Wrong table'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Under Review'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
  });

  testWidgets('student profile uses the light page background', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            email: 'student@example.com',
            initialTab: 0,
            navigationSection: true,
          ),
        ),
      ),
    );

    final background = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(ProfileScreen),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(background.color, const Color(0xFFF4F6F4));
    expect(find.text('Full Name'), findsOneWidget);
  });

  testWidgets('booking cart totals multiple items and shows order details', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: FacilitiesScreen(
          category: 'KRP Student',
          email: 'student@example.com',
          studentName: 'Student',
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Badminton').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final today = DateTime.now();
    final daysUntilMonday = (DateTime.monday - today.weekday + 7) % 7;
    final nextMonday = today.add(
      Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday),
    );
    await tester.ensureVisible(find.textContaining('Date:'));
    await tester.tap(find.textContaining('Date:'));
    await tester.pumpAndSettle();
    if (nextMonday.month != today.month) {
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('${nextMonday.day}').first);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Start:'));
    await tester.pumpAndSettle();
    for (final time in ['5:00 PM', '6:00 PM', '9:00 PM', '10:00 PM']) {
      expect(find.text(time), findsOneWidget);
    }
    expect(find.text('7:00 PM'), findsNothing);
    expect(find.text('5:30 PM'), findsNothing);
    await tester.tap(find.text('9:00 PM'));
    await tester.pumpAndSettle();

    final daysUntilSaturday = (DateTime.saturday - today.weekday + 7) % 7;
    final nextSaturday = today.add(
      Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday),
    );
    await tester.ensureVisible(find.textContaining('Date:'));
    await tester.tap(find.textContaining('Date:'));
    await tester.pumpAndSettle();
    if (nextSaturday.month != nextMonday.month) {
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('${nextSaturday.day}').first);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Start:'));
    await tester.pumpAndSettle();
    for (final time in [
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '3:00 PM',
      '4:00 PM',
      '5:00 PM',
      '6:00 PM',
      '9:00 PM',
      '10:00 PM',
    ]) {
      expect(find.text(time), findsOneWidget);
    }
    expect(find.text('1:00 PM'), findsNothing);
    expect(find.text('7:00 PM'), findsNothing);
    expect(find.text('8:00 PM'), findsNothing);
    await tester.tap(find.text('10:00 AM'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add to cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('1 item · RM6.00'), findsOneWidget);
    expect(
      tester.getRect(find.text('View my order')).bottom,
      lessThan(tester.view.physicalSize.height - 72),
    );

    await tester.tap(find.text('Dart').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add to cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('2 items · RM9.00'), findsOneWidget);
    await tester.tap(find.text('View my order'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('03 Your order'), findsOneWidget);
    expect(find.text('Total items'), findsOneWidget);
    expect(find.text('Total hours'), findsOneWidget);
    expect(find.text('2'), findsNWidgets(2));
    expect(find.text('KRP Student'), findsOneWidget);
    expect(find.text('RM9.00'), findsOneWidget);
    expect(find.text('Pay RM9.00'), findsOneWidget);
    expect(find.textContaining('Court 01'), findsOneWidget);
    expect(find.textContaining('Board'), findsOneWidget);
  });
}
