import 'package:flutter/material.dart';
import '../models/booking.dart';
import 'payment_screen.dart';

class BookingConfirmScreen extends StatelessWidget {
  final Booking booking;
  final String studentName;
  final String category;

  const BookingConfirmScreen({
    super.key,
    required this.booking,
    required this.studentName,
    required this.category,
  });

  final Color primaryGreen = const Color(0xFF103B2B);
  final Color accentLime = const Color(0xFFD2F865);
  final Color subtleBorder = const Color(0xFFE9EFEA);

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${booking.date.day}/${booking.date.month}/${booking.date.year}';
    final timeStr = booking.timeSlots.length == 1
        ? booking.timeSlots.first
        : '${booking.timeSlots.first} – ${_calculateEndTime(booking.timeSlots.last)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Confirm Booking',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section header matching wireframe "Booking detail"
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Booking detail',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF103B2B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Review your reservation details before proceeding to payment.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Main Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: subtleBorder),
            ),
            elevation: 1,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F6C8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.sports_tennis,
                          color: primaryGreen,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.facilityName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'KRP Sports Complex, UTM',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 28),

                  _row('Booked For', studentName),
                  _row('Category', category),
                  _row('Date', dateStr),
                  _row('Time Slot', timeStr),
                  _row('Duration', '${booking.timeSlots.length} hour(s)'),
                  _row('Price Rate', 'RM ${booking.pricePerSession}.00 / hour'),

                  const Divider(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'RM ${booking.totalPrice}.00',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Collegiate Guidelines
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD0E6D8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Important Guidelines',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Non-marking sports shoes are strictly required on all courts.\n'
                  '• Present your UTM Matric Card upon check-in at the counter.\n'
                  '• Students cannot cancel bookings or request refunds. Eligible refunds for management-related facility unavailability are handled by KRP Management.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Button matching wireframe: [ Proceed to payment ]
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(booking: booking),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Proceed to payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20, color: accentLime),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateEndTime(String startTime) {
    try {
      final parts = startTime.split(' ');
      final clock = parts[0].split(':');
      var hour = int.parse(clock[0]);
      final minute = clock[1];
      var period = parts[1];

      hour += 1;
      if (hour == 12) {
        period = period == 'AM' ? 'PM' : 'AM';
      } else if (hour > 12) {
        hour -= 12;
      }
      return '$hour:$minute $period';
    } catch (_) {
      return startTime;
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
