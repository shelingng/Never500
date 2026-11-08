import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:krp_play/models/booking.dart';
import 'package:krp_play/screens/payment_screen.dart';

void main() {
  final booking = Booking(
    id: 'booking-1',
    userEmail: 'student@example.com',
    facilityName: 'Badminton Court 01',
    date: DateTime(2026, 11, 8),
    timeSlots: ['5:00 PM'],
    pricePerSession: 6,
    totalPrice: 6,
  );

  testWidgets('shows only FPX and Touch n Go without booking status', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: PaymentScreen(booking: booking)));
    await tester.scrollUntilVisible(find.text('FPX'), 300);

    expect(find.text('FPX'), findsOneWidget);
    expect(find.text("Touch 'n Go"), findsOneWidget);
    expect(find.text('Debit / Credit Card'), findsNothing);
    expect(find.text('E-Wallet'), findsNothing);
    expect(find.text('Status'), findsNothing);
    final bankDropdown = find.byType(DropdownButtonFormField<String>);
    await tester.scrollUntilVisible(bankDropdown, 300);
    await tester.ensureVisible(bankDropdown);
    await tester.pumpAndSettle();
    expect(find.text('Select your bank'), findsOneWidget);

    await tester.tap(bankDropdown);
    await tester.pumpAndSettle();
    expect(find.text('Maybank (Maybank2u / Maybank2e)'), findsOneWidget);
    expect(
      find.text('CIMB Bank (CIMB Clicks / CIMB BizChannel)'),
      findsOneWidget,
    );
  });

  testWidgets('hides the bank dropdown when Touch n Go is selected', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: PaymentScreen(booking: booking)));
    await tester.scrollUntilVisible(find.text("Touch 'n Go"), 300);

    await tester.tap(find.text("Touch 'n Go"));
    await tester.pump();

    expect(find.text('Select your bank'), findsNothing);
  });
}
