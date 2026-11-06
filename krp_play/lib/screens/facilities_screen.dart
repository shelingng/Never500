import 'package:flutter/material.dart';

import '../models/facility.dart';
import '../models/booking.dart';
import 'payment_screen.dart';
import '../services/booking_service.dart';

class FacilitiesScreen extends StatefulWidget {
  final String category;
  final String email;

  const FacilitiesScreen({
    super.key,
    required this.category,
    required this.email,
  });

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  // KRP facilities and pricing
  final List<Facility> facilities = const [
    Facility(
      name: 'Badminton Court 01',
      type: 'Badminton',
      krpPrice: 6,
      nonKrpPrice: 8,
      unit: 'court/hour',
    ),
    Facility(
      name: 'Badminton Court 02',
      type: 'Badminton',
      krpPrice: 6,
      nonKrpPrice: 8,
      unit: 'court/hour',
    ),
    Facility(
      name: 'Ping Pong Table 01',
      type: 'Ping Pong',
      krpPrice: 4,
      nonKrpPrice: 6,
      unit: 'table/hour',
    ),
    Facility(
      name: 'Ping Pong Table 02',
      type: 'Ping Pong',
      krpPrice: 4,
      nonKrpPrice: 6,
      unit: 'table/hour',
    ),
    Facility(
      name: 'Snooker Table',
      type: 'Snooker',
      krpPrice: 10,
      nonKrpPrice: 12,
      unit: 'table/hour',
    ),
    Facility(
      name: 'Dart Board',
      type: 'Dart',
      krpPrice: 3,
      nonKrpPrice: 5,
      unit: 'board/hour',
    ),
    Facility(
      name: 'KRP Gym',
      type: 'Gym',
      krpPrice: 2,
      nonKrpPrice: 4,
      unit: 'person/session',
    ),
  ];

  final List<String> filters = [
    'All',
    'Badminton',
    'Ping Pong',
    'Snooker',
    'Dart',
    'Gym',
  ];

  String selectedFilter = 'All';
  int selectedFacility = 0;
  int selectedDate = 0;
  int participants = 1;

  List<String> selectedTimes = [];

  // Weekday sessions: 5 PM - 7 PM and 8 PM - 11 PM
  final List<String> weekdays = [
    '5:00 PM',
    '6:00 PM',
    '8:00 PM',
    '9:00 PM',
    '10:00 PM',
  ];

  // Weekend sessions: 10 AM - 1 PM, 2 PM - 7 PM and 8 PM - 11 PM
  final List<String> weekends = [
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '8:00 PM',
    '9:00 PM',
    '10:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    final facility = facilities[selectedFacility];

    final price = facility.priceFor(widget.category);

    final selectedBookingDate = DateTime.now().add(
      Duration(days: selectedDate),
    );

    final isWeekend =
        selectedBookingDate.weekday == DateTime.saturday ||
        selectedBookingDate.weekday == DateTime.sunday;

    final times = isWeekend ? weekends : weekdays;

    final total =
        price *
        selectedTimes.length *
        (facility.type == 'Gym' ? participants : 1);

    final filteredFacilities = facilities
        .where((item) => selectedFilter == 'All' || item.type == selectedFilter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Facility'),
        backgroundColor: const Color(0xFF173F32),
        foregroundColor: Colors.white,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // HEADER
          const Text(
            'Choose your facility',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text('Your category: ${widget.category}'),

          const SizedBox(height: 18),

          // FACILITY FILTERS
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filters.map((filter) {
              return ChoiceChip(
                label: Text(filter),
                selected: selectedFilter == filter,

                onSelected: (_) {
                  setState(() {
                    selectedFilter = filter;
                    selectedTimes.clear();

                    selectedFacility = facilities.indexWhere(
                      (item) => filter == 'All' || item.type == filter,
                    );

                    if (selectedFacility < 0) {
                      selectedFacility = 0;
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // FACILITY CARDS
          ...filteredFacilities.map((item) {
            final index = facilities.indexOf(item);

            final active = selectedFacility == index;

            return Card(
              color: active ? const Color(0xFFE5EFE9) : Colors.white,

              child: ListTile(
                leading: const Icon(
                  Icons.sports_tennis,
                  color: Color(0xFF173F32),
                ),

                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: Text(
                  '${item.type} · RM ${item.priceFor(widget.category)}/${item.unit}',
                ),

                trailing: active
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.chevron_right),

                onTap: () {
                  setState(() {
                    selectedFacility = index;
                    selectedTimes.clear();
                  });
                },
              ),
            );
          }),

          const SizedBox(height: 25),

          // DATE SELECTION
          const Text(
            'Choose your date',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,

            children: List.generate(7, (index) {
              final date = DateTime.now().add(Duration(days: index));

              final dayName = index == 0
                  ? 'Today'
                  : [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ][date.weekday - 1];

              return ChoiceChip(
                label: Text('$dayName ${date.day}/${date.month}'),

                selected: selectedDate == index,

                onSelected: (_) {
                  setState(() {
                    selectedDate = index;
                    selectedTimes.clear();
                  });
                },
              );
            }),
          ),

          const SizedBox(height: 25),

          // TIME SELECTION
          const Text(
            'Choose your time',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          const Text('Each selected session is one hour.'),

          const SizedBox(height: 5),

          const Text(
            'Maximum booking duration: 2 consecutive hours.',
            style: TextStyle(
              color: Color(0xFF173F32),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,

            children: times.map((time) {
              final selected = selectedTimes.contains(time);

              return FilterChip(
                label: Text(time),
                selected: selected,

                onSelected: (_) {
                  setState(() {
                    // Remove selected time
                    if (selected) {
                      selectedTimes.remove(time);
                      return;
                    }

                    // Maximum two sessions
                    if (selectedTimes.length >= 2) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Maximum booking duration is 2 hours.'),
                        ),
                      );

                      return;
                    }

                    // Sort selected sessions
                    final newSelection = [...selectedTimes, time]
                      ..sort(
                        (a, b) => times.indexOf(a).compareTo(times.indexOf(b)),
                      );

                    final indexes = newSelection
                        .map((item) => times.indexOf(item))
                        .toList();

                    // Ensure consecutive sessions
                    final consecutive =
                        indexes.length == 1 ||
                        indexes.last - indexes.first == 1;

                    if (consecutive) {
                      selectedTimes = newSelection;
                    } else {
                      selectedTimes = [time];
                    }
                  });
                },
              );
            }).toList(),
          ),

          // GYM PARTICIPANTS
          if (facility.type == 'Gym') ...[
            const SizedBox(height: 20),

            const Text(
              'Number of participants',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            DropdownButton<int>(
              value: participants,

              items: List.generate(10, (index) => index + 1)
                  .map(
                    (number) => DropdownMenuItem(
                      value: number,
                      child: Text('$number participant(s)'),
                    ),
                  )
                  .toList(),

              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    participants = value;
                  });
                }
              },
            ),
          ],

          const SizedBox(height: 25),

          // BOOKING SUMMARY
          Card(
            color: const Color(0xFFE5EFE9),

            child: Padding(
              padding: const EdgeInsets.all(18),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Booking summary',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Text('Facility: ${facility.name}'),

                  Text('Category: ${widget.category}'),

                  Text(
                    'Date: ${selectedBookingDate.day}/${selectedBookingDate.month}/${selectedBookingDate.year}',
                  ),

                  Text('Sessions: ${selectedTimes.length}'),

                  if (selectedTimes.isNotEmpty)
                    Text('Time: ${selectedTimes.join(' - ')}'),

                  Text('Price per session: RM $price'),

                  if (facility.type == 'Gym')
                    Text('Participants: $participants'),

                  const Divider(),

                  Text(
                    'Total: RM $total.00',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF173F32),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ADD TO ORDER
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF173F32),
              minimumSize: const Size.fromHeight(52),
            ),

            onPressed: selectedTimes.isEmpty
                ? null
                : () {
                    final booking = Booking(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),

                      userEmail: widget.email,

                      facilityName: facility.name,

                      date: selectedBookingDate,

                      timeSlots: List<String>.from(selectedTimes),

                      pricePerSession: price,

                      participants: facility.type == 'Gym' ? participants : 1,

                      totalPrice: total,
                    );

                    final success = BookingService().addBooking(booking);

                    if (success) {
                      setState(() {
                        selectedTimes.clear();
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(booking: booking),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'One or more selected slots are already booked.',
                          ),
                        ),
                      );
                    }
                  },

            child: const Text('Add to order'),
          ),

          const SizedBox(height: 20),

          const Text(
            'Availability is subject to KRP Management approval and operational arrangements.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
