import 'package:flutter/material.dart';

import '../widgets/booking_history.dart';

// SCRUM-48: same saved history as Profile > My bookings.
class BookingRecordsScreen extends StatelessWidget {
  final String email;
  const BookingRecordsScreen({super.key, required this.email});

  static const Color primaryGreen = Color(0xFF103B2B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Booking Records',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: BookingHistoryView(),
      ),
    );
  }
}
