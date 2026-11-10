import 'package:flutter/material.dart';

import '../models/booking.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;

  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'Online Banking';
  bool isProcessing = false;

  final Color primaryColor = const Color(0xFF173F32);

  void confirmPayment() {
    setState(() {
      isProcessing = true;
    });

    // Prototype only: no real payment transaction occurs.
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 65),

                const SizedBox(height: 16),

                const Text(
                  'Payment Successful!',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Your payment process has been completed in this prototype.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                    onPressed: () {
                      Navigator.of(context)
                        ..pop()
                        ..pop();
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    final date =
        '${booking.date.day}/${booking.date.month}/${booking.date.year}';

    final isGym = booking.facilityName == 'KRP Gym';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Complete your booking',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          const Text(
            'Review your booking details before proceeding.',
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 24),

          // BOOKING DETAILS
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Details',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),

                  const Divider(height: 25),

                  _detailRow('Booking ID', booking.id),

                  _detailRow('Facility', booking.facilityName),

                  _detailRow('Date', date),

                  _detailRow('Time', booking.timeSlots.join(', ')),

                  _detailRow('Duration', '${booking.timeSlots.length} hour(s)'),

                  if (isGym)
                    _detailRow('Participants', '${booking.participants}'),

                  _detailRow('Status', booking.status),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // PAYMENT SUMMARY
          Card(
            color: const Color(0xFFE5EFE9),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Summary',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  _detailRow(
                    'Price per session',
                    'RM ${booking.pricePerSession}.00',
                  ),

                  _detailRow(
                    'Number of sessions',
                    '${booking.timeSlots.length}',
                  ),

                  if (isGym)
                    _detailRow('Participants', '${booking.participants}'),

                  const Divider(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        'RM ${booking.totalPrice}.00',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          // PAYMENT METHODS
          const Text(
            'Select Payment Method',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _paymentOption(
            title: 'Online Banking',
            subtitle: 'Pay through online banking',
            icon: Icons.account_balance,
          ),

          _paymentOption(
            title: 'Debit / Credit Card',
            subtitle: 'Pay using your bank card',
            icon: Icons.credit_card,
          ),

          _paymentOption(
            title: 'E-Wallet',
            subtitle: 'Pay using an e-wallet',
            icon: Icons.account_balance_wallet,
          ),

          const SizedBox(height: 25),

          // CONFIRM PAYMENT
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryColor),

              onPressed: isProcessing ? null : confirmPayment,

              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Pay RM ${booking.totalPrice}.00',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Payment methods are for demonstration only. No actual payment will be charged.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = selectedPaymentMethod == title;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selected ? primaryColor : Colors.grey,
        ),
        selected: selected,
        onTap: () {
          setState(() {
            selectedPaymentMethod = title;
          });
        },
      ),
    );
  }
}
