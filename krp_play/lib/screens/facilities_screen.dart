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
  // 3: Review the cart and order total
  // 4: Payment & booking status
  int currentStep = 1;

  final Color primaryGreen = const Color(0xFF103B2B);
  final Color subtleBorder = const Color(0xFFE2E8E4);

  String selectedSport = 'Badminton';
  String selectedCourt = 'Court 01';

  DateTime selectedDate = DateTime.now();
  String selectedStartTime = '9:00 PM';
  int selectedDurationHours = 1;
  final List<Booking> cartItems = [];

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

  static const List<String> _weekdayStartTimes = [
    '5:00 PM',
    '6:00 PM',
    '9:00 PM',
    '10:00 PM',
  ];

  static const List<String> _weekendStartTimes = [
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '9:00 PM',
    '10:00 PM',
  ];

  List<String> get availableStartTimes {
    final isWeekend =
        selectedDate.weekday == DateTime.saturday ||
        selectedDate.weekday == DateTime.sunday;
    return isWeekend ? _weekendStartTimes : _weekdayStartTimes;
  }

  static const List<String> monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get formattedDate =>
      '${selectedDate.day} ${monthNames[selectedDate.month - 1]} ${selectedDate.year}';

  String get calculatedEndTime => _formatTime(
    BookingService.minutesFor(selectedStartTime) + selectedDurationHours * 60,
  );

  String get timeRangeString => '$selectedStartTime–$calculatedEndTime';

  int _rateForSport(String sport) {
    if (widget.category == 'KRP Student') {
      switch (sport) {
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
      switch (sport) {
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

  int get ratePerHour => _rateForSport(selectedSport);
  int get totalAmount => ratePerHour * selectedDurationHours;
  int get cartTotal =>
      cartItems.fold(0, (total, item) => total + item.totalPrice);
  int get cartTotalHours =>
      cartItems.fold(0, (total, item) => total + item.timeSlots.length);

  String get _selectedFacilityName {
    final courtNumber = selectedCourt.replaceAll(RegExp(r'[^0-9]'), '');
    return switch (selectedSport) {
      'Badminton' => 'Badminton Court $courtNumber',
      'Ping Pong' => 'Ping Pong Table $courtNumber',
      'Snooker' => 'Snooker Table',
      'Dart' => 'Dart Board',
      _ => '$selectedSport $selectedCourt',
    };
  }

  String _formatTime(int minutes) {
    final minuteOfDay = minutes % (24 * 60);
    final hour24 = minuteOfDay ~/ 60;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = (minuteOfDay % 60).toString().padLeft(2, '0');
    return '$hour12:$minute ${hour24 < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
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
      bottomNavigationBar: currentStep == 3
          ? _buildCheckoutBar()
          : cartItems.isNotEmpty && currentStep < 3
          ? _buildCartBar()
          : null,
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

                _sportCard(title: 'Badminton', sport: 'Badminton'),
                const SizedBox(height: 10),
                _sportCard(title: 'Ping Pong', sport: 'Ping Pong'),
                const SizedBox(height: 10),
                _sportCard(title: 'Snooker', sport: 'Snooker'),
                const SizedBox(height: 10),
                _sportCard(title: 'Dart', sport: 'Dart'),

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

  Widget _sportCard({required String title, required String sport}) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedSport = sport;
          selectedCourt = 'Court 01';
          currentStep = 2; // Move to next page
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5EDE7)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEBF5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_sportIcon(sport), color: primaryGreen),
            ),
            const SizedBox(width: 14),
            Expanded(
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
                    'RM${_rateForSport(sport)}.00 / hour',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 20, color: primaryGreen),
          ],
        ),
      ),
    );
  }

  IconData _sportIcon(String sport) {
    switch (sport) {
      case 'Badminton':
        return Icons.sports_tennis;
      case 'Ping Pong':
      case 'Snooker':
        return Icons.table_restaurant;
      case 'Dart':
        return Icons.gps_fixed;
      default:
        return Icons.sports;
    }
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
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '$selectedSport /',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B2420),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => currentStep = 1),
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

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Date Selector
                    _pillButton(
                      label: 'Date: $formattedDate',
                      onTap: _showDatePickerDialog,
                    ),

                    // Start Time Selector
                    _pillButton(
                      label: 'Start: $selectedStartTime',
                      onTap: _showStartTimeSelectorDialog,
                    ),

                    // Duration Selector
                    _pillButton(
                      label:
                          'Duration: $selectedDurationHours hour${selectedDurationHours > 1 ? 's' : ''}',
                      onTap: () {
                        setState(() {
                          selectedDurationHours = selectedDurationHours == 1
                              ? 2
                              : 1;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  '$timeRangeString · RM$ratePerHour.00 per hour',
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

                // Add this selection to the order and return to sport selection.
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
                    onPressed: _addSelectedToCart,
                    child: Text(
                      'Add to cart',
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
                  content: Text(
                    '$courtName is $statusLabel. Please select Court 01.',
                  ),
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
            color: isSelected
                ? primaryGreen
                : (isSelected ? primaryGreen : const Color(0xFFE2E8E4)),
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
  // PANEL 03: Order summary
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
          _buildPanelHeader('03 Your order'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (cartItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Your cart is empty. Add a facility to continue.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                else
                  ...cartItems.map(_buildCartItemCard),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: subtleBorder),
                  ),
                  child: Column(
                    children: [
                      _summaryRow('Total items', '${cartItems.length}'),
                      const SizedBox(height: 10),
                      _summaryRow('Total hours', '$cartTotalHours'),
                      const SizedBox(height: 10),
                      _summaryRow('Student category', widget.category),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Final total',
                              style: TextStyle(
                                color: Color(0xFF103B2B),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'RM${cartTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Availability will be checked again before payment.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(Booking booking) {
    final sport = _sportForBooking(booking);
    final court = _courtForBooking(booking);
    final date = booking.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 76,
            decoration: BoxDecoration(
              color: _sportColor(sport),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sport,
                  style: const TextStyle(
                    color: Color(0xFF103B2B),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$court · ${date.day} ${monthNames[date.month - 1]} ${date.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 3),
                Text(
                  _bookingTimeRange(booking),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RM${booking.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF103B2B),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                tooltip: 'Remove from order',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                icon: const Icon(Icons.delete_outline, size: 19),
                color: Colors.grey.shade500,
                onPressed: () => _removeCartItem(booking),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFF26362D),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _sportForBooking(Booking booking) {
    if (booking.facilityName.startsWith('Badminton')) return 'Badminton';
    if (booking.facilityName.startsWith('Ping Pong')) return 'Ping Pong';
    if (booking.facilityName.startsWith('Snooker')) return 'Snooker';
    if (booking.facilityName.startsWith('Dart')) return 'Dart';
    return booking.facilityName;
  }

  String _courtForBooking(Booking booking) =>
      booking.facilityName.replaceFirst('${_sportForBooking(booking)} ', '');

  Color _sportColor(String sport) {
    switch (sport) {
      case 'Badminton':
        return const Color(0xFF388E3C);
      case 'Ping Pong':
        return const Color(0xFF2878B5);
      case 'Snooker':
        return const Color(0xFF7E57C2);
      case 'Dart':
        return const Color(0xFFD9A321);
      default:
        return primaryGreen;
    }
  }

  String _bookingTimeRange(Booking booking) {
    final start = BookingService.minutesFor(booking.timeSlots.first);
    final end = _formatTime(start + booking.timeSlots.length * 60);
    return '${booking.timeSlots.first} - $end';
  }

  Widget _buildCartBar() {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 80),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: primaryGreen,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${cartItems.length} ${cartItems.length == 1 ? 'item' : 'items'} · RM${cartTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => setState(() => currentStep = 3),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'View my order',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: cartItems.isEmpty
                ? null
                : () => setState(() => currentStep = 4),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Pay RM${cartTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  void _addSelectedToCart() {
    final date = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final startMinutes = BookingService.minutesFor(selectedStartTime);
    final timeSlots = List.generate(
      selectedDurationHours,
      (index) => _formatTime(startMinutes + index * 60),
    );
    final facilityName = _selectedFacilityName;
    final conflictsWithCart = cartItems.any((item) {
      final sameDate =
          item.date.year == date.year &&
          item.date.month == date.month &&
          item.date.day == date.day;
      return item.facilityName == facilityName &&
          sameDate &&
          item.timeSlots.any(timeSlots.contains);
    });

    if (conflictsWithCart ||
        !BookingService.instance.areAllSlotsAvailable(
          facilityName: facilityName,
          date: date,
          timeSlots: timeSlots,
        )) {
      _showMessage(
        'That facility is no longer available for the selected time.',
      );
      return;
    }

    final booking = Booking(
      id: 'CART-${DateTime.now().microsecondsSinceEpoch}',
      userEmail: widget.email,
      facilityName: facilityName,
      date: date,
      timeSlots: timeSlots,
      pricePerSession: ratePerHour,
      participants: 1,
      totalPrice: totalAmount,
    );

    setState(() {
      cartItems.add(booking);
      currentStep = 1;
    });
    _showMessage('Added to your order.');
  }

  void _removeCartItem(Booking booking) {
    setState(() {
      cartItems.removeWhere((item) => item.id == booking.id);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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
                          'RM${cartTotal.toStringAsFixed(2)}',
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
                            Icon(
                              Icons.check,
                              size: 20,
                              color: Color(0xFF2E7D32),
                            ),
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
                          '$generatedBookingRef · ${cartItems.length} ${cartItems.length == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'RM${cartTotal.toStringAsFixed(2)} · ${cartItems.first.date.day} ${monthNames[cartItems.first.date.month - 1]} ${cartItems.first.date.year}',
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
                            Navigator.of(
                              context,
                            ).pop(); // Back to facility info screen
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
    final bookingService = BookingService.instance;
    for (final item in cartItems) {
      if (!bookingService.areAllSlotsAvailable(
        facilityName: item.facilityName,
        date: item.date,
        timeSlots: item.timeSlots,
      )) {
        _showMessage(
          'An item in your order is no longer available. Please review your order.',
        );
        return;
      }
    }

    for (final item in cartItems) {
      final confirmedBooking = Booking(
        id: item.id,
        userEmail: item.userEmail,
        facilityName: item.facilityName,
        date: item.date,
        timeSlots: item.timeSlots,
        pricePerSession: item.pricePerSession,
        participants: item.participants,
        totalPrice: item.totalPrice,
        status: 'Confirmed',
      );
      if (!bookingService.addBooking(confirmedBooking)) {
        _showMessage(
          'An item in your order could not be confirmed. Please review your order.',
        );
        return;
      }
    }

    setState(() {
      generatedBookingRef = cartItems.first.id;
      paymentCompleted = true;
    });
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
      setState(() {
        selectedDate = picked;
        if (!availableStartTimes.contains(selectedStartTime)) {
          selectedStartTime = availableStartTimes.first;
        }
      });
    }
  }

  void _showStartTimeSelectorDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select start time',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.4,
                  ),
                  itemCount: availableStartTimes.length,
                  itemBuilder: (context, index) {
                    final time = availableStartTimes[index];
                    final isSelected = selectedStartTime == time;
                    return OutlinedButton(
                      onPressed: () {
                        setState(() => selectedStartTime = time);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected
                            ? primaryGreen
                            : Colors.white,
                        foregroundColor: isSelected
                            ? Colors.white
                            : primaryGreen,
                        side: BorderSide(
                          color: isSelected ? primaryGreen : subtleBorder,
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: Text(
                        time,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
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
      Offset(rect.left + 8, rect.top),
      Offset(rect.left + 8, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right - 8, rect.top),
      Offset(rect.right - 8, rect.bottom),
      paint,
    );

    // Middle net line
    final midY = rect.top + rect.height / 2;
    canvas.drawLine(
      Offset(rect.left - 2, midY),
      Offset(rect.right + 2, midY),
      paint..strokeWidth = 1.8,
    );
    paint.strokeWidth = 1.2;

    // Service lines
    canvas.drawLine(
      Offset(rect.left, midY - 14),
      Offset(rect.right, midY - 14),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, midY + 14),
      Offset(rect.right, midY + 14),
      paint,
    );

    // Back doubles lines
    canvas.drawLine(
      Offset(rect.left, rect.top + 6),
      Offset(rect.right, rect.top + 6),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom - 6),
      Offset(rect.right, rect.bottom - 6),
      paint,
    );

    // Center dividing lines
    final midX = rect.left + rect.width / 2;
    canvas.drawLine(Offset(midX, rect.top), Offset(midX, midY - 14), paint);
    canvas.drawLine(Offset(midX, midY + 14), Offset(midX, rect.bottom), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
