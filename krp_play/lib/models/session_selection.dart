/// Matches reserve_cart's whole-hour operating-schedule grid.
/// This is selection guidance; the server still validates every reservation.
class SessionSelection {
  static int? clockMinutes(Object? value) {
    final parts = value?.toString().split(':') ?? const <String>[];
    if (parts.length < 2 || parts.length > 3) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final seconds = parts.length == 3 ? num.tryParse(parts[2]) : 0;
    if (hour == null ||
        minute == null ||
        seconds != 0 ||
        hour < 0 ||
        hour > 24 ||
        minute < 0 ||
        minute > 59 ||
        (hour == 24 && minute != 0)) {
      return null;
    }
    return hour * 60 + minute;
  }

  static List<int> startsForDate(
    List<Map<String, dynamic>> schedules,
    DateTime date,
  ) {
    final starts = <int>{};
    for (final schedule in schedules) {
      if (schedule['is_active'] != true ||
          schedule['day_of_week'] != date.weekday % 7 ||
          schedule['slot_minutes'] != 60) {
        continue;
      }
      final start = clockMinutes(schedule['start_time']);
      final end = clockMinutes(schedule['end_time']);
      if (start == null || end == null || end <= start) continue;
      for (var time = start; time + 60 <= end && time + 60 < 1440; time += 60) {
        starts.add(time);
      }
    }
    return starts.toList()..sort();
  }

  static String serverError(String message) {
    if (message.contains('OUTSIDE_OPERATING_HOURS')) {
      return 'This session is outside operating hours. Remove it from your order and choose a different start time or duration.';
    }
    if (message.contains('INVALID_DATE')) {
      return 'Choose a booking date from today up to 30 days ahead.';
    }
    return 'This session has already started or is no longer valid. Remove it from your order and choose a future session.';
  }

  static String? error({
    required List<int> allowedStarts,
    required int start,
    required int hours,
  }) {
    if (hours < 1 || hours > 2) {
      return 'Choose a duration of 1 or 2 hours.';
    }
    if (allowedStarts.isEmpty) {
      return 'No bookable sessions are scheduled for this date.';
    }
    if (!allowedStarts.contains(start)) {
      return 'Choose a start time within operating hours.';
    }
    for (var hour = 0; hour < hours; hour++) {
      if (!allowedStarts.contains(start + hour * 60)) {
        return 'This 2-hour booking crosses a closed period. Choose an earlier start or 1 hour.';
      }
    }
    return null;
  }
}
