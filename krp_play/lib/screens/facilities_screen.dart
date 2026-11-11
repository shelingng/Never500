import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'booking_confirm_screen.dart';

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

enum CourtStatus { available, booked, locked }

class FacilitiesScreenStateModel {
  final String name;
  final CourtStatus status;
  final String note;

  const FacilitiesScreenStateModel({
    required this.name,
    required this.status,
    required this.note,
  });
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  final Color primaryGreen = const Color(0xFF103B2B);
  final Color accentLime = const Color(0xFFD2F865);
  final Color subtleBorder = const Color(0xFFE9EFEA);

  String selectedSport = 'Badminton';
  final List<String> sports = ['Badminton', 'Ping Pong', 'Snooker', 'Dart', 'Gym'];

  int selectedDateIndex = 0;
  String selectedTime = '7:00';
  String selectedPeriod = 'PM';
  int selectedDurationHours = 2; // Default 2 hours matching wireframe

  String? selectedCourtName = 'Court 1'; // Selected court

  final List<String> availableHours = [
    '5:00',
    '5:30',
    '6:00',
    '6:30',
    '7:00',
    '7:30',
    '8:00',
    '8:30',
    '9:00',
    '9:30',
    '10:00',
  ];

  DateTime get selectedDate =>
      DateTime.now().add(Duration(days: selectedDateIndex));

  String get startTimeFormatted => '$selectedTime $selectedPeriod';

  List<String> get generatedTimeSlots {
    final slots = <String>[];
    try {
      final startMin = BookingService.minutesFor(startTimeFormatted);
      for (int i = 0; i < selectedDurationHours; i++) {
        final currentMin = startMin + (i * 60);
        final hour24 = (currentMin ~/ 60) % 24;
        final minute = currentMin % 60;
        final period = hour24 >= 12 ? 'PM' : 'AM';
        final hour12 = hour24 == 0
            ? 12
            : (hour24 > 12 ? hour24 - 12 : hour24);
        final minStr = minute < 10 ? '0$minute' : '$minute';
        slots.add('$hour12:$minStr $period');
      }
    } catch (_) {
      slots.add(startTimeFormatted);
    }
    return slots;
  }

  int get pricePerHour {
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
        case 'Gym':
          return 2;
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
        case 'Gym':
          return 4;
        default:
          return 8;
      }
    }
  }

  int get totalPrice => pricePerHour * selectedDurationHours;

  List<FacilitiesScreenStateModel> get currentCourts {
    final targetDate = selectedDate;
    final slots = generatedTimeSlots;

    if (selectedSport == 'Badminton') {
      return [
        _evaluateCourt('Court 1', 'Badminton Court 01', targetDate, slots),
        _evaluateCourt('Court 2', 'Badminton Court 02', targetDate, slots),
        const FacilitiesScreenStateModel(
          name: 'Court 3',
          status: CourtStatus.locked,
          note: 'Locked for specific event',
        ),
      ];
    } else if (selectedSport == 'Ping Pong') {
      return [
        _evaluateCourt('Table 1', 'Ping Pong Table 01', targetDate, slots),
        _evaluateCourt('Table 2', 'Ping Pong Table 02', targetDate, slots),
        const FacilitiesScreenStateModel(
          name: 'Table 3',
          status: CourtStatus.locked,
          note: 'Locked for specific event',
        ),
      ];
    } else if (selectedSport == 'Snooker') {
      return [
        _evaluateCourt('Table 1', 'Snooker Table', targetDate, slots),
      ];
    } else if (selectedSport == 'Dart') {
      return [
        _evaluateCourt('Board 1', 'Dart Board', targetDate, slots),
      ];
    } else {
      return [
        _evaluateCourt('Gym Session', 'KRP Gym', targetDate, slots),
      ];
    }
  }

  FacilitiesScreenStateModel _evaluateCourt(
    String displayName,
    String facilityFullName,
    DateTime date,
    List<String> slots,
  ) {
    if (BookingService.instance.isFacilityLocked(facilityFullName)) {
      return FacilitiesScreenStateModel(
        name: displayName,
        status: CourtStatus.locked,
        note: BookingService.instance.getLockReason(facilityFullName),
      );
    }

    final isAvailable = BookingService.instance.areAllSlotsAvailable(
      facilityName: facilityFullName,
      date: date,
      timeSlots: slots,
    );

    if (isAvailable) {
      return FacilitiesScreenStateModel(
        name: displayName,
        status: CourtStatus.available,
        note: 'can be book',
      );
    } else {
      return FacilitiesScreenStateModel(
        name: displayName,
        status: CourtStatus.booked,
        note: 'booked by other player',
      );
    }
  }

  String get facilityFullNameForSelection {
    if (selectedSport == 'Badminton') {
      if (selectedCourtName == 'Court 2') return 'Badminton Court 02';
      return 'Badminton Court 01';
    } else if (selectedSport == 'Ping Pong') {
      if (selectedCourtName == 'Table 2') return 'Ping Pong Table 02';
      return 'Ping Pong Table 01';
    } else if (selectedSport == 'Snooker') {
      return 'Snooker Table';
    } else if (selectedSport == 'Dart') {
      return 'Dart Board';
    } else {
      return 'KRP Gym';
    }
  }

  @override
  Widget build(BuildContext context) {
    final courts = currentCourts;

    // Reset selection if current selected court is not available
    final selectedCourtModel = courts.firstWhere(
      (c) => c.name == selectedCourtName,
      orElse: () => courts.first,
    );

    final canProceed = selectedCourtModel.status == CourtStatus.available;

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
          'Book Facility',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              // BOX 1: USER & SPORT SELECTION
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: subtleBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Welcome, ${widget.email.split('@').first}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F6C8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Choose your sport',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: sports.map((sport) {
                          final isSelected = selectedSport == sport;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(sport),
                              selected: isSelected,
                              selectedColor: primaryGreen,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                              side: BorderSide(
                                color: isSelected ? primaryGreen : const Color(0xFFD2DCD4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              onSelected: (_) {
                                setState(() {
                                  selectedSport = sport;
                                  selectedCourtName = sport == 'Badminton' ? 'Court 1' : 'Table 1';
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // BOX 2: SPORT COURT LAYOUT
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: subtleBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Layout title matching wireframe
                    Text(
                      '$selectedSport Court Layout',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date Selector
                    const Text(
                      'Select Date',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(7, (index) {
                          final date = DateTime.now().add(Duration(days: index));
                          final isSelected = selectedDateIndex == index;
                          final dayLabel = index == 0
                              ? 'Today'
                              : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedDateIndex = index;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryGreen : const Color(0xFFF7F9F7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? primaryGreen : subtleBorder,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      dayLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${date.day}/${date.month}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Time Selection Controls with dropdowns (wireframe: [ 7.00 v ] [ a.m. v ] [ 2 v ] hours)
                    Row(
                      children: [
                        const Text(
                          'Select time : ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '(:00 or :30 only)',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Hour dropdown [ 7:00 v ]
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: subtleBorder),
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFFF9FAF9),
                          ),
                          child: DropdownButton<String>(
                            value: selectedTime,
                            underline: const SizedBox(),
                            items: availableHours.map((h) {
                              return DropdownMenuItem(value: h, child: Text(h));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => selectedTime = val);
                              }
                            },
                          ),
                        ),

                        // Period dropdown [ PM v ]
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: subtleBorder),
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFFF9FAF9),
                          ),
                          child: DropdownButton<String>(
                            value: selectedPeriod,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'PM', child: Text('p.m.')),
                              DropdownMenuItem(value: 'AM', child: Text('a.m.')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => selectedPeriod = val);
                              }
                            },
                          ),
                        ),

                        // Duration dropdown [ 2 v ] hours
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: subtleBorder),
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFFF9FAF9),
                          ),
                          child: DropdownButton<int>(
                            value: selectedDurationHours,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('1 hr')),
                              DropdownMenuItem(value: 2, child: Text('2 hrs')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => selectedDurationHours = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // STATUS LEGEND
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _legendItem('Can be book', const Color(0xFF2E7D32)),
                        _legendItem('Booked', const Color(0xFFD32F2F)),
                        _legendItem('Locked (Event)', const Color(0xFF757575)),
                      ],
                    ),

                    const Divider(height: 28),

                    // VISUAL COURTS LAYOUT (Matching wireframe!)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: courts.map((court) {
                          final isSelected = selectedCourtName == court.name &&
                              court.status == CourtStatus.available;

                          return Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: _buildCourtVisualCard(court, isSelected),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // STICKY BOTTOM BAR ("Proceed to Confirm")
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$selectedSport · $selectedCourtName',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '$startTimeFormatted · $selectedDurationHours hr(s) · RM $totalPrice.00',
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canProceed ? primaryGreen : Colors.grey,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: canProceed
                          ? () {
                              final booking = Booking(
                                id: DateTime.now().microsecondsSinceEpoch.toString(),
                                userEmail: widget.email,
                                facilityName: facilityFullNameForSelection,
                                date: selectedDate,
                                timeSlots: generatedTimeSlots,
                                pricePerSession: pricePerHour,
                                participants: 1,
                                totalPrice: totalPrice,
                                status: 'Pending',
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingConfirmScreen(
                                    booking: booking,
                                    studentName: widget.email.split('@').first,
                                    category: widget.category,
                                  ),
                                ),
                              ).then((_) {
                                // Refresh court availability state after returning
                                setState(() {});
                              });
                            }
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Confirm',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                              size: 16, color: accentLime),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // COURT VISUAL CARD
  Widget _buildCourtVisualCard(FacilitiesScreenStateModel court, bool isSelected) {
    Color cardBorder;
    Color courtSurfaceColor;
    Color statusColor;
    IconData statusIcon;

    switch (court.status) {
      case CourtStatus.available:
        cardBorder = isSelected ? primaryGreen : const Color(0xFF2E7D32);
        courtSurfaceColor = const Color(0xFF1B5E44);
        statusColor = const Color(0xFF2E7D32);
        statusIcon = isSelected ? Icons.check_circle : Icons.radio_button_unchecked;
        break;
      case CourtStatus.booked:
        cardBorder = const Color(0xFFD32F2F);
        courtSurfaceColor = const Color(0xFFC62828);
        statusColor = const Color(0xFFD32F2F);
        statusIcon = Icons.cancel_outlined;
        break;
      case CourtStatus.locked:
        cardBorder = const Color(0xFF757575);
        courtSurfaceColor = const Color(0xFF616161);
        statusColor = const Color(0xFF757575);
        statusIcon = Icons.lock_outline;
        break;
    }

    return InkWell(
      onTap: court.status == CourtStatus.available
          ? () {
              setState(() {
                selectedCourtName = court.name;
              });
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${court.name} is ${court.note}. Please pick another court.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryGreen : cardBorder.withValues(alpha: 0.4),
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Radio / Selection row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  court.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: statusColor,
                  ),
                ),
                Icon(statusIcon, color: statusColor, size: 20),
              ],
            ),

            const SizedBox(height: 10),

            // Visual Court Graphic (Drawn dynamically!)
            Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                color: courtSurfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(140, 140),
                    painter: _getCourtPainter(selectedSport),
                  ),
                  if (court.status == CourtStatus.locked)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, color: Colors.white, size: 24),
                    ),
                  if (court.status == CourtStatus.booked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'BOOKED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Wireframe caption with arrow hint
            Container(
              height: 38,
              alignment: Alignment.center,
              child: Text(
                court.note,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomPainter _getCourtPainter(String sport) {
    switch (sport) {
      case 'Badminton':
        return _BadmintonCourtGridPainter();
      case 'Ping Pong':
        return _TableTennisTablePainter();
      case 'Snooker':
        return _SnookerTablePainter();
      default:
        return _BadmintonCourtGridPainter();
    }
  }
}

// 1. Badminton Court Painter
class _BadmintonCourtGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final netPaint = Paint()
      ..color = const Color(0xFFD2F865)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Court Outer Boundary
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRect(rect, linePaint);

    // Singles Sidelines (horizontal margins)
    canvas.drawLine(Offset(rect.left + 10, rect.top), Offset(rect.left + 10, rect.bottom), linePaint);
    canvas.drawLine(Offset(rect.right - 10, rect.top), Offset(rect.right - 10, rect.bottom), linePaint);

    // Net across middle (horizontal center)
    final midY = rect.top + rect.height / 2;
    canvas.drawLine(Offset(rect.left - 4, midY), Offset(rect.right + 4, midY), netPaint);

    // Short service lines (above and below net)
    canvas.drawLine(Offset(rect.left, midY - 20), Offset(rect.right, midY - 20), linePaint);
    canvas.drawLine(Offset(rect.left, midY + 20), Offset(rect.right, midY + 20), linePaint);

    // Long service lines for doubles (near top and bottom ends)
    canvas.drawLine(Offset(rect.left, rect.top + 8), Offset(rect.right, rect.top + 8), linePaint);
    canvas.drawLine(Offset(rect.left, rect.bottom - 8), Offset(rect.right, rect.bottom - 8), linePaint);

    // Center dividing lines (from short service line to back line)
    final midX = rect.left + rect.width / 2;
    canvas.drawLine(Offset(midX, rect.top), Offset(midX, midY - 20), linePaint);
    canvas.drawLine(Offset(midX, midY + 20), Offset(midX, rect.bottom), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. Table Tennis Table Painter
class _TableTennisTablePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final netPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final rect = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    canvas.drawRect(rect, linePaint);

    // Middle Net
    final midY = rect.top + rect.height / 2;
    canvas.drawLine(Offset(rect.left - 4, midY), Offset(rect.right + 4, midY), netPaint);

    // Center dividing line (vertical)
    final midX = rect.left + rect.width / 2;
    canvas.drawLine(Offset(midX, rect.top), Offset(midX, rect.bottom), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. Snooker Table Painter
class _SnookerTablePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final pocketPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(14, 14, size.width - 28, size.height - 28);
    canvas.drawRect(rect, linePaint);

    // 6 Pockets
    canvas.drawCircle(Offset(rect.left, rect.top), 5, pocketPaint);
    canvas.drawCircle(Offset(rect.right, rect.top), 5, pocketPaint);
    canvas.drawCircle(Offset(rect.left, rect.bottom), 5, pocketPaint);
    canvas.drawCircle(Offset(rect.right, rect.bottom), 5, pocketPaint);
    canvas.drawCircle(Offset(rect.left, rect.top + rect.height / 2), 5, pocketPaint);
    canvas.drawCircle(Offset(rect.right, rect.top + rect.height / 2), 5, pocketPaint);

    // Baulk line
    final baulkY = rect.top + rect.height * 0.25;
    canvas.drawLine(Offset(rect.left, baulkY), Offset(rect.right, baulkY), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
