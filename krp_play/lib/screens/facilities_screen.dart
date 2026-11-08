import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/facility.dart';
import '../models/facility_catalog.dart';
import '../services/booking_service.dart';
import 'payment_screen.dart';

const _primaryGreen = Color(0xFF173F32);
const _paleGreen = Color(0xFFE5EFE9);
const _mutedText = Color(0xFF68756E);

class FacilitiesScreen extends StatefulWidget {
  final String category;
  final String email;
  final VoidCallback? onBookingPaid;

  const FacilitiesScreen({
    super.key,
    required this.category,
    required this.email,
    this.onBookingPaid,
  });

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  static const filters = [
    'All',
    'Badminton',
    'Ping Pong',
    'Snooker',
    'Dart',
  ];

  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final visibleFacilities = krpFacilities
        .where(
          (facility) =>
              _selectedFilter == 'All' || facility.type == _selectedFilter,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text(
          'Available courts',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: _primaryGreen, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        const Text(
          'Choose a facility to view dates and available times.',
          style: TextStyle(color: _mutedText),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final selected = _selectedFilter == filter;
              return ChoiceChip(
                label: Text(filter),
                selected: selected,
                showCheckmark: false,
                selectedColor: _primaryGreen,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected ? _primaryGreen : const Color(0xFFE0E7E2),
                ),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _selectedFilter = filter),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        ...visibleFacilities.map(
          (facility) => _FacilityCard(
            facility: facility,
            category: widget.category,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => FacilityBookingScreen(
                  facility: facility,
                  category: widget.category,
                  email: widget.email,
                  onBookingPaid: widget.onBookingPaid,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final Facility facility;
  final String category;
  final VoidCallback onTap;

  const _FacilityCard({
    required this.facility,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final code = facilityCode(facility);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _paleGreen,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    color: _primaryGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: _mutedText,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'KRP Sports Hall',
                          style: TextStyle(color: _mutedText, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${facility.priceFor(category)}',
                    style: const TextStyle(
                      color: _primaryGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '/${facility.unit}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: _mutedText,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FacilityBookingScreen extends StatefulWidget {
  final Facility facility;
  final String category;
  final String email;
  final VoidCallback? onBookingPaid;

  const FacilityBookingScreen({
    super.key,
    required this.facility,
    required this.category,
    required this.email,
    this.onBookingPaid,
  });

  @override
  State<FacilityBookingScreen> createState() => _FacilityBookingScreenState();
}

class _FacilityBookingScreenState extends State<FacilityBookingScreen> {
  int _selectedDate = 1;
  final Set<String> _selectedTimes = {};

  DateTime get _bookingDate =>
      DateUtils.dateOnly(DateTime.now().add(Duration(days: _selectedDate)));

  List<String> get _times => sessionsForDate(_bookingDate);

  int get _price => widget.facility.priceFor(widget.category);

  int get _total =>
      _price * _selectedTimes.length;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_bookingDate.day}/${_bookingDate.month}/${_bookingDate.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: Text(widget.facility.name),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1D8),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'STEP 2',
                  style: TextStyle(
                    color: _primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Choose date & time',
                  style: TextStyle(
                    color: _primaryGreen,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.calendar_month_outlined, size: 15),
              const SizedBox(width: 4),
              const Text(
                '7-day advance booking',
                style: TextStyle(color: _mutedText, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 8,
              separatorBuilder: (context, index) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final date = DateUtils.dateOnly(
                  DateTime.now().add(Duration(days: index)),
                );
                final selected = _selectedDate == index;
                final isToday = index == 0;
                final weekday = [
                  'MON',
                  'TUE',
                  'WED',
                  'THU',
                  'FRI',
                  'SAT',
                  'SUN',
                ][date.weekday - 1];
                return SizedBox(
                  height: 84,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: InkWell(
                      key: ValueKey('booking-date-$index'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: isToday
                          ? null
                          : () {
                              setState(() {
                                _selectedDate = index;
                                _selectedTimes.clear();
                              });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 54,
                        height: selected ? 84 : 76,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? _primaryGreen
                              : isToday
                              ? const Color(0xFFE9ECEA)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? _primaryGreen
                                : const Color(0xFFE3E9E5),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              index == 0 ? 'TODAY' : weekday,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFFB7E28A)
                                    : isToday
                                    ? const Color(0xFFA0A8A3)
                                    : _mutedText,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : isToday
                                    ? const Color(0xFFA0A8A3)
                                    : _primaryGreen,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _monthName(date.month),
                              style: TextStyle(
                                color: selected
                                    ? Colors.white70
                                    : isToday
                                    ? const Color(0xFFA0A8A3)
                                    : _mutedText,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _bookingDate.weekday == DateTime.saturday ||
                        _bookingDate.weekday == DateTime.sunday
                    ? 'WEEKEND SESSIONS'
                    : 'WEEKDAY SESSIONS',
                style: const TextStyle(
                  color: _primaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .6,
                ),
              ),
              const Text(
                'One-hour slots',
                style: TextStyle(color: _mutedText, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _times.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 64,
            ),
            itemBuilder: (context, index) {
              final time = _times[index];
              final available = BookingService().isSlotAvailable(
                facilityName: widget.facility.name,
                date: _bookingDate,
                time: time,
              );
              final selected = _selectedTimes.contains(time);
              return _TimeSlotCard(
                time: time,
                available: available,
                selected: selected,
                onTap: available ? () => _toggleTime(time) : null,
              );
            },
          ),
          if (_selectedTimes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking summary',
                      style: TextStyle(
                        color: _primaryGreen,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text('Date: $dateLabel'),
                    Text('Time: ${_times.where(_selectedTimes.contains).join(', ')}'),
                    Text('Price per session: RM $_price'),
                    const Divider(height: 22),
                    Text(
                      'Total: RM $_total.00',
                      style: const TextStyle(
                        color: _primaryGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _selectedTimes.isEmpty ? null : _submitBooking,
            style: FilledButton.styleFrom(
              backgroundColor: _primaryGreen,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text('Continue to payment'),
          ),
        ],
      ),
    );
  }

  void _toggleTime(String time) {
    setState(() {
      if (_selectedTimes.contains(time)) {
        _selectedTimes.remove(time);
        return;
      }
      if (_selectedTimes.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum booking duration is 2 hours.')),
        );
        return;
      }
      if (_selectedTimes.isNotEmpty &&
          (_minutesFor(time) - _minutesFor(_selectedTimes.first)).abs() != 60) {
        _selectedTimes
          ..clear()
          ..add(time);
        return;
      }
      _selectedTimes.add(time);
    });
  }

  void _submitBooking() {
    final sortedTimes = _times.where(_selectedTimes.contains).toList();
    final booking = Booking(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userEmail: widget.email,
      facilityName: widget.facility.name,
      date: _bookingDate,
      timeSlots: sortedTimes,
      pricePerSession: _price,
      totalPrice: _total,
    );

    if (!BookingService().addBooking(booking)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The selected slot is no longer available.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PaymentScreen(
          booking: booking,
          onPaymentComplete: widget.onBookingPaid,
        ),
      ),
    );
  }

  int _minutesFor(String time) {
    final parts = time.split(' ');
    final clock = parts.first.split(':');
    var hour = int.parse(clock[0]);
    final minute = int.parse(clock[1]);
    final isPm = parts.last == 'PM';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  String _monthName(int month) => const [
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
  ][month - 1];
}

class _TimeSlotCard extends StatelessWidget {
  final String time;
  final bool available;
  final bool selected;
  final VoidCallback? onTap;

  const _TimeSlotCard({
    required this.time,
    required this.available,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = available ? _primaryGreen : const Color(0xFF9AA39D);
    return Card(
      margin: EdgeInsets.zero,
      color: available ? Colors.white : const Color(0xFFE9ECEA),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? _primaryGreen : const Color(0xFFDCE4DF),
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle
                    : available
                    ? Icons.access_time_rounded
                    : Icons.block_rounded,
                color: foreground,
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      available ? 'Available' : 'Booked',
                      style: TextStyle(
                        color: available
                            ? const Color(0xFF4F8B50)
                            : const Color(0xFF89928C),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
