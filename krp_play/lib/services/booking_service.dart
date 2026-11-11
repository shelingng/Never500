import '../models/booking.dart';

class BookingService {
  static final BookingService instance = BookingService._internal();

  factory BookingService() => instance;

  final List<Booking> _bookings = [];
  final Set<String> _lockedFacilities = {'Badminton Court 03', 'Ping Pong Table 03'};

  BookingService._internal() {
    // Seed initial sample booking to reflect active reservation
    final now = DateTime.now();
    _bookings.add(
      Booking(
        id: 'BKG-2026-001',
        userEmail: 'student@student.utm.my',
        facilityName: 'Badminton Court 02',
        date: DateTime(now.year, now.month, now.day),
        timeSlots: const ['7:00 PM', '8:00 PM'],
        pricePerSession: 6,
        participants: 1,
        totalPrice: 12,
        status: 'Confirmed',
      ),
    );
  }

  // Return all bookings without allowing external modification.
  List<Booking> get bookings => List.unmodifiable(_bookings);

  // Check if facility is locked for events/maintenance
  bool isFacilityLocked(String facilityName) {
    return _lockedFacilities.contains(facilityName);
  }

  String getLockReason(String facilityName) {
    if (facilityName.contains('Badminton')) {
      return 'Locked for KRP Inter-College Tournament';
    }
    return 'Locked for collegiate event';
  }

  // Check if multiple slots are all available
  bool areAllSlotsAvailable({
    required String facilityName,
    required DateTime date,
    required List<String> timeSlots,
  }) {
    if (isFacilityLocked(facilityName)) return false;
    return timeSlots.every((slot) => isSlotAvailable(
          facilityName: facilityName,
          date: date,
          time: slot,
        ));
  }

  // Total available slots count for a specific date across standard facilities
  int getAvailableSlotsCount(DateTime date) {
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final slotsPerFacility = isWeekend ? 11 : 5;
    const totalFacilities = 7;
    final totalSlotsPossible = totalFacilities * slotsPerFacility;

    int bookedSlotsCount = 0;
    for (final booking in _bookings) {
      if (booking.status != 'Cancelled' &&
          booking.status != 'Rejected' &&
          booking.date.year == date.year &&
          booking.date.month == date.month &&
          booking.date.day == date.day) {
        bookedSlotsCount += booking.timeSlots.length;
      }
    }

    final available = totalSlotsPossible - bookedSlotsCount;
    return available < 0 ? 0 : available;
  }

  // Convert a time such as "5:00 PM" into minutes after midnight.
  static int minutesFor(String time) {
    final parts = time.split(' ');

    if (parts.length != 2) {
      throw FormatException('Invalid time format: $time');
    }

    final clock = parts[0].split(':');

    if (clock.length != 2) {
      throw FormatException('Invalid time format: $time');
    }

    var hour = int.parse(clock[0]);
    final minute = int.parse(clock[1]);
    final period = parts[1].toUpperCase();

    if (period != 'AM' && period != 'PM') {
      throw FormatException('Invalid time period: $time');
    }

    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
      throw FormatException('Invalid time: $time');
    }

    if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return hour * 60 + minute;
  }

  // Check whether two time slots are consecutive (exactly 60 minutes apart).
  static bool areConsecutive(String time1, String time2) {
    try {
      final first = minutesFor(time1);
      final second = minutesFor(time2);
      return (first - second).abs() == 60;
    } catch (_) {
      return false;
    }
  }

  // Check whether the selected sessions follow booking rules.
  bool _hasValidDuration(List<String> timeSlots) {
    if (timeSlots.isEmpty || timeSlots.length > 2) {
      return false;
    }

    if (timeSlots.toSet().length != timeSlots.length) {
      return false;
    }

    if (timeSlots.length == 1) {
      return true;
    }

    return areConsecutive(timeSlots[0], timeSlots[1]);
  }

  // Check whether a particular facility time slot is available.
  bool isSlotAvailable({
    required String facilityName,
    required DateTime date,
    required String time,
  }) {
    return !_bookings.any((booking) {
      final sameFacility = booking.facilityName == facilityName;

      final sameDate =
          booking.date.year == date.year &&
          booking.date.month == date.month &&
          booking.date.day == date.day;

      final sameTime = booking.timeSlots.contains(time);

      final activeBooking =
          booking.status != 'Cancelled' && booking.status != 'Rejected';

      return sameFacility && sameDate && sameTime && activeBooking;
    });
  }

  // Add a booking after checking all booking rules.
  bool addBooking(Booking booking) {
    // Check maximum duration and consecutive sessions.
    if (!_hasValidDuration(booking.timeSlots)) {
      return false;
    }

    // Check availability of every selected session.
    for (final time in booking.timeSlots) {
      if (!isSlotAvailable(
        facilityName: booking.facilityName,
        date: booking.date,
        time: time,
      )) {
        return false;
      }
    }

    // Add booking only when all checks pass.
    _bookings.add(booking);

    return true;
  }

  // Find a booking using its ID.
  Booking? getBookingById(String id) {
    try {
      return _bookings.firstWhere((booking) => booking.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get bookings belonging to a particular student.
  List<Booking> getBookingsByEmail(String email) {
    return _bookings.where((booking) => booking.userEmail == email).toList();
  }
}
