import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;
  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = 'Online Banking';
  bool isProcessing = false;
  final _bookingService = BookingService();

  final Color primaryColor = const Color(0xFF103B2B);

  confirmPayment() async {
    setState(() {
      isProcessing = true;
    });

    try {
      // 🌟 Live Supabase Update
      await _bookingService.confirmPayment(
        widget.booking.id, 
        widget.booking.totalPrice, 
        selectedPaymentMethod
      );

      if (!mounted) return;
      setState(() => isProcessing = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 65),
                const SizedBox(height: 16),
                const Text('Payment Successful!', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('Booking confirmed and saved to Supabase.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: primaryColor),
                    onPressed: () {
                      Navigator.of(context)..pop()..pop()..pop(); 
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final date = '${booking.date.day}/${booking.date.month}/${booking.date.year}';

    return Scaffold(
      appBar: AppBar(title: const Text('Payment'), backgroundColor: primaryColor, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Complete your booking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking Details', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const Divider(height: 25),
                  _detailRow('Facility', booking.facilityName),
                  _detailRow('Date', date),
                  _detailRow('Status', booking.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Card(
            color: const Color(0xFFE5EFE9),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Summary', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _detailRow('Price per session', 'RM ${booking.pricePerSession}'),
                  const Divider(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('RM ${booking.totalPrice}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          const Text('Select Payment Method', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _paymentOption('Online Banking', 'Pay through online banking', Icons.account_balance),
          _paymentOption('E-Wallet', 'Pay using an e-wallet', Icons.account_balance_wallet),
          const SizedBox(height: 25),

          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
              onPressed: isProcessing ? null : () => confirmPayment(),
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Pay RM ${booking.totalPrice}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _paymentOption(String title, String subtitle, IconData icon) {
    final selected = selectedPaymentMethod == title;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? primaryColor : Colors.grey),
        selected: selected,
        onTap: () => setState(() => selectedPaymentMethod = title),
      ),
    );
  }
}