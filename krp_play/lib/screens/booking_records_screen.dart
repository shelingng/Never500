import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class BookingRecordsScreen extends StatefulWidget {
  final String email;
  const BookingRecordsScreen({super.key, required this.email});

  @override
  State<BookingRecordsScreen> createState() => _BookingRecordsScreenState();
}

class _BookingRecordsScreenState extends State<BookingRecordsScreen> {
  final Color primaryGreen = const Color(0xFF103B2B);
  final _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('Booking Records', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: FutureBuilder(
        future: _bookingService.getUserBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawBookings = snapshot.data;
          final bookings = (rawBookings is List ? rawBookings : <dynamic>[])
              .where((b) => !(b is Booking && b.status.trim().toLowerCase().startsWith('closed')))
              .toList();

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No active bookings found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Reserve a court or facility to get started.', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final Booking booking = bookings[index] as Booking;
              final dateStr = '${booking.date.day}/${booking.date.month}/${booking.date.year}';

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE9EFEA))),
                color: Colors.white,
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFEBF5E9), borderRadius: BorderRadius.circular(20)),
                            child: Text(booking.status, style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          Text('RM ${booking.totalPrice}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(booking.reference.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(dateStr, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${booking.facilityName} · ${(booking.timeSlots as List).join(', ')} (1 hour each)'),
                      if (booking.paymentRef != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Payment ref: ${booking.paymentRef}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        Text(
                          'Paid at: ${DateTime.parse(booking.paidAt.toString()).toLocal()}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}