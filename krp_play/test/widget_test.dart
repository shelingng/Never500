import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:krp_play/main.dart';
import 'package:krp_play/models/booking.dart';
import 'package:krp_play/models/facility_catalog.dart';
import 'package:krp_play/models/student_account.dart';
import 'package:krp_play/services/booking_service.dart';
import 'package:krp_play/screens/home_screen.dart';

void main() {
  const account = StudentAccount(
    fullName: 'She Ling',
    email: 'sheling@example.com',
    contact: '0123456789',
    matric: 'KRP12345',
    category: 'KRP Student',
    password: 'password123',
  );

  testWidgets('app opens on the sign-in screen', (tester) async {
    await tester.pumpWidget(const KrpPlayApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('home navigation opens the court list and date selector', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(account: account, onLogout: _ignoreLogout),
      ),
    );
    expect(find.text('GOOD AFTERNOON, SHE LING'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Book'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Available courts'), findsOneWidget);
    expect(find.text('Badminton Court 01'), findsOneWidget);

    await tester.tap(find.text('Badminton Court 01'));
    await tester.pumpAndSettle();
    expect(find.text('Choose date & time'), findsOneWidget);
    expect(find.text('One-hour slots'), findsOneWidget);
    expect(find.text('Available'), findsWidgets);
    expect(find.text('Booking summary'), findsNothing);
    expect(
      tester
          .widget<InkWell>(find.byKey(const ValueKey('booking-date-0')))
          .onTap,
      isNull,
    );

    final tomorrow = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 1)),
    );
    for (final time in sessionsForDate(tomorrow)) {
      expect(find.text(time), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('booking-date-2')));
    await tester.pumpAndSettle();
    final followingDay = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 2)),
    );
    for (final time in sessionsForDate(followingDay)) {
      expect(find.text(time), findsOneWidget);
    }
  });

  testWidgets('successful prototype payment opens Profile > My bookings', (
    tester,
  ) async {
    _useTallTestViewport(tester);
    const email = 'payment-redirect@example.com';
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          account: StudentAccount(
            fullName: 'Payment Test',
            email: email,
            contact: '0123456789',
            matric: 'P123',
            category: 'KRP Student',
            password: 'password123',
          ),
          onLogout: _ignoreLogout,
        ),
      ),
    );

    await tester.tap(find.text('Book'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Badminton Court 01'));
    await tester.pumpAndSettle();
    final firstSession = sessionsForDate(
      DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1))),
    ).last;
    await tester.tap(find.text(firstSession));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();

    final touchNGo = find.text("Touch 'n Go");
    await tester.ensureVisible(touchNGo);
    await tester.tap(touchNGo);
    await tester.pumpAndSettle();
    final payButton = find.text('Pay RM 6.00');
    await tester.ensureVisible(payButton);
    await tester.tap(payButton);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('KRP PLAY / My Profile'), findsOneWidget);
    expect(find.text('Badminton Court 01'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TabBar),
        matching: find.textContaining('My bookings'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('profile tab is available from the bottom navigation', (
    tester,
  ) async {
    _useTallTestViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(account: account, onLogout: _ignoreLogout),
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profile'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('sheling@example.com'), findsWidgets);
    expect(find.textContaining('Personal details'), findsWidgets);
    expect(find.text('STUDENT ACCOUNT'), findsOneWidget);

    await _tapProfileSubtab(tester, 'Refund requests');
    await tester.pumpAndSettle();
    expect(find.textContaining('Refund eligibility:'), findsOneWidget);
    expect(find.text('PROCESSING'), findsOneWidget);

    await _tapProfileSubtab(tester, 'My reports');
    await tester.pumpAndSettle();
    expect(find.text('Contact admin'), findsOneWidget);
    expect(find.text('Create Report'), findsOneWidget);
  });

  testWidgets('navigation drawer routes to facilities and profile', (
    tester,
  ) async {
    _useTallTestViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(account: account, onLogout: _ignoreLogout),
      ),
    );

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('Need assistance?'), findsOneWidget);
    await tester.tap(find.text('Facilities'));
    await tester.pumpAndSettle();
    expect(find.text('Available courts'), findsOneWidget);

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Profile'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Personal details'), findsWidgets);
  });

  testWidgets('profile header fits a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(account: account, onLogout: _ignoreLogout),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profile'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('KRP PLAY / My Profile'), findsOneWidget);
    expect(find.text('SL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'edit profile opens personal details and validates confirmation',
    (tester) async {
      _useTallTestViewport(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(account: account, onLogout: _ignoreLogout),
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Profile'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();

      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      expect(
        find.text('Please confirm your information is accurate.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('report form creates a local submitted report', (tester) async {
    _useTallTestViewport(tester);
    final bookingDate = DateTime(2026, 11, 7);
    expect(
      BookingService().addBooking(
        Booking(
          id: 'BK-REPORT',
          userEmail: account.email,
          facilityName: 'Badminton Court 01',
          date: bookingDate,
          timeSlots: const ['10:00 AM'],
          pricePerSession: 6,
          totalPrice: 6,
        ),
      ),
      isTrue,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(account: account, onLogout: _ignoreLogout),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profile'),
      ),
    );
    await tester.pumpAndSettle();
    await _tapProfileSubtab(tester, 'My reports');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Report'));
    await tester.pumpAndSettle();

    expect(find.text('How can we help?'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Facility Problem').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Booking?>));
    await tester.pumpAndSettle();
    const relatedBooking =
        'BK-REPORT - Badminton Court 01 - 7 Nov 2026 10:00 AM - 11:00 AM';
    await tester.tap(find.text(relatedBooking).last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'The court lights are not working.',
    );
    await tester.tap(find.text('Submit Report'));
    await tester.pumpAndSettle();

    expect(find.text('The court lights are not working.'), findsOneWidget);
    expect(find.text('Facility Problem'), findsOneWidget);
    expect(find.text('UNDER REVIEW'), findsOneWidget);
    expect(find.text('BK-REPORT'), findsOneWidget);
    expect(find.text('Badminton Court 01'), findsOneWidget);
    expect(find.text('7 Nov 2026 • 10:00 AM - 11:00 AM'), findsOneWidget);
  });

  testWidgets('bookings group by court and date, then sort by time', (
    tester,
  ) async {
    _useTallTestViewport(tester);
    const email = 'grouping-test@example.com';
    final service = BookingService();
    final date = DateTime(2026, 11, 8);
    expect(
      service.addBooking(
        Booking(
          id: 'group-10',
          userEmail: email,
          facilityName: 'Badminton Court 01',
          date: date,
          timeSlots: const ['10:00 AM'],
          pricePerSession: 6,
          totalPrice: 6,
        ),
      ),
      isTrue,
    );
    expect(
      service.addBooking(
        Booking(
          id: 'group-11',
          userEmail: email,
          facilityName: 'Badminton Court 01',
          date: date,
          timeSlots: const ['11:00 AM'],
          pricePerSession: 6,
          totalPrice: 6,
        ),
      ),
      isTrue,
    );
    expect(
      service.addBooking(
        Booking(
          id: 'group-court-2',
          userEmail: email,
          facilityName: 'Badminton Court 02',
          date: date,
          timeSlots: const ['10:00 AM'],
          pricePerSession: 6,
          totalPrice: 6,
        ),
      ),
      isTrue,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          account: StudentAccount(
            fullName: 'Test Student',
            email: email,
            contact: '0123456789',
            matric: 'T123',
            category: 'KRP Student',
            password: 'password123',
          ),
          onLogout: _ignoreLogout,
        ),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profile'),
      ),
    );
    await tester.pumpAndSettle();
    await _tapProfileSubtab(tester, 'My bookings');
    await tester.pumpAndSettle();

    expect(find.text('Badminton Court 01'), findsOneWidget);
    expect(find.text('Badminton Court 02'), findsOneWidget);
    expect(find.text('8 Nov 2026 • 10:00 AM - 12:00 PM'), findsOneWidget);
    expect(find.text('RM 12.00'), findsOneWidget);
  });
}

Future<void> _tapProfileSubtab(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(TabBar),
    matching: find.textContaining(label),
  );
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
}

void _useTallTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _ignoreLogout() {}
