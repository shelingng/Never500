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

  // 🌟 Live Data Trackers
  List<Booking> _dayBookings = [];
  bool _isLoadingAvailability = false;

  static const List<String> malaysianBanks = [
    'Maybank2u', 'CIMB Clicks', 'Public Bank', 'RHB Now', 'Hong Leong Bank',
    'Bank Islam', 'AmBank', 'Bank Rakyat', 'Affin Bank', 'Alliance Bank',
    'BSN', 'Bank Muamalat', 'Agrobank', 'OCBC Bank', 'UOB Malaysia',
  ];

  static const List<String> _weekdayStartTimes = [
    '5:00 PM', '6:00 PM', '9:00 PM', '10:00 PM',
  ];

  static const List<String> _weekendStartTimes = [
    '10:00 AM', '11:00 AM', '12:00 PM', '3:00 PM', '4:00 PM',
    '5:00 PM', '6:00 PM', '9:00 PM', '10:00 PM',
  ];

  List<String> get availableStartTimes {
    final isWeekend = selectedDate.weekday == DateTime.saturday || selectedDate.weekday == DateTime.sunday;
    return isWeekend ? _weekendStartTimes : _weekdayStartTimes;
  }

  static const List<String> monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get formattedDate => '${selectedDate.day} ${monthNames[selectedDate.month - 1]} ${selectedDate.year}';
  String get calculatedEndTime => _formatTime(_minutesFor(selectedStartTime) + selectedDurationHours * 60);
  String get timeRangeString => '$selectedStartTime–$calculatedEndTime';

  // 🌟 Define precise court quantities per sport
  List<String> get _currentCourts {
    if (selectedSport == 'Badminton') return ['Court 01', 'Court 02'];
    if (selectedSport == 'Ping Pong') return ['Table 01', 'Table 02'];
    if (selectedSport == 'Snooker') return ['Table 01'];
    if (selectedSport == 'Dart') return ['Board 01'];
    return ['Court 01'];
  }

  String _getFullFacilityName(String suffix) {
    if (selectedSport == 'Badminton') return 'Badminton $suffix';
    if (selectedSport == 'Ping Pong') return 'Ping Pong $suffix';
    if (selectedSport == 'Snooker') return 'Snooker $suffix';
    if (selectedSport == 'Dart') return 'Dart $suffix';
    return '$selectedSport $suffix';
  }

  // 🌟 Check live Supabase DB for overlapping times
  String _getCourtStatus(String facilityName, List<String> requestedSlots) {
    // 1. Is it currently in our cart?
    if (cartItems.any((item) => item.facilityName == facilityName && item.date.day == selectedDate.day && item.timeSlots.any((slot) => requestedSlots.contains(slot)))) {
      return 'In Cart';
    }
    
    // 2. Is it actively booked in Supabase?
    if (_dayBookings.any((booking) => booking.facilityName == facilityName && booking.timeSlots.any((slot) => requestedSlots.contains(slot)))) {
      return 'Booked';
    }

    // 3. Simulated Management Lock (For Demo purposes: Badminton Court 02 on Weekends at 10AM is locked by Admin)
    if (facilityName == 'Badminton Court 02' && requestedSlots.contains('10:00 AM') && availableStartTimes == _weekendStartTimes) {
      return 'Management lock';
    }

    return 'Available';
  }

  // 🌟 Fetch Live Bookings From Supabase
  Future<void> _fetchAvailability() async {
    setState(() => _isLoadingAvailability = true);
    try {
      final bookings = await BookingService().getBookingsForDate(selectedDate);
      if (mounted) {
        setState(() {
          _dayBookings = bookings;
          _isLoadingAvailability = false;
          _autoSelectFirstAvailableCourt();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAvailability = false);
    }
  }

  // 🌟 Prevent selecting a booked court by defaulting to the first green one
  void _autoSelectFirstAvailableCourt() {
    final startMinutes = _minutesFor(selectedStartTime);
    final requestedTimeSlots = List.generate(selectedDurationHours, (index) => _formatTime(startMinutes + index * 60));

    bool currentIsAvailable = _getCourtStatus(_getFullFacilityName(selectedCourt), requestedTimeSlots) == 'Available';
    
    if (!currentIsAvailable) {
      for (var suffix in _currentCourts) {
        if (_getCourtStatus(_getFullFacilityName(suffix), requestedTimeSlots) == 'Available') {
          selectedCourt = suffix;
          return;
        }
      }
    }
  }

  int _minutesFor(String time) {
    final parts = time.split(' ');
    final clock = parts[0].split(':');
    var hour = int.parse(clock[0]);
    final minute = int.parse(clock[1]);
    final period = parts[1].toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  int _rateForSport(String sport) {
    if (widget.category == 'KRP Student') {
      if (sport == 'Badminton') return 6;
      if (sport == 'Ping Pong') return 4;
      if (sport == 'Snooker') return 10;
      if (sport == 'Dart') return 3;
      return 6;
    } else {
      if (sport == 'Badminton') return 8;
      if (sport == 'Ping Pong') return 6;
      if (sport == 'Snooker') return 12;
      if (sport == 'Dart') return 5;
      return 8;
    }
  }

  num get ratePerHour => _rateForSport(selectedSport);
  num get totalAmount => ratePerHour * selectedDurationHours;
  num get cartTotal => cartItems.fold(0.0, (total, item) => total + (item.totalPrice as num));
  num get cartTotalHours => cartItems.fold(0, (total, item) => total + (item.timeSlots.length as num));

  String get _selectedFacilityName => _getFullFacilityName(selectedCourt);

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
            const Text('KRP PLAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
            Text('Student view', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
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
      case 1: return _buildStep1ChooseSport();
      case 2: return _buildStep2ChooseCourt();
      case 3: return _buildStep3ReviewBooking();
      case 4: return _buildStep4PaymentAndStatus();
      default: return _buildStep1ChooseSport();
    }
  }

  Widget _buildStep1ChooseSport() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader('01 Choose your sport'),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ${widget.studentName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B2420))),
                const SizedBox(height: 4),
                Text('${widget.category} · Prices shown for your category', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 24),
                _sportCard(title: 'Badminton', sport: 'Badminton'),
                const SizedBox(height: 10),
                _sportCard(title: 'Ping Pong', sport: 'Ping Pong'),
                const SizedBox(height: 10),
                _sportCard(title: 'Snooker', sport: 'Snooker'),
                const SizedBox(height: 10),
                _sportCard(title: 'Dart', sport: 'Dart'),
                const SizedBox(height: 28),
                Text('Availability is subject to KRP Management arrangements.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
          selectedCourt = _currentCourts.first;
          currentStep = 2;
        });
        _fetchAvailability(); // 🌟 Fetch live DB bookings for this day
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
              width: 46, height: 46,
              decoration: BoxDecoration(color: const Color(0xFFEBF5E9), borderRadius: BorderRadius.circular(12)),
              child: Icon(_sportIcon(sport), color: primaryGreen),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF103B2B))),
                  const SizedBox(height: 4),
                  Text('RM${_rateForSport(sport)}.00 / hour', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
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
      case 'Badminton': return Icons.sports_tennis;
      case 'Ping Pong':
      case 'Snooker': return Icons.table_restaurant;
      case 'Dart': return Icons.gps_fixed;
      default: return Icons.sports;
    }
  }

  Widget _buildStep2ChooseCourt() {
    final startMinutes = _minutesFor(selectedStartTime);
    final requestedTimeSlots = List.generate(selectedDurationHours, (index) => _formatTime(startMinutes + index * 60));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader('02 Choose your court'),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 4, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('$selectedSport /', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B2420))),
                    InkWell(
                      onTap: () => setState(() => currentStep = 1),
                      child: Text('Change sport', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _pillButton(label: 'Date: $formattedDate', onTap: _showDatePickerDialog),
                    _pillButton(label: 'Start: $selectedStartTime', onTap: _showStartTimeSelectorDialog),
                    _pillButton(label: 'Duration: $selectedDurationHours hour${selectedDurationHours > 1 ? 's' : ''}', onTap: () {
                      setState(() => selectedDurationHours = selectedDurationHours == 1 ? 2 : 1);
                      _autoSelectFirstAvailableCourt(); // Recheck slots
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                Text('$timeRangeString · RM$ratePerHour.00 per hour', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF103B2B))),
                const SizedBox(height: 20),

                // 🌟 DYNAMIC COURTS ROW
                if (_isLoadingAvailability)
                  const Padding(padding: EdgeInsets.all(32.0), child: Center(child: CircularProgressIndicator(color: Color(0xFF103B2B))))
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(2, (index) {
                      if (index < _currentCourts.length) {
                        final courtSuffix = _currentCourts[index];
                        final fullFacilityName = _getFullFacilityName(courtSuffix);
                        final status = _getCourtStatus(fullFacilityName, requestedTimeSlots);
                        
                        Color statusColor;
                        Color surfaceTint;
                        bool isSelectable = false;

                        if (status == 'Available') {
                          statusColor = const Color(0xFF2E7D32);
                          surfaceTint = const Color(0xFFF3FAF5);
                          isSelectable = true;
                        } else if (status == 'Booked' || status == 'In Cart') {
                          statusColor = const Color(0xFFD32F2F);
                          surfaceTint = const Color(0xFFFDF2F2);
                        } else {
                          statusColor = const Color(0xFF757575);
                          surfaceTint = const Color(0xFFF5F5F5);
                        }

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: index == 0 && _currentCourts.length > 1 ? 10 : 0),
                            child: _courtCard(
                              courtName: courtSuffix,
                              statusLabel: status,
                              statusColor: statusColor,
                              surfaceTint: surfaceTint,
                              isSelectable: isSelectable,
                              isSelected: selectedCourt == courtSuffix && isSelectable,
                            ),
                          ),
                        );
                      } else {
                        // Invisible spacer for 1-court sports to keep UI alignment
                        return const Expanded(child: SizedBox());
                      }
                    }),
                  ),

                const SizedBox(height: 16),
                Text('Selected: $selectedCourt', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B2420))),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: _addSelectedToCart,
                    child: const Text('Add to cart', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
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
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2C3E34))),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _courtCard({required String courtName, required String statusLabel, required Color statusColor, required Color surfaceTint, required bool isSelectable, required bool isSelected}) {
    return InkWell(
      onTap: isSelectable ? () => setState(() => selectedCourt = courtName) : () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$courtName is $statusLabel.')));
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? primaryGreen : const Color(0xFFE2E8E4), width: isSelected ? 2.5 : 1.0),
        ),
        child: Column(
          children: [
            Container(
              height: 110, width: double.infinity,
              decoration: BoxDecoration(color: surfaceTint, borderRadius: BorderRadius.circular(6), border: Border.all(color: statusColor.withValues(alpha: 0.5))),
              child: CustomPaint(painter: _PrototypeCourtPainter(lineColor: statusColor)),
            ),
            const SizedBox(height: 8),
            Text(courtName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2420))),
            const SizedBox(height: 2),
            Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3ReviewBooking() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: subtleBorder),
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
                  Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('Your cart is empty. Add a facility to continue.', style: TextStyle(color: Colors.grey.shade600)))
                else
                  ...cartItems.map(_buildCartItemCard),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF7F9F7), borderRadius: BorderRadius.circular(12), border: Border.all(color: subtleBorder)),
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
                          const Expanded(child: Text('Final total', style: TextStyle(color: Color(0xFF103B2B), fontSize: 15, fontWeight: FontWeight.bold))),
                          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('RM${cartTotal.toStringAsFixed(2)}', style: TextStyle(color: primaryGreen, fontSize: 22, fontWeight: FontWeight.bold)))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(Booking booking) {
    final sport = selectedSport;
    final court = booking.facilityName.replaceFirst('$selectedSport ', '');
    final date = booking.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subtleBorder),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 76, decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sport, style: const TextStyle(color: Color(0xFF103B2B), fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$court · ${date.day} ${monthNames[date.month - 1]} ${date.year}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 3),
                Text('${booking.timeSlots.first} - ${_formatTime(_minutesFor(booking.timeSlots.first.toString()) + (booking.timeSlots.length as int) * 60)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),              ],
            ),
          ),
          Column(
            children: [
              Text('RM${booking.totalPrice}', style: const TextStyle(color: Color(0xFF103B2B), fontSize: 14, fontWeight: FontWeight.bold)),
              IconButton(
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
        Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
        Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: Color(0xFF26362D), fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _buildCartBar() {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 80),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(color: primaryGreen, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, -3))]),
        child: Row(
          children: [
            Expanded(child: Text('${cartItems.length} items · RM${cartTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
            ElevatedButton(
              onPressed: () => setState(() => currentStep = 3),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
              child: const Text('View order', style: TextStyle(fontWeight: FontWeight.bold)),
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
          height: 50, width: double.infinity,
          child: ElevatedButton(
            onPressed: cartItems.isEmpty ? null : () => setState(() => currentStep = 4),
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Pay RM${cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  void _addSelectedToCart() {
    final date = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final startMinutes = _minutesFor(selectedStartTime);
    final timeSlots = List.generate(selectedDurationHours, (index) => _formatTime(startMinutes + index * 60));
    final facilityName = _selectedFacilityName;

    if (_getCourtStatus(facilityName, timeSlots) != 'Available') {
      _showMessage('That facility is no longer available for the selected time.');
      return;
    }

    final booking = Booking(
      id: 'CART-${DateTime.now().microsecondsSinceEpoch}',
      userId: widget.email, 
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
    setState(() => cartItems.removeWhere((item) => item.id == booking.id));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildStep4PaymentAndStatus() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader('04 Payment & booking status'),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!paymentCompleted) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: subtleBorder)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Amount due', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 3),
                            const Text('Booking total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF304137))),
                          ],
                        ),
                        Text('RM${cartTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryGreen)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Select payment method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildPaymentMethodOption(
                    title: 'FPX Online Banking',
                    subtitle: 'All Malaysian banks',
                    icon: Icons.account_balance_outlined,
                    selected: selectedPaymentMethod == 'FPX',
                    onTap: () => setState(() => selectedPaymentMethod = 'FPX'),
                    expandedContent: DropdownButtonFormField<String>(
                      key: ValueKey<String?>(selectedBank),
                      initialValue: selectedBank,
                      decoration: InputDecoration(labelText: 'Choose your bank', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                      items: malaysianBanks.map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
                      onChanged: (bank) => setState(() => selectedBank = bank),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentMethodOption(
                    title: 'E-Wallet',
                    subtitle: "Touch 'n Go eWallet",
                    icon: Icons.account_balance_wallet_outlined,
                    selected: selectedPaymentMethod == 'E-Wallet',
                    onTap: () => setState(() => selectedPaymentMethod = 'E-Wallet'),
                    expandedContent: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAF8), borderRadius: BorderRadius.circular(10), border: Border.all(color: subtleBorder)),
                      child: const Row(children: [Icon(Icons.wallet_outlined, color: Color(0xFF315A3B)), SizedBox(width: 10), Expanded(child: Text("Touch 'n Go eWallet", style: TextStyle(fontWeight: FontWeight.w600))), Icon(Icons.check_circle, color: Color(0xFF315A3B))]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: _canSubmitPayment ? _processDemoPayment : null,
                      child: const Text('Pay Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                if (paymentCompleted) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFEBF5E9), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC7E5C3))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [Icon(Icons.check, size: 20, color: Color(0xFF2E7D32)), SizedBox(width: 8), Text('Booking confirmed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))]),
                        const SizedBox(height: 10),
                        Text('$generatedBookingRef · ${cartItems.length} items', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('RM${cartTotal.toStringAsFixed(2)} · ${cartItems.first.date.day} ${monthNames[cartItems.first.date.month - 1]} ${cartItems.first.date.year}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text('View booking details →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryGreen)),
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

  bool get _canSubmitPayment => selectedPaymentMethod == 'E-Wallet' || (selectedPaymentMethod == 'FPX' && selectedBank != null);

  Widget _buildPaymentMethodOption({required String title, required String subtitle, required IconData icon, required bool selected, required VoidCallback onTap, required Widget expandedContent}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: selected ? const Color(0xFFF5F9F3) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? primaryGreen : const Color(0xFFE2E8E4), width: selected ? 1.5 : 1)),
            child: Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFEDF4E9), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: primaryGreen)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF304137))), Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))])),
                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? primaryGreen : Colors.grey.shade400),
              ],
            ),
          ),
        ),
        if (selected) Padding(padding: const EdgeInsets.only(left: 12, right: 12, top: 10), child: expandedContent),
      ],
    );
  }

  void _processDemoPayment() async {
    final bookingService = BookingService();
    try {
      for (final item in cartItems) {
        final confirmedBooking = Booking(
          id: item.id, userId: item.userId, facilityName: item.facilityName,
          date: item.date, timeSlots: item.timeSlots, pricePerSession: item.pricePerSession,
          participants: item.participants, totalPrice: item.totalPrice, status: 'Confirmed',
        );
        final response = await bookingService.createBooking(confirmedBooking, widget.category);
        await bookingService.confirmPayment(response['id'], confirmedBooking.totalPrice, selectedPaymentMethod);
      }
      setState(() { generatedBookingRef = 'KRP-CONFIRMED'; paymentCompleted = true; });
    } catch (e) {
      _showMessage('Error processing booking: $e');
    }
  }

  Widget _buildPanelHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: primaryGreen, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  void _showDatePickerDialog() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryGreen, onPrimary: Colors.white)), child: child!),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        if (!availableStartTimes.contains(selectedStartTime)) selectedStartTime = availableStartTimes.first;
      });
      _fetchAvailability(); // Re-fetch the live bookings for the new date!
    }
  }

  void _showStartTimeSelectorDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select start time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.4),
                itemCount: availableStartTimes.length,
                itemBuilder: (context, index) {
                  final time = availableStartTimes[index];
                  final isSelected = selectedStartTime == time;
                  return OutlinedButton(
                    onPressed: () { 
                      setState(() => selectedStartTime = time); 
                      _autoSelectFirstAvailableCourt(); 
                      Navigator.pop(context); 
                    },
                    style: OutlinedButton.styleFrom(backgroundColor: isSelected ? primaryGreen : Colors.white, foregroundColor: isSelected ? Colors.white : primaryGreen, side: BorderSide(color: isSelected ? primaryGreen : subtleBorder), padding: EdgeInsets.zero),
                    child: Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrototypeCourtPainter extends CustomPainter {
  final Color lineColor;
  _PrototypeCourtPainter({required this.lineColor});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = lineColor..style = PaintingStyle.stroke..strokeWidth = 1.2;
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRect(rect, paint);
    canvas.drawLine(Offset(rect.left + 8, rect.top), Offset(rect.left + 8, rect.bottom), paint);
    canvas.drawLine(Offset(rect.right - 8, rect.top), Offset(rect.right - 8, rect.bottom), paint);
    final midY = rect.top + rect.height / 2;
    canvas.drawLine(Offset(rect.left - 2, midY), Offset(rect.right + 2, midY), paint..strokeWidth = 1.8);
    paint.strokeWidth = 1.2;
    canvas.drawLine(Offset(rect.left, midY - 14), Offset(rect.right, midY - 14), paint);
    canvas.drawLine(Offset(rect.left, midY + 14), Offset(rect.right, midY + 14), paint);
    canvas.drawLine(Offset(rect.left, rect.top + 6), Offset(rect.right, rect.top + 6), paint);
    canvas.drawLine(Offset(rect.left, rect.bottom - 6), Offset(rect.right, rect.bottom - 6), paint);
    final midX = rect.left + rect.width / 2;
    canvas.drawLine(Offset(midX, rect.top), Offset(midX, midY - 14), paint);
    canvas.drawLine(Offset(midX, midY + 14), Offset(midX, rect.bottom), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}