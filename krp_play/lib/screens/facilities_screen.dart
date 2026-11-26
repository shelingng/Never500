import 'dart:async';

import 'package:flutter/material.dart';
import '../models/student_category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/booking.dart';
import '../models/checkout_recovery.dart';
import '../services/booking_service.dart';

class FacilitiesScreen extends StatefulWidget {
  final String category;
  final String email;
  final String studentName;
  final BookingService? bookingService;

  const FacilitiesScreen({
    super.key,
    required this.category,
    required this.email,
    this.studentName = 'Yu Xiang',
    this.bookingService,
  });

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  late final BookingService _bookingService =
      widget.bookingService ?? BookingService();
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _bookingsChannel;
  Timer? _availabilityTimer;

  List _facilities = [];
  bool _loadingPrices = true;
  bool _priceLoadFailed = false;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _loadPrices();
    if (_bookingService.usesRealPayment) _recoverCheckout();
    // The Billplz page opens in another tab. When the user comes back,
    // check the payment automatically instead of waiting for a button press.
    _lifecycleListener = AppLifecycleListener(onResume: _onAppResumed);
    _bookingsChannel = _supabase
        .channel('student:facilities_bookings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) {
            if (mounted && currentStep == 2) {
              _fetchAvailability(showLoader: false);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'time_slots',
          callback: (_) {
            if (mounted && currentStep == 2) {
              _fetchAvailability(showLoader: false);
            }
          },
        )
        .subscribe();

    _availabilityTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted &&
          currentStep == 2 &&
          !_isLoadingAvailability &&
          !_isReserving) {
        _fetchAvailability(showLoader: false);
      }
    });
  }

  void _onAppResumed() {
    if (_pendingBookingId != null && !reservationCreated) {
      _checkPaymentStatus(quiet: true);
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _availabilityTimer?.cancel();
    if (_bookingsChannel != null) {
      _supabase.removeChannel(_bookingsChannel!);
    }
    super.dispose();
  }

  Future<void> _loadPrices() async {
    setState(() {
      _loadingPrices = true;
      _priceLoadFailed = false;
    });
    try {
      final rows = await _bookingService.getFacilities();
      if (!mounted) return;
      setState(() {
        _facilities = (rows as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        _loadingPrices = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingPrices = false;
          _priceLoadFailed = true;
        });
      }
    }
  }

  int currentStep = 1;

  final Color primaryGreen = const Color(0xFF103B2B);
  final Color subtleBorder = const Color(0xFFE2E8E4);

  String selectedSport = 'Badminton';
  String selectedCourt = 'Court 01';

  DateTime selectedDate = DateTime.now();
  String selectedStartTime = '9:00 PM';
  int selectedDurationHours = 1;
  final List<Booking> cartItems = [];

  bool reservationCreated = false;
  bool _isReserving = false;
  String? _checkoutRequestId;
  num? _reservedTotal;
  String? _pendingBookingId;
  DateTime? _paymentDeadline;
  String? _paymentUrl;
  bool _checkingPayment = false;
  bool _recoveringCheckout = false;
  String? _recoveryError;
  bool _paidViaBillplz = false;
  String? _availabilityError;
  int _availabilityRequest = 0;
  String generatedBookingRef = '';
  String selectedPaymentMethod = '';
  String? selectedBank;

  List<Booking> _dayBookings = [];
  bool _isLoadingAvailability = false;

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
  String get calculatedEndTime =>
      _formatTime(_minutesFor(selectedStartTime) + selectedDurationHours * 60);
  String get timeRangeString => '$selectedStartTime–$calculatedEndTime';

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

  String _normalizeFacilityKey(String raw) {
    var s = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceFirstMapped(RegExp(r' 0+(\d+)$'), (m) => ' ${m[1]}');
    if (s == 'dart board' || s == 'dart' || s == 'board 1' || s == 'dart 1') {
      return 'dart 1';
    }
    if (s == 'snooker table' ||
        s == 'snooker' ||
        s == 'table 1' ||
        s == 'snooker 1') {
      return 'snooker 1';
    }
    return s;
  }

  bool _sameFacility(String a, String b) {
    if (a.trim().isEmpty || b.trim().isEmpty) return false;
    return _normalizeFacilityKey(a) == _normalizeFacilityKey(b);
  }

  String _getCourtStatus(String facilityName, List<String> requestedSlots) {
    if (_availabilityError != null) return 'Unavailable';
    for (final booking in _dayBookings) {
      final stat = booking.status.trim().toLowerCase();
      if (_sameFacility(booking.facilityName, facilityName) &&
          booking.timeSlots.any((slot) => requestedSlots.contains(slot))) {
        if (stat.contains('closed') || stat.contains('maintenance')) {
          return 'Closed';
        }
        return switch (stat) {
          'booked' => 'Booked',
          'reserved' => 'Reserved',
          'past' => 'Session ended',
          _ => 'Booked',
        };
      }
    }

    if (cartItems.any(
      (item) =>
          _sameFacility(item.facilityName, facilityName) &&
          DateUtils.isSameDay(item.date, selectedDate) &&
          item.timeSlots.any((slot) => requestedSlots.contains(slot)),
    )) {
      return 'In Cart';
    }

    return 'Available';
  }

  Future<void> _fetchAvailability({bool showLoader = true}) async {
    final request = ++_availabilityRequest;
    final date = selectedDate;
    if (showLoader && mounted) {
      setState(() {
        _isLoadingAvailability = true;
        _availabilityError = null;
      });
    }
    try {
      final bookings = await _bookingService.getBookingsForDate(date);
      if (!mounted || request != _availabilityRequest) return;
      setState(() {
        _dayBookings = bookings;
        _isLoadingAvailability = false;
        _availabilityError = null;
        _autoSelectFirstAvailableCourt();
      });
    } catch (error, stackTrace) {
      debugPrint('Facility availability failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted || request != _availabilityRequest) return;
      setState(() {
        _isLoadingAvailability = false;
        _availabilityError = 'Availability could not be loaded. Please retry.';
        _dayBookings = [];
      });
    }
  }

  void _autoSelectFirstAvailableCourt() {
    final startMinutes = _minutesFor(selectedStartTime);
    final requestedTimeSlots = List.generate(
      selectedDurationHours,
      (index) => _formatTime(startMinutes + index * 60),
    );

    bool currentIsAvailable =
        _getCourtStatus(
          _getFullFacilityName(selectedCourt),
          requestedTimeSlots,
        ) ==
        'Available';

    if (!currentIsAvailable) {
      for (var suffix in _currentCourts) {
        if (_getCourtStatus(_getFullFacilityName(suffix), requestedTimeSlots) ==
            'Available') {
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

  num _rateForSport(String sport) {
    final rows = _facilities.where(
      (f) => f['name'].toString().startsWith('$sport '),
    );
    if (rows.isEmpty) return 0;
    return _priceFor(rows.first);
  }

  // SCRUM-38: a missing or unknown category is never given the KRP rate.
  StudentCategory? get _studentCategory =>
      StudentCategory.parse(widget.category);

  num _priceFor(Map<String, dynamic> facility) {
    return facility[(_studentCategory ?? StudentCategory.nonKrp).priceColumn]
        as num;
  }

  num get ratePerHour {
    final name = _selectedFacilityName.replaceFirstMapped(
      RegExp(r' 0+(\d+)$'),
      (m) => ' ${m[1]}',
    );
    final rows = _facilities.where((f) => f['name'] == name);
    return rows.isEmpty ? _rateForSport(selectedSport) : _priceFor(rows.first);
  }

  num get totalAmount => ratePerHour * selectedDurationHours;
  num get cartTotal =>
      cartItems.fold(0.0, (total, item) => total + (item.totalPrice as num));
  num get cartTotalHours => cartItems.fold(
    0,
    (total, item) => total + (item.timeSlots.length as num),
  );

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
            if (_isReserving) return;
            if (currentStep > 1 &&
                !reservationCreated &&
                _pendingBookingId == null) {
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
    if (_recoveringCheckout) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking your unfinished checkout...'),
          ],
        ),
      );
    }
    if (_recoveryError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_recoveryError!),
          TextButton(
            onPressed: _recoverCheckout,
            child: const Text('Retry checkout recovery'),
          ),
        ],
      );
    }
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
                if (_loadingPrices) const LinearProgressIndicator(),
                if (_priceLoadFailed)
                  TextButton(
                    onPressed: _loadPrices,
                    child: const Text('Prices could not be loaded. Retry'),
                  ),
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
      onTap:
          _loadingPrices ||
              _priceLoadFailed ||
              !_facilities.any(
                (f) => f['name'].toString().startsWith('$sport '),
              )
          ? null
          : () {
              setState(() {
                selectedSport = sport;
                selectedCourt = _currentCourts.first;
                currentStep = 2;
              });
              _fetchAvailability();
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
              child: sport == 'Ping Pong' || sport == 'Snooker'
                  ? Center(
                      child: CustomPaint(
                        size: const Size(28, 28),
                        painter: _SportChoiceIconPainter(
                          sport: sport,
                          color: primaryGreen,
                        ),
                      ),
                    )
                  : Icon(_sportIcon(sport), color: primaryGreen),
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
                    'RM${_rateForSport(sport).toStringAsFixed(2)} / hour',
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

  Widget _buildStep2ChooseCourt() {
    final startMinutes = _minutesFor(selectedStartTime);
    final requestedTimeSlots = List.generate(
      selectedDurationHours,
      (index) => _formatTime(startMinutes + index * 60),
    );

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
                    _pillButton(
                      label: 'Date: $formattedDate',
                      onTap: _showDatePickerDialog,
                    ),
                    _pillButton(
                      label: 'Start: $selectedStartTime',
                      onTap: _showStartTimeSelectorDialog,
                    ),
                    _pillButton(
                      label:
                          'Duration: $selectedDurationHours hour${selectedDurationHours > 1 ? 's' : ''}',
                      onTap: () {
                        setState(
                          () => selectedDurationHours =
                              selectedDurationHours == 1 ? 2 : 1,
                        );
                        _autoSelectFirstAvailableCourt();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$timeRangeString · RM${ratePerHour.toStringAsFixed(2)} per hour',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF103B2B),
                  ),
                ),
                const SizedBox(height: 20),

                if (_availabilityError != null)
                  TextButton.icon(
                    onPressed: _fetchAvailability,
                    icon: const Icon(Icons.refresh),
                    label: Text(_availabilityError!),
                  ),

                if (_isLoadingAvailability)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF103B2B),
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(2, (index) {
                      if (index < _currentCourts.length) {
                        final courtSuffix = _currentCourts[index];
                        final fullFacilityName = _getFullFacilityName(
                          courtSuffix,
                        );
                        final status = _getCourtStatus(
                          fullFacilityName,
                          requestedTimeSlots,
                        );

                        Color statusColor;
                        Color surfaceTint;
                        bool isSelectable = false;

                        if (status == 'Available') {
                          statusColor = const Color(0xFF2E7D32);
                          surfaceTint = const Color(0xFFF3FAF5);
                          isSelectable = true;
                        } else if (status == 'Booked' ||
                            status == 'Reserved' ||
                            status == 'In Cart') {
                          statusColor = const Color(0xFFD32F2F);
                          surfaceTint = const Color(0xFFFDF2F2);
                        } else {
                          statusColor = const Color(0xFF757575);
                          surfaceTint = const Color(0xFFF5F5F5);
                        }

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == 0 && _currentCourts.length > 1
                                  ? 10
                                  : 0,
                            ),
                            child: _courtCard(
                              courtName: courtSuffix,
                              statusLabel: status,
                              statusColor: statusColor,
                              surfaceTint: surfaceTint,
                              isSelectable: isSelectable,
                              isSelected:
                                  selectedCourt == courtSuffix && isSelectable,
                            ),
                          ),
                        );
                      } else {
                        return const Expanded(child: SizedBox());
                      }
                    }),
                  ),

                const SizedBox(height: 16),
                Text(
                  'Selected: $selectedCourt',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B2420),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed:
                        _isLoadingAvailability ||
                            _availabilityError != null ||
                            _getCourtStatus(
                                  _selectedFacilityName,
                                  requestedTimeSlots,
                                ) !=
                                'Available'
                        ? null
                        : _addSelectedToCart,
                    child: const Text(
                      'Add to cart',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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
          ? () => setState(() => selectedCourt = courtName)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$courtName is $statusLabel.')),
              );
            },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryGreen : const Color(0xFFE2E8E4),
            width: isSelected ? 2.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: surfaceTint,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              ),
              child: CustomPaint(
                painter: _PrototypeCourtPainter(
                  lineColor: statusColor,
                  sport: selectedSport,
                ),
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
            ),
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
                      _summaryRow(
                        'Student category',
                        StudentCategory.labelFor(widget.category),
                      ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(Booking booking) {
    final facilityName = booking.facilityName.toString();
    final sport = facilityName
        .split(RegExp(r'\s+(?:Court|Table|Board)\b', caseSensitive: false))
        .first;
    final court = facilityName.startsWith('$sport ')
        ? facilityName.substring(sport.length + 1)
        : facilityName;
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
          Container(
            width: 4,
            height: 76,
            decoration: BoxDecoration(
              color: primaryGreen,
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
                  '${booking.timeSlots.first} - ${_formatTime(_minutesFor(booking.timeSlots.first.toString()) + (booking.timeSlots.length as int) * 60)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                'RM${(booking.totalPrice as num).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF103B2B),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
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
                '${cartItems.length} items · RM${cartTotal.toStringAsFixed(2)}',
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'View order',
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
    final startMinutes = _minutesFor(selectedStartTime);
    final timeSlots = List.generate(
      selectedDurationHours,
      (index) => _formatTime(startMinutes + index * 60),
    );
    final facilityName = _selectedFacilityName;

    if (_getCourtStatus(facilityName, timeSlots) != 'Available') {
      _showMessage(
        'That facility is no longer available for the selected time.',
      );
      return;
    }

    // The same session twice would double the total and be rejected at Pay
    // (DUPLICATE_CART_SLOT), so stop it here with a clear message.
    final overlapsCart = cartItems.any(
      (item) =>
          item.facilityName == facilityName &&
          DateUtils.isSameDay(item.date, date) &&
          List<String>.from(item.timeSlots as List).any(timeSlots.contains),
    );
    if (overlapsCart) {
      _showMessage(
        'This time is already in your order for $facilityName. Choose a different time.',
      );
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
      _checkoutRequestId = null;
      cartItems.add(booking);
      currentStep = 1;
    });
    _showMessage('Added to your order.');
  }

  void _removeCartItem(Booking booking) {
    setState(() {
      _checkoutRequestId = null;
      cartItems.removeWhere((item) => item.id == booking.id);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                if (!reservationCreated) ...[
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
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
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
                          'RM${(_reservedTotal ?? cartTotal).toStringAsFixed(2)}',
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
                  if (_bookingService.usesRealPayment && _paymentUrl != null)
                    _buildAwaitingPaymentPanel()
                  else if (_bookingService.usesRealPayment) ...[
                    const Text(
                      'You will be taken to Billplz to pay securely with FPX online banking or an e-wallet.',
                    ),
                    const SizedBox(height: 20),
                    _buildPayNowButton(),
                  ] else ...[
                    const Text(
                      'Prototype demo: Pay Now simulates payment. No money is charged.',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Select payment method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentMethodOption(
                      title: 'FPX Online Banking',
                      subtitle: 'All Malaysian banks',
                      icon: Icons.account_balance_outlined,
                      selected: selectedPaymentMethod == 'FPX',
                      onTap: () =>
                          setState(() => selectedPaymentMethod = 'FPX'),
                      expandedContent: DropdownButtonFormField<String>(
                        key: ValueKey<String?>(selectedBank),
                        initialValue: selectedBank,
                        decoration: InputDecoration(
                          labelText: 'Choose your bank',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
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
                        onChanged: (bank) =>
                            setState(() => selectedBank = bank),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentMethodOption(
                      title: 'E-Wallet',
                      subtitle: "Touch 'n Go eWallet",
                      icon: Icons.account_balance_wallet_outlined,
                      selected: selectedPaymentMethod == 'E-Wallet',
                      onTap: () =>
                          setState(() => selectedPaymentMethod = 'E-Wallet'),
                      expandedContent: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAF8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: subtleBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.wallet_outlined,
                              color: Color(0xFF315A3B),
                            ),
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
                    _buildPayNowButton(),
                  ],
                ],
                if (reservationCreated) ...[
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
                              Icons.check_circle_outline,
                              size: 20,
                              color: Color(0xFF2E7D32),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Payment successful',
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
                          _paidViaBillplz
                              ? 'Payment received - booking confirmed'
                              : 'Demo payment successful - booking confirmed',
                        ),
                        Text(
                          '$generatedBookingRef · ${cartItems.length} items',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'RM${(_reservedTotal ?? cartTotal).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _paidViaBillplz
                              ? 'Paid via Billplz.'
                              : 'Demo only. No money was charged.',
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
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
      _bookingService.usesRealPayment ||
      selectedPaymentMethod == 'E-Wallet' ||
      (selectedPaymentMethod == 'FPX' && selectedBank != null);

  Widget _buildPayNowButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _canSubmitPayment && !_isReserving
            ? _reserveSelectedCart
            : null,
        child: Text(
          _isReserving
              ? 'Processing...'
              : (_pendingBookingId == null ? 'Pay Now' : 'Resume payment'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _deadlineLabel(DateTime deadline) {
    final kl = deadline.toUtc().add(const Duration(hours: 8));
    final hour = kl.hour % 12 == 0 ? 12 : kl.hour % 12;
    final minute = kl.minute.toString().padLeft(2, '0');
    return '${kl.day} ${monthNames[kl.month - 1]} ${kl.year}, $hour:$minute ${kl.hour < 12 ? 'AM' : 'PM'} (MYT)';
  }

  Widget _buildAwaitingPaymentPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1D48A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Slots reserved - complete your payment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$generatedBookingRef · RM${(_reservedTotal ?? cartTotal).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _paymentDeadline == null
                ? 'Complete payment before your reservation expires, then return here to check its status.'
                : 'Original payment deadline: ${_deadlineLabel(_paymentDeadline!)}. Resuming does not extend your hold.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open Billplz payment page'),
              onPressed: _openPaymentPage,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: _checkingPayment ? null : _checkPaymentStatus,
              child: Text(
                _checkingPayment ? 'Checking...' : "I've paid - check status",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaymentPage() async {
    final url = _paymentUrl;
    if (url == null) return;
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!opened && mounted) {
      _showMessage(
        'Could not open the payment page. Allow pop-ups and try again.',
      );
    }
  }

  Future<void> _recoverCheckout() async {
    if (_recoveringCheckout) return;
    final owner = _bookingService.checkoutUserId;
    setState(() {
      _recoveringCheckout = true;
      _recoveryError = null;
    });
    try {
      final saved = await _bookingService.getCheckoutForRecovery();
      if (!mounted || _bookingService.checkoutUserId != owner) return;
      if (saved != null) {
        if (saved.cart.isEmpty) {
          throw StateError(
            'This unfinished order has no recoverable sessions.',
          );
        }
        _applyRecoveredCheckout(saved);
        if (!saved.canResumeAt(DateTime.now())) {
          await _resetExpiredPayment();
          if (mounted)
            _showMessage(
              'Your previous hold expired. Your cart was restored. Review availability before paying again.',
            );
        } else {
          _showMessage(
            'Your unfinished order was restored. Resume payment to continue with the same booking.',
          );
        }
      }
    } catch (error) {
      debugPrint('Checkout recovery failed: $error');
      if (mounted) {
        setState(
          () => _recoveryError =
              'Could not check your unfinished order. Retry before starting another checkout.',
        );
      }
    } finally {
      if (mounted) setState(() => _recoveringCheckout = false);
    }
  }

  void _applyRecoveredCheckout(CheckoutRecovery saved) {
    setState(() {
      cartItems
        ..clear()
        ..addAll(saved.cart);
      _pendingBookingId = saved.order.id;
      _paymentDeadline = saved.order.paymentDeadline;
      _checkoutRequestId = saved.requestId;
      _reservedTotal = saved.order.total;
      generatedBookingRef = saved.order.reference;
      selectedDate = saved.cart.first.date;
      currentStep = 4;
      _paymentUrl = null;
    });
  }

  /// Re-check the owned order before reusing/creating its Billplz bill.
  /// This path never calls reserveCart.
  Future<void> _resumePendingCheckout() async {
    final bookingId = _pendingBookingId;
    if (bookingId == null) return;
    final owner = _bookingService.checkoutUserId;
    final saved = await _bookingService.getCheckoutForRecovery(
      bookingId: bookingId,
    );
    if (!mounted || _bookingService.checkoutUserId != owner) return;
    if (saved == null) {
      throw const PaymentException(
        'This order is no longer available. Check your booking history.',
      );
    }
    if (saved.order.status.toLowerCase() == 'confirmed') {
      setState(() {
        _paidViaBillplz = true;
        reservationCreated = true;
        _paymentUrl = null;
      });
      return;
    }
    if (!saved.canResumeAt(DateTime.now())) {
      await _resetExpiredPayment();
      if (mounted)
        _showMessage(
          'This order can no longer be paid. Review your cart and booking history before checking out again.',
        );
      return;
    }
    final url = await _bookingService.createBillplzPayment(bookingId);
    if (!mounted || _bookingService.checkoutUserId != owner) return;
    setState(() => _paymentUrl = url);
  }

  // Drop the expired hold; keep the restored cart for a fresh availability check.
  Future<void> _resetExpiredPayment() async {
    setState(() {
      _paymentUrl = null;
      _pendingBookingId = null;
      _paymentDeadline = null;
      _checkoutRequestId = null;
      _reservedTotal = null;
      currentStep = 2;
    });
    await _fetchAvailability();
  }

  /// quiet = true when the user returns from Billplz on their own:
  /// only show a message when something actually changed.
  Future<void> _checkPaymentStatus({bool quiet = false}) async {
    final bookingId = _pendingBookingId;
    if (bookingId == null || _checkingPayment) return;
    setState(() => _checkingPayment = true);
    try {
      final result = await _bookingService.getPaymentStatus(bookingId);
      if (!mounted) return;
      final status = result['bookingStatus'];
      final lastAttempt = result['lastAttempt'];
      final deadline = DateTime.tryParse(
        result['paymentDeadline']?.toString() ?? '',
      );
      final holdExpired = deadline != null && !deadline.isAfter(DateTime.now());

      if (status == 'confirmed') {
        setState(() {
          _paidViaBillplz = true;
          reservationCreated = true;
          _paymentUrl = null;
        });
      } else if (status == 'expired' || holdExpired) {
        _showMessage(
          lastAttempt == 'completed'
              ? 'Payment arrived after your hold expired and the session was no longer available. A refund has been opened for you automatically.'
              : 'Your 10-minute hold expired. Your cart is kept - check the slots and pay again.',
        );
        await _resetExpiredPayment();
      } else if (lastAttempt == 'failed') {
        _showMessage(
          'Payment failed. No money was taken. Tap "Open Billplz payment page" to try again.',
        );
      } else if (lastAttempt == 'completed') {
        _showMessage(
          'Payment received. Confirming your booking - check again in a few seconds.',
        );
      } else if (!quiet) {
        _showMessage(
          'Payment not received yet. Complete it on the Billplz page, then check again.',
        );
      }
    } on PaymentException catch (e) {
      if (mounted && !quiet) _showMessage(e.message);
    } catch (_) {
      if (mounted && !quiet) {
        _showMessage('Could not check the payment status. Try again.');
      }
    } finally {
      if (mounted) setState(() => _checkingPayment = false);
    }
  }

  Widget _buildPaymentMethodOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required Widget expandedContent,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF5F9F3) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? primaryGreen : const Color(0xFFE2E8E4),
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
        if (selected)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
            child: expandedContent,
          ),
      ],
    );
  }

  Future<void> _removeConflictingCartItems() async {
    final cartSnapshot = List<Booking>.from(cartItems);
    final unavailable = <Booking>[];
    final dates = <DateTime, List<Booking>>{};
    try {
      for (final item in cartSnapshot) {
        final date = DateUtils.dateOnly(item.date);
        final bookings = dates[date] ??= await _bookingService
            .getBookingsForDate(date);
        final requestedSlots = List<String>.from(item.timeSlots as List);
        final blocked = bookings.any((booking) {
          if (!_sameFacility(booking.facilityName, item.facilityName))
            return false;
          final occupiedSlots = List<String>.from(booking.timeSlots as List);
          return occupiedSlots.any(requestedSlots.contains);
        });
        if (blocked) unavailable.add(item);
      }
    } catch (error) {
      debugPrint('Cart conflict cleanup failed: $error');
      if (!mounted) return;
      _showMessage(
        'A selected slot is reserved or booked. No payment was taken. Choose another time.',
      );
      setState(() => currentStep = 2);
      await _fetchAvailability();
      return;
    }
    if (!mounted) return;
    final removedIds = unavailable.map((item) => item.id).toSet();
    setState(() {
      cartItems.removeWhere((item) => removedIds.contains(item.id));
      currentStep = 2;
    });
    await _fetchAvailability();
    if (!mounted) return;
    final details = unavailable
        .map((item) {
          final date = item.date;
          final start = item.timeSlots.first.toString();
          final end = _formatTime(
            _minutesFor(start) + (item.timeSlots.length as int) * 60,
          );
          return '${item.facilityName} · ${date.day} ${monthNames[date.month - 1]} ${date.year} · $start–$end';
        })
        .join('\n\n');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Selected slot is no longer available'),
        content: SingleChildScrollView(
          child: Text(
            unavailable.isEmpty
                ? 'A selected slot was booked or reserved before checkout. No payment was started. Please choose another slot.'
                : '$details\n\nThese slots are booked, reserved or unavailable and have been removed from your cart. Other cart items are kept. No payment was started.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Choose another slot'),
          ),
        ],
      ),
    );
  }

  Future<void> _reserveSelectedCart() async {
    if (_isReserving || cartItems.isEmpty || reservationCreated) return;
    if (_studentCategory == null) {
      // The server would refuse with PROFILE_CATEGORY_REQUIRED anyway.
      _showMessage(StudentCategory.notSetHelp);
      return;
    }
    setState(() => _isReserving = true);
    final key = _checkoutRequestId ??= BookingService.newCheckoutRequestId();
    try {
      if (_bookingService.usesRealPayment && _pendingBookingId != null) {
        await _resumePendingCheckout();
        return;
      }
      if (_bookingService.usesRealPayment) {
        final booking = await _bookingService.reserveCart(
          cartItems,
          requestId: key,
        );
        if (!mounted) return;
        setState(() {
          _pendingBookingId = booking['id'].toString();
          _paymentDeadline = DateTime.tryParse(
            booking['payment_deadline']?.toString() ?? '',
          );
          generatedBookingRef = booking['reference'].toString();
          _reservedTotal = booking['total_amount'] as num;
        });
        if (booking['status'] == 'confirmed') {
          setState(() {
            _paidViaBillplz = true;
            reservationCreated = true;
          });
          return;
        }
        final url = await _bookingService.createBillplzPayment(
          _pendingBookingId!,
        );
        if (!mounted) return;
        setState(() => _paymentUrl = url);
        return;
      }
      final response = await _bookingService.demoPayCart(
        cartItems,
        requestId: key,
        method: selectedPaymentMethod == 'E-Wallet'
            ? 'touch_n_go_ewallet'
            : 'fpx',
      );
      if (!mounted) return;
      if (response['status'] != 'confirmed' || response['is_demo'] != true) {
        throw StateError('Demo payment was not confirmed by the server.');
      }
      setState(() {
        generatedBookingRef = response['reference'].toString();
        _reservedTotal = response['total_amount'] as num;
        reservationCreated = true;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final conflict =
          e.code == '23505' || e.message.contains('SLOT_UNAVAILABLE');
      if (conflict) {
        _checkoutRequestId = null;
        await _removeConflictingCartItems();
      } else if (e.message.contains('HOLD_EXPIRED')) {
        _checkoutRequestId = null;
        _showMessage(
          'Your hold expired. Review availability before trying again.',
        );
        setState(() => currentStep = 2);
        await _fetchAvailability();
      } else if (e.message.contains('PRICE_CHANGED')) {
        _checkoutRequestId = null;
        await _loadPrices();
        if (!mounted) return;
        setState(() {
          cartItems.clear();
          currentStep = 1;
        });
        _showMessage(
          'Prices have changed. Rebuild your cart with the updated prices before paying.',
        );
      } else if (e.code == 'PGRST202') {
        _showMessage(
          'Checkout is not configured yet. The reviewed database script must be deployed first.',
        );
      } else if (e.message.contains('PROFILE_CATEGORY_REQUIRED')) {
        _showMessage(StudentCategory.notSetHelp);
      } else {
        _showMessage(
          'Could not reserve this cart. Check the session times and account category.',
        );
      }
    } on PaymentException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Connection interrupted. Retry Pay with the same cart to recover your reservation.',
        );
      }
    } finally {
      if (mounted) setState(() => _isReserving = false);
    }
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryGreen,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        if (!availableStartTimes.contains(selectedStartTime)) {
          selectedStartTime = availableStartTimes.first;
        }
      });
      _fetchAvailability();
    }
  }

  void _showStartTimeSelectorDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
                      _autoSelectFirstAvailableCourt();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected ? primaryGreen : Colors.white,
                      foregroundColor: isSelected ? Colors.white : primaryGreen,
                      side: BorderSide(
                        color: isSelected ? primaryGreen : subtleBorder,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      time,
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
      ),
    );
  }
}

class _PrototypeCourtPainter extends CustomPainter {
  final Color lineColor;
  final String sport;

  _PrototypeCourtPainter({required this.lineColor, required this.sport});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = size.width / 240 < size.height / 130
        ? size.width / 240
        : size.height / 130;

    canvas.save();
    canvas.translate(
      (size.width - 240 * scale) / 2,
      (size.height - 130 * scale) / 2,
    );
    canvas.scale(scale);

    final pen = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    switch (sport) {
      case 'Ping Pong':
        const pingTable = Rect.fromLTWH(35, 15, 170, 100);
        canvas.drawRRect(
          RRect.fromRectAndRadius(pingTable, const Radius.circular(4)),
          pen,
        );
        canvas.drawRect(pingTable.deflate(5), pen);
        canvas.drawLine(const Offset(40, 65), const Offset(200, 65), pen);

        canvas.drawLine(
          const Offset(120, 11),
          const Offset(120, 119),
          pen..strokeWidth = 4,
        );
        pen.strokeWidth = 1;
        for (double y = 18; y <= 112; y += 7) {
          canvas.drawLine(Offset(115, y), Offset(125, y), pen);
        }

        pen.strokeWidth = 2;
        canvas.drawOval(const Rect.fromLTWH(211, 76, 18, 24), pen);
        canvas.drawLine(
          const Offset(220, 100),
          const Offset(220, 113),
          pen..strokeWidth = 4,
        );
        canvas.drawCircle(const Offset(220, 62), 4, fill);
        break;

      case 'Snooker':
        const snookerTable = Rect.fromLTWH(22, 16, 196, 98);
        canvas.drawRRect(
          RRect.fromRectAndRadius(snookerTable, const Radius.circular(12)),
          pen..strokeWidth = 5,
        );
        pen.strokeWidth = 1.5;
        canvas.drawRect(snookerTable.deflate(8), pen);

        for (final point in const [
          Offset(29, 23),
          Offset(120, 23),
          Offset(211, 23),
          Offset(29, 107),
          Offset(120, 107),
          Offset(211, 107),
        ]) {
          canvas.drawCircle(point, 5, fill);
        }

        canvas.drawLine(const Offset(70, 24), const Offset(70, 106), pen);
        canvas.drawArc(
          const Rect.fromLTWH(49, 44, 42, 42),
          1.5707963,
          3.1415927,
          false,
          pen,
        );

        canvas.drawCircle(const Offset(56, 65), 4, fill);
        for (int row = 0; row < 5; row++) {
          for (int ball = 0; ball <= row; ball++) {
            canvas.drawCircle(
              Offset(135 + row * 8, 65 + (ball - row / 2) * 9),
              3.5,
              fill,
            );
          }
        }
        break;

      case 'Dart':
        const centre = Offset(120, 65);
        for (final radius in [55.0, 48.0, 33.0, 28.0]) {
          canvas.drawCircle(centre, radius, pen);
        }

        for (int segment = 0; segment < 20; segment++) {
          canvas.save();
          canvas.translate(centre.dx, centre.dy);
          canvas.rotate(segment * 3.141592653589793 / 10);
          canvas.drawLine(
            const Offset(0, -9),
            const Offset(0, -55),
            pen..strokeWidth = 1,
          );
          canvas.restore();
        }

        pen.strokeWidth = 2;
        canvas.drawCircle(centre, 9, pen);
        canvas.drawCircle(centre, 4, fill);
        break;

      default:
        pen
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.butt;
        const court = Rect.fromLTWH(18, 18, 204, 94);
        canvas.drawRect(court, pen);
        for (final y in [25.0, 105.0]) {
          canvas.drawLine(Offset(18, y), Offset(222, y), pen);
        }
        for (final x in [29.0, 211.0, 90.0, 150.0]) {
          canvas.drawLine(Offset(x, 18), Offset(x, 112), pen);
        }
        canvas.drawLine(const Offset(18, 65), const Offset(90, 65), pen);
        canvas.drawLine(const Offset(150, 65), const Offset(222, 65), pen);
        canvas.drawLine(
          const Offset(120, 15),
          const Offset(120, 115),
          pen..strokeWidth = 2,
        );
        canvas.drawCircle(const Offset(120, 15), 2.5, fill);
        canvas.drawCircle(const Offset(120, 115), 2.5, fill);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PrototypeCourtPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || oldDelegate.sport != sport;
  }
}

class _SportChoiceIconPainter extends CustomPainter {
  final String sport;
  final Color color;

  const _SportChoiceIconPainter({required this.sport, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 28, size.height / 28);
    final fill = Paint()..color = color;
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    if (sport == 'Ping Pong') {
      canvas.save();
      canvas.translate(12, 11);
      canvas.rotate(0.6);
      canvas.drawOval(const Rect.fromLTWH(-7, -8, 14, 16), fill);
      canvas.drawLine(
        const Offset(0, 7),
        const Offset(0, 16),
        pen..strokeWidth = 4,
      );
      canvas.restore();
      canvas.drawCircle(const Offset(23, 5), 3, pen..strokeWidth = 1.8);
    } else {
      for (final point in const [
        Offset(11, 7),
        Offset(7, 14),
        Offset(15, 14),
        Offset(3, 21),
        Offset(11, 21),
        Offset(19, 21),
      ]) {
        canvas.drawCircle(point, 3, fill);
      }
      canvas.drawLine(const Offset(18, 2), const Offset(27, 23), pen);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SportChoiceIconPainter oldDelegate) =>
      oldDelegate.sport != sport || oldDelegate.color != color;
}
