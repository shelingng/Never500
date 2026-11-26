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
  final occupied = <Booking>[];
  List<Booking> submitted = [];

  @override
  Future<List<Map<String, dynamic>>> getFacilities() async => [
    {'name': 'Badminton Court 1', 'krp_price': 6, 'non_krp_price': 8},
    {'name': 'Badminton Court 2', 'krp_price': 6, 'non_krp_price': 8},
    {'name': 'Dart Board', 'krp_price': 3, 'non_krp_price': 5},
  ];

  @override
  Future<List<Booking>> getBookingsForDate(DateTime date) async {
    if (availabilityFails) throw StateError('offline');
    return occupied.where((b) => DateUtils.isSameDay(b.date, date)).toList();
  }

  @override
  Future<Map<String, dynamic>> demoPayCart(
    List<Booking> cart, {
    required String requestId,
    required String method,
  }) async {
    keys.add(requestId);
    submitted = List<Booking>.from(cart);
    if (error is PostgrestException) {
      final item = cart.first;
      occupied.add(
        Booking(
          id: 'other-user-booking',
          userId: 'other-user',
          facilityName: item.facilityName,
          date: item.date,
          timeSlots: List<String>.from(item.timeSlots as List),
          pricePerSession: item.pricePerSession,
          totalPrice: item.totalPrice,
          status: 'confirmed',
        ),
      );
    }
    if (error != null) throw error!;
    return pending?.future ??
        Future.value({
          'id': 'test-order',
          'reference': 'KRP-test',
          'total_amount': 6,
          'status': 'confirmed',
          'is_demo': true,
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

Future<void> openPayment(
  WidgetTester tester,
  CheckoutFake fake, {
  bool addDart = false,
}) async {
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
  if (addDart) {
    await tapText(tester, 'Dart');
    await tapText(tester, 'Add to cart');
  }
  await tapText(tester, 'View order');
  await tapText(tester, addDart ? 'Pay RM9.00' : 'Pay RM6.00');
  await tapText(tester, 'E-Wallet');
  expect(
    fake.keys,
    isEmpty,
    reason: 'Cart and method selection do not acquire a hold',
  );
}

void checkoutTestWidgets(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pump(const Duration(seconds: 51));
      await tester.pump(const Duration(seconds: 7));
      await tester.pump();
    }
  });
}
