import 'package:flutter/material.dart';

class AdminSlotsTab extends StatefulWidget {
  const AdminSlotsTab({super.key});

  @override
  State<AdminSlotsTab> createState() => _AdminSlotsTabState();
}

class _AdminSlotsTabState extends State<AdminSlotsTab> {
  String _selectedFacility = 'Badminton Court 01';
  String _selectedReason = 'Maintenance';
  
  int _selectedDateIndex = 3; // Default to SAT 14 Nov to match screenshot

  // 1. Generate 7 clickable days matching the screenshots
  final List _dates = [
    {'day': 'WED', 'date': '11', 'month': 'Nov', 'isWeekend': false},
    {'day': 'THU', 'date': '12', 'month': 'Nov', 'isWeekend': false},
    {'day': 'FRI', 'date': '13', 'month': 'Nov', 'isWeekend': false},
    {'day': 'SAT', 'date': '14', 'month': 'Nov', 'isWeekend': true},
    {'day': 'SUN', 'date': '15', 'month': 'Nov', 'isWeekend': true},
    {'day': 'MON', 'date': '16', 'month': 'Nov', 'isWeekend': false},
    {'day': 'TUE', 'date': '17', 'month': 'Nov', 'isWeekend': false},
  ];

  // 2. Facilities data mapped directly from the KRP Poster
  final List<String> _facilitiesList = [
    'Badminton Court 01', 'Badminton Court 02', 
    'Ping Pong Table 01', 'Ping Pong Table 02',
    'Snooker Table', 'Dart Board', 'Gym'
  ];

  Map<String, String> _getFacilityDetails(String facility) {
    if (facility.contains('Badminton')) return {'code': 'B01', 'price': 'RM 6 KRP · RM 8 non-KRP'};
    if (facility.contains('Ping Pong')) return {'code': 'P01', 'price': 'RM 4 KRP · RM 6 non-KRP'};
    if (facility.contains('Snooker')) return {'code': 'S01', 'price': 'RM 10 KRP · RM 12 non-KRP'};
    if (facility.contains('Dart')) return {'code': 'D01', 'price': 'RM 3 KRP · RM 5 non-KRP'};
    if (facility.contains('Gym')) return {'code': 'G01', 'price': 'RM 2 KRP · RM 4 non-KRP'};
    return {'code': 'F01', 'price': 'RM 0'};
  }

  // 3. Dynamic Slots based on Weekday/Weekend logic from the poster
  final List<String> _weekdaySlots = ['5:00 PM', '6:00 PM', '8:00 PM', '9:00 PM', '10:00 PM']; // 7PM break excluded
  final List<String> _weekendSlots = ['10:00 AM', '11:00 AM', '12:00 PM', '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM', '6:00 PM', '8:00 PM', '9:00 PM', '10:00 PM']; // 1PM & 7PM breaks excluded

  // State map to track whether a slot is 'Open', 'Closed', or 'Reserved'
  Map<String, String> _slotStatus = {};

  @override
  void initState() {
    super.initState();
    _generateSlotsForSelectedDay();
  }

  void _generateSlotsForSelectedDay() {
    bool isWeekend = _dates[_selectedDateIndex]['isWeekend'];
    List<String> currentSlots = isWeekend ? _weekendSlots : _weekdaySlots;
    
    _slotStatus.clear();
    for (int i = 0; i < currentSlots.length; i++) {
      // Simulate some slots being reserved for realistic UI testing
      if (i == 2 || (isWeekend && i == 5)) {
        _slotStatus[currentSlots[i]] = 'Reserved';
      } else {
        _slotStatus[currentSlots[i]] = 'Open';
      }
    }
  }

  // 4. Close all slots functionality
  void _closeAllSlots() {
    setState(() {
      _slotStatus.forEach((key, value) {
        if (value == 'Open') {
          _slotStatus[key] = 'Closed by admin';
        }
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All open slots have been closed.')));
  }

  @override
  Widget build(BuildContext context) {
    bool isWeekend = _dates[_selectedDateIndex]['isWeekend'];
    List<String> activeSlots = isWeekend ? _weekendSlots : _weekdaySlots;
    var facilityInfo = _getFacilityDetails(_selectedFacility);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('— AVAILABILITY CONTROL', style: TextStyle(color: Color(0xFF173F32), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Manage slots', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0D211A))),
          const SizedBox(height: 8),
          const Text('Bookings update here in real time. Saved closures are reflected to students instantly.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF173F32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Availability Saved!')));
            },
            child: const Text('Availability saved', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Interactive Horizontal Date Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_dates.length, (index) {
                      return _buildDateBox(
                        _dates[index]['day'], 
                        _dates[index]['date'], 
                        _dates[index]['month'], 
                        _selectedDateIndex == index,
                        () {
                          setState(() {
                            _selectedDateIndex = index;
                            _generateSlotsForSelectedDay(); // Regenerate times based on day
                          });
                        }
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // Facility Dropdown
                const Text('Facility', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _selectedFacility,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: _facilitiesList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedFacility = val!);
                  },
                ),
                const SizedBox(height: 16),

                // Updated Closure Reasons
                const Text('Closure reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _selectedReason,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: ['Maintenance', 'College event', 'Safety inspection', 'Operational requirement']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedReason = val!),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Color(0xFFE65100), size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Paid reservations are protected and cannot be closed from this control.', style: TextStyle(fontSize: 12, color: Color(0xFFE65100)))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Legend & Close All Slots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildLegend(Colors.green, 'Open'),
                        const SizedBox(width: 12),
                        _buildLegend(Colors.redAccent, 'Closed by admin'),
                        const SizedBox(width: 12),
                        _buildLegend(Colors.grey.shade400, 'Reserved'),
                      ],
                    ),
                    InkWell(
                      onTap: _closeAllSlots,
                      child: const Text('Close all slots', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Interactive Slots Table
                Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fixed First Column (Facility Info)
                        Container(
                          width: 200,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(right: BorderSide(color: Colors.grey.shade300))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('FACILITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8), 
                                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)), 
                                    child: Text(facilityInfo['code']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, 
                                      children: [
                                        Text(_selectedFacility, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), 
                                        Text(facilityInfo['price']!, style: const TextStyle(fontSize: 10, color: Colors.grey))
                                      ]
                                    )
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        // Dynamic Scrollable Time Columns
                        ...activeSlots.map((time) {
                          String status = _slotStatus[time] ?? 'Open';
                          return _buildSlotCell(time, status, (bool switchValue) {
                            setState(() {
                              _slotStatus[time] = switchValue ? 'Open' : 'Closed by admin';
                            });
                          });
                        }).toList(),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDateBox(String day, String date, String month, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF173F32) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? const Color(0xFF173F32) : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(day, style: TextStyle(fontSize: 10, color: isActive ? Colors.greenAccent : Colors.grey)),
            Text(date, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.black)),
            Text(month, style: TextStyle(fontSize: 12, color: isActive ? Colors.white : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: color, width: 2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildSlotCell(String time, String status, ValueChanged<bool> onChanged) {
    bool isReserved = status == 'Reserved';
    bool isOpen = status == 'Open';

    return Container(
      width: 110, // Fixed width to allow smooth horizontal scrolling
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isReserved ? Colors.grey.shade100 : Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300))
      ),
      child: Column(
        children: [
          Text(time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          Text(
            status, 
            style: TextStyle(
              fontSize: 12, 
              color: isReserved ? Colors.grey : (isOpen ? Colors.green : Colors.redAccent),
              fontWeight: FontWeight.w600
            )
          ),
          Switch(
            value: isOpen || isReserved, 
            onChanged: isReserved ? null : onChanged, 
            activeColor: isReserved ? Colors.grey.shade300 : Colors.green,
            inactiveTrackColor: Colors.redAccent.withOpacity(0.3),
            inactiveThumbColor: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}