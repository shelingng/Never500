import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class FacilitiesScreen extends StatefulWidget {
  final String category;
  final String email;
  final String studentName;

  const FacilitiesScreen({
    super.key,
    required this.category,
    required this.email,
    this.studentName = 'Yu Xiang',
  });

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  // Navigation step in prototype:
  // 1: Choose your sport
  // 2: Choose your court (select date, time, hours + show court layout)
  // 3: Review your booking (confirm page showing details)
  // 4: Payment & booking status
  int currentStep = 1;

  final Color primaryGreen = const Color(0xFF103B2B);
  final Color subtleBorder = const Color(0xFFE2E8E4);

  String selectedSport = 'Badminton';
  String selectedCourt = 'Court 01';

  DateTime selectedDate = DateTime(2026, 11, 14);
  String selectedStartTime = '9:00 PM';
  int selectedDurationHours = 1;

  bool paymentCompleted = false;
  String generatedBookingRef = 'DEMO-KRP-001';
  String selectedPaymentMethod = '';
  String? selectedBank;

  static const List<String> malaysianBanks = [
    'Maybank2u',
    'CIMB Clicks',
    'Public Bank',
    'RHB Now',
    'Hong Leong Bank',
    'Bank Islam',
    'AmBank',
    'Bank Rakyat',
    'Affin Bank',
    'Alliance Bank',
    'BSN',
    'Bank Muamalat',
    'Agrobank',
    'OCBC Bank',
    'UOB Malaysia',
    'HSBC Bank Malaysia',
    'Standard Chartered',
    'Kuwait Finance House',
    'Al Rajhi Bank',
    'MBSB Bank',
  ];

  final List<String> availableStartTimes = [
    '5:00 PM',
    '5:30 PM',
    '6:00 PM',
    '6:30 PM',
    '7:00 PM',
    '7:30 PM',
    '8:00 PM',
    '8:30 PM',
    '9:00 PM',
    '9:30 PM',
    '10:00 PM',
  ];

  static const List<String> monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String get formattedDate =>
      '${selectedDate.day} ${monthNames[selectedDate.month - 1]} ${selectedDate.year}';

  String get calculatedEndTime {
    try {
      final startMin = BookingService.minutesFor(selectedStartTime);
      final endMin = startMin + (selectedDurationHours * 60);
      final hour24 = (endMin ~/ 60) % 24;
      final minute = endMin % 60;
      final period = hour24 >= 12 ? 'PM' : 'AM';
      final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
      final minStr = minute < 10 ? '0$minute' : '$minute';
      return '$hour12:$minStr $period';
    } catch (_) {
      return '10:00 PM';
    }
  }

  String get timeRangeString => '$selectedStartTime–$calculatedEndTime';

  int get ratePerHour {
    if (widget.category == 'KRP Student') {
      switch (selectedSport) {
        case 'Badminton':
          return 6;
        case 'Ping Pong':
          return 4;
        case 'Snooker':
          return 10;
        case 'Dart':
          return 3;
        default:
          return 6;
      }
    } else {
      switch (selectedSport) {
        case 'Badminton':
          return 8;
        case 'Ping Pong':
          return 6;
        case 'Snooker':
          return 12;
        case 'Dart':
          return 5;
        default:
          return 8;
      }
    }
  }

  int get totalAmount => ratePerHour * selectedDurationHours;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () {
            if (currentStep > 1 && !paymentCompleted) {
              setState(() => currentStep -= 1);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'KRP PLAY',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Student view',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _buildCurrentStepCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepCard() {
    switch (currentStep) {
      case 1:
        return _buildStep1ChooseSport();
      case 2:
        return _buildStep2ChooseCourt();
      case 3:
        return _buildStep3ReviewBooking();
      case 4:
        return _buildStep4PaymentAndStatus();
      default:
        return _buildStep1ChooseSport();
    }
  }

  // ==========================================
  // PANEL 01: 01 Choose your sport
  // ==========================================
  Widget _buildStep1ChooseSport() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          _buildPanelHeader('01 Choose your sport'),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${widget.studentName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2420),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.category} · Prices shown for your category',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // 2x2 Grid of Sport Cards matching mockup
                Row(
                  children: [
                    Expanded(
                      child: _sportCard(
                        title: 'Badminton',
                        subtitle: 'From RM6 / court / hour',
                        sport: 'Badminton',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sportCard(
                        title: 'Ping Pong',
                        subtitle: 'From RM4 / table / hour',
                        sport: 'Ping Pong',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _sportCard(
                        title: 'Snooker',
                        subtitle: 'From RM10 / table / hour',
                        sport: 'Snooker',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sportCard(
                        title: 'Dart',
                        subtitle: 'From RM3 / board / hour',
                        sport: 'Dart',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                Text(
                  'Availability is subject to KRP Management arrangements.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sportCard({
    required String title,
    required String subtitle,
    required String sport,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedSport = sport;
          currentStep = 2; // Move to next page
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5EDE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF103B2B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.arrow_forward_rounded,
                  size: 16, color: primaryGreen),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PANEL 02: 02 Choose your court
  // (Steps 2 & 3 in user request)
  // ==========================================
  Widget _buildStep2ChooseCourt() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          _buildPanelHeader('02 Choose your court'),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb & Change Sport
                Row(
                  children: [
                    Text(
                      '$selectedSport / ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B2420),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => currentStep = 1);
                      },
                      child: Text(
                        'Change sport',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Controls Row: Date, Start, Duration
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Date Selector
                      _pillButton(
                        label: 'Date: $formattedDate',
                        onTap: _showDatePickerDialog,
                      ),
                      const SizedBox(width: 8),

                      // Start Time Selector
                      _pillButton(
                        label: 'Start: $selectedStartTime',
                        onTap: _showStartTimeSelectorDialog,
                      ),
                      const SizedBox(width: 8),

                      // Duration Selector
                      _pillButton(
                        label: 'Duration: $selectedDurationHours hour${selectedDurationHours > 1 ? 's' : ''}',
                        onTap: () {
                          setState(() {
                            selectedDurationHours = selectedDurationHours == 1 ? 2 : 1;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  '$timeRangeString · RM$ratePerHour.00 per court',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF103B2B),
                  ),
                ),

                const SizedBox(height: 20),

                // 3 Courts Display: Green (Available), Red (Booked), Grey (Locked)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Court 01 (Available)
                    Expanded(
                      child: _courtCard(
                        courtName: 'Court 01',
                        statusLabel: 'Available',
                        statusColor: const Color(0xFF2E7D32),
                        surfaceTint: const Color(0xFFF3FAF5),
                        isSelectable: true,
                        isSelected: selectedCourt == 'Court 01',
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Court 02 (Booked)
                    Expanded(
                      child: _courtCard(
                        courtName: 'Court 02',
                        statusLabel: 'Booked',
                        statusColor: const Color(0xFFD32F2F),
                        surfaceTint: const Color(0xFFFDF2F2),
                        isSelectable: false,
                        isSelected: false,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Court 03* (Management lock)
                    Expanded(
                      child: _courtCard(
                        courtName: 'Court 03*',
                        statusLabel: 'Management lock',
                        statusColor: const Color(0xFF757575),
                        surfaceTint: const Color(0xFFF5F5F5),
                        isSelectable: false,
                        isSelected: false,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Selected feedback line
                Text(
                  'Selected: $selectedCourt · Available',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B2420),
                  ),
                ),

                const SizedBox(height: 20),

                // Primary Button: Review booking · RM6.00
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() => currentStep = 3);
                    },
                    child: Text(
                      'Review booking · RM$totalAmount.00',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  '*Court count is illustrative; load actual facilities from database.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCE4DF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E34),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _courtCard({
    required String courtName,
    required String statusLabel,
    required Color statusColor,
    required Color surfaceTint,
    required bool isSelectable,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: isSelectable
          ? () {
              setState(() => selectedCourt = courtName);
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$courtName is $statusLabel. Please select Court 01.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryGreen : (isSelected ? primaryGreen : const Color(0xFFE2E8E4)),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Visual Court Graphic Container
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: surfaceTint,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              ),
              child: CustomPaint(
                painter: _PrototypeCourtPainter(lineColor: statusColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              courtName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1B2420),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PANEL 03: 03 Review your booking
  // (Step 4 in user request)
  // ==========================================
  Widget _buildStep3ReviewBooking() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          _buildPanelHeader('03 Review your booking'),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewDetailRow('Sport / Facility', '$selectedSport / $selectedCourt'),
                _divider(),
                _reviewDetailRow('Date', formattedDate),
                _divider(),
                _reviewDetailRow('Start → End', '$selectedStartTime → $calculatedEndTime'),
                _divider(),
                _reviewDetailRow('Duration', '$selectedDurationHours hour${selectedDurationHours > 1 ? 's' : ''}'),
                _divider(),
                _reviewDetailRow('Student category', widget.category),
                _divider(),
                _reviewDetailRow('Rate', 'RM$ratePerHour.00 / court / hour'),

                const SizedBox(height: 20),

                // Total Amount Highlight Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF103B2B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'RM$totalAmount.00',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'Availability will be checked again before payment.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

                // Primary Action Button: Proceed to payment
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() => currentStep = 4);
                    },
                    child: const Text(
                      'Proceed to payment',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Secondary Action: Edit selection
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() => currentStep = 2);
                    },
                    child: Text(
                      'Edit selection',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 1, color: const Color(0xFFEFF3F0));

  // ==========================================
  // PANEL 04: 04 Payment & booking status
  // (Step 5 in user request)
  // ==========================================
  Widget _buildStep4PaymentAndStatus() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          _buildPanelHeader('04 Payment & booking status'),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!paymentCompleted) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: subtleBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount due',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Booking total',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF304137),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'RM$totalAmount.00',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select payment method',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentMethodOption(
                    title: 'FPX Online Banking',
                    subtitle: 'All Malaysian banks',
                    icon: Icons.account_balance_outlined,
                    selected: selectedPaymentMethod == 'FPX',
                    onTap: () {
                      setState(() => selectedPaymentMethod = 'FPX');
                    },
                    expandedContent: DropdownButtonFormField<String>(
                      key: ValueKey<String?>(selectedBank),
                      initialValue: selectedBank,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Choose your bank',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: malaysianBanks
                          .map(
                            (bank) => DropdownMenuItem(
                              value: bank,
                              child: Text(bank),
                            ),
                          )
                          .toList(),
                      onChanged: (bank) {
                        setState(() => selectedBank = bank);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentMethodOption(
                    title: 'E-Wallet',
                    subtitle: "Touch 'n Go eWallet",
                    icon: Icons.account_balance_wallet_outlined,
                    selected: selectedPaymentMethod == 'E-Wallet',
                    onTap: () {
                      setState(() => selectedPaymentMethod = 'E-Wallet');
                    },
                    expandedContent: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: subtleBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wallet_outlined, color: Color(0xFF315A3B)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Touch 'n Go eWallet",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(Icons.check_circle, color: Color(0xFF315A3B)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _canSubmitPayment ? _processDemoPayment : null,
                      child: const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Secure payment powered by Billplz.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],

                // Booking Confirmed Success Card
                if (paymentCompleted) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC7E5C3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check, size: 20, color: Color(0xFF2E7D32)),
                            SizedBox(width: 8),
                            Text(
                              'Booking confirmed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$generatedBookingRef · $selectedCourt',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$formattedDate · $timeRangeString',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Booking: Confirmed Payment: Paid',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop(); // Back to facility info screen
                          },
                          child: Text(
                            'View booking details →',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSubmitPayment =>
      selectedPaymentMethod == 'E-Wallet' ||
      (selectedPaymentMethod == 'FPX' && selectedBank != null);

  Widget _buildPaymentMethodOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required Widget expandedContent,
  }) {
    final borderColor = selected ? primaryGreen : const Color(0xFFE2E8E4);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF5F9F3) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF4E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF304137),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? primaryGreen : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (selected)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
            child: expandedContent,
          ),
      ],
    );
  }

  void _processDemoPayment() {
    setState(() {
      paymentCompleted = true;
    });

    // Keep the mock booking in the in-memory booking service.
    BookingService.instance.addBooking(
      Booking(
        id: generatedBookingRef,
        userEmail: widget.email,
        facilityName: 'Badminton Court 01',
        date: selectedDate,
        timeSlots: [selectedStartTime],
        pricePerSession: ratePerHour,
        participants: 1,
        totalPrice: totalAmount,
        status: 'Confirmed',
      ),
    );
  }

  Widget _buildPanelHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  void _showDatePickerDialog() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1B2420),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _showStartTimeSelectorDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select start time (:00 or :30)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableStartTimes.map((time) {
                  final isSelected = selectedStartTime == time;
                  return ChoiceChip(
                    label: Text(time),
                    selected: isSelected,
                    selectedColor: primaryGreen,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() => selectedStartTime = time);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// Custom Painter for Regulation Badminton Court in Prototype Cards
class _PrototypeCourtPainter extends CustomPainter {
  final Color lineColor;

  _PrototypeCourtPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRect(rect, paint);

    // Singles sidelines
    canvas.drawLine(
        Offset(rect.left + 8, rect.top), Offset(rect.left + 8, rect.bottom), paint);
    canvas.drawLine(
        Offset(rect.right - 8, rect.top), Offset(rect.right - 8, rect.bottom), paint);

    // Middle net line
    final midY = rect.top + rect.height / 2;
    canvas.drawLine(Offset(rect.left - 2, midY), Offset(rect.right + 2, midY),
        paint..strokeWidth = 1.8);
    paint.strokeWidth = 1.2;

    // Service lines
    canvas.drawLine(
        Offset(rect.left, midY - 14), Offset(rect.right, midY - 14), paint);
    canvas.drawLine(
        Offset(rect.left, midY + 14), Offset(rect.right, midY + 14), paint);

    // Back doubles lines
    canvas.drawLine(
        Offset(rect.left, rect.top + 6), Offset(rect.right, rect.top + 6), paint);
    canvas.drawLine(
        Offset(rect.left, rect.bottom - 6), Offset(rect.right, rect.bottom - 6), paint);

    // Center dividing lines
    final midX = rect.left + rect.width / 2;
    canvas.drawLine(Offset(midX, rect.top), Offset(midX, midY - 14), paint);
    canvas.drawLine(Offset(midX, midY + 14), Offset(midX, rect.bottom), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
