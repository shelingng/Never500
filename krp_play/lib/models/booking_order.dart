// SCRUM-48: one combined order (a `bookings` row) with every session and
// payment saved for it. Grouping and labels live here so they can be tested
// without a database. Times follow docs/architecture.md section 4.4: sessions
// are Kuala Lumpur wall-clock, instants are shown in KL time (UTC+8).

/// The four history tabs. A booking is in exactly one of them.
enum OrderGroup { upcoming, pending, past, cancelled }

const Duration _klOffset = Duration(hours: 8);

const List<String> _monthNames = [
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

/// `9:00 PM` from a database time such as `21:00:00`.
String formatSessionTime(String dbTime) {
  final parts = dbTime.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$hour12:$minute ${hour < 12 || hour == 24 ? 'AM' : 'PM'}';
}

/// `25 Nov 2026` for a KL calendar date.
String formatKlDate(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

/// `24 Nov 2026, 3:40 PM` in KL time, whatever the device time zone is.
String formatKlInstant(DateTime instant) {
  final kl = instant.toUtc().add(_klOffset);
  final hour12 = kl.hour % 12 == 0 ? 12 : kl.hour % 12;
  final minute = kl.minute.toString().padLeft(2, '0');
  return '${formatKlDate(kl)}, $hour12:$minute ${kl.hour < 12 ? 'AM' : 'PM'}';
}

String formatRinggit(num amount) => 'RM${amount.toStringAsFixed(2)}';

DateTime? _parseInstant(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString())?.toUtc();

num _parseNum(dynamic value) =>
    value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;

/// Converts a KL date + wall-clock time to the matching UTC instant.
DateTime _klToUtc(DateTime date, String dbTime) {
  final parts = dbTime.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime.utc(
    date.year,
    date.month,
    date.day,
    hour,
    minute,
  ).subtract(_klOffset);
}

class OrderSession {
  final String facilityName;
  final DateTime date; // KL calendar date
  final String startTime; // database time, KL wall clock
  final String endTime;
  final num price;
  final String status;

  const OrderSession({
    required this.facilityName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.price,
    this.status = 'confirmed',
  });

  bool get isCancelled =>
      status.toLowerCase().contains('cancel') ||
      status.toLowerCase().contains('refund') ||
      status.toLowerCase().contains('closed') ||
      status.toLowerCase() == 'expired' ||
      status.toLowerCase() == 'failed';
  String get sessionStatusLabel => status.toLowerCase() == 'pending_payment'
      ? 'Awaiting payment'
      : status.toLowerCase() == 'expired'
      ? 'Expired - not paid'
      : isCancelled
      ? (status.toLowerCase().contains('refund')
            ? 'Refunded session'
            : 'Cancelled by management')
      : 'Confirmed session';

  DateTime get startsAt => _klToUtc(date, startTime);

  /// An end time of 00:00 means midnight at the end of [date].
  DateTime get endsAt {
    final end = _klToUtc(date, endTime);
    return end.isAfter(startsAt) ? end : end.add(const Duration(days: 1));
  }

  String get interval =>
      '${formatSessionTime(startTime)} - ${formatSessionTime(endTime)}';
}

class OrderPayment {
  final String status; // pending | paid | simulated_success
  final String? method; // fpx | touch_n_go_ewallet
  final String? gateway; // billplz | prototype_demo
  final String? reference;
  final DateTime? paidAt;
  final num amount;

  const OrderPayment({
    required this.status,
    this.method,
    this.gateway,
    this.reference,
    this.paidAt,
    required this.amount,
  });

  bool get isPaid => status == 'paid';
  bool get isDemo =>
      status == 'simulated_success' || gateway == 'prototype_demo';

  String get methodLabel => switch (method) {
    'fpx' => 'FPX online banking',
    'touch_n_go_ewallet' => "Touch 'n Go eWallet",
    _ => method ?? '-',
  };
}

class BookingOrder {
  final String id;
  final String reference;
  final String status; // stored status, e.g. confirmed, Closed (Maintenance)
  final num total;
  final DateTime? createdAt;
  final DateTime? paymentDeadline;
  final bool isDemo;
  final List<OrderSession> sessions; // sorted by start time
  final List<OrderPayment> payments;

  const BookingOrder({
    required this.id,
    required this.reference,
    required this.status,
    required this.total,
    this.createdAt,
    this.paymentDeadline,
    this.isDemo = false,
    required this.sessions,
    required this.payments,
  });

  /// Builds an order from a `bookings` row with nested `booking_items`
  /// (+ `time_slots` + `facilities`) and `payments`, as selected by
  /// `BookingService.getMyOrders`.
  factory BookingOrder.fromRow(Map<String, dynamic> row) {
    final sessions = <OrderSession>[];
    for (final raw in (row['booking_items'] as List? ?? const [])) {
      final item = Map<String, dynamic>.from(raw as Map);
      final slot = item['time_slots'] as Map?;
      final date = DateTime.tryParse(slot?['slot_date']?.toString() ?? '');
      if (slot == null || date == null) continue;
      sessions.add(
        OrderSession(
          facilityName:
              (slot['facilities'] as Map?)?['name']?.toString() ?? 'Facility',
          date: date,
          startTime: slot['start_time'].toString(),
          endTime: (slot['end_time'] ?? slot['start_time']).toString(),
          price: _parseNum(item['price']),
          status: (item['status'] ?? row['status'] ?? 'confirmed').toString(),
        ),
      );
    }

    // Older records saved the session on the booking row instead of items.
    final legacyDate = DateTime.tryParse(row['booking_date']?.toString() ?? '');
    final legacyStart = row['start_time']?.toString();
    if (sessions.isEmpty && legacyDate != null && legacyStart != null) {
      final hour = (int.tryParse(legacyStart.split(':').first) ?? 0) + 1;
      sessions.add(
        OrderSession(
          facilityName: (row['facility_name'] ?? 'Facility').toString(),
          date: legacyDate,
          startTime: legacyStart,
          endTime: '${hour.toString().padLeft(2, '0')}:00:00',
          price: _parseNum(row['total_amount']),
        ),
      );
    }
    sessions.sort((a, b) => a.startsAt.compareTo(b.startsAt));

    final payments = [
      for (final raw in (row['payments'] as List? ?? const []))
        () {
          final p = Map<String, dynamic>.from(raw as Map);
          return OrderPayment(
            status: (p['status'] ?? '').toString().toLowerCase(),
            method: p['payment_method']?.toString(),
            gateway: p['payment_gateway']?.toString(),
            reference: (p['transaction_reference'] ?? p['billplz_id'])
                ?.toString(),
            paidAt: _parseInstant(p['paid_at']),
            amount: _parseNum(p['amount']),
          );
        }(),
    ];

    return BookingOrder(
      id: row['id'].toString(),
      reference: (row['booking_reference'] ?? row['id']).toString(),
      status: (row['status'] ?? '').toString().trim(),
      total: _parseNum(row['total_amount']),
      createdAt: _parseInstant(row['created_at']),
      paymentDeadline: _parseInstant(row['payment_deadline']),
      isDemo: row['is_demo'] == true,
      sessions: sessions,
      payments: payments,
    );
  }

  String get _status => status.toLowerCase();

  /// Reference short enough to read: `KRP-<uuid>` becomes `KRP-3F9A2C1B`.
  /// Other formats are kept as they are. Copy [reference] for the full value.
  String get shortReference {
    final match = RegExp(
      r'^([A-Za-z]+-)?([0-9a-fA-F]{8})-[0-9a-fA-F]{4}-',
    ).firstMatch(reference);
    if (match == null) return reference;
    return '${match.group(1) ?? ''}${match.group(2)!.toUpperCase()}';
  }

  /// The payment that settled this order, if any (paid or demo).
  OrderPayment? get settledPayment {
    for (final p in payments) {
      if (p.isPaid || p.isDemo) return p;
    }
    return null;
  }

  bool holdActiveAt(DateTime now) =>
      _status == 'pending_payment' &&
      paymentDeadline != null &&
      paymentDeadline!.isAfter(now.toUtc());

  /// Which history tab the order belongs to at [now].
  OrderGroup groupAt(DateTime now) {
    if (_status == 'pending_payment') {
      return holdActiveAt(now) ? OrderGroup.pending : OrderGroup.cancelled;
    }
    if (_status == 'confirmed') {
      final stillToPlay =
          sessions.isEmpty ||
          sessions.any((s) => !s.isCancelled && s.endsAt.isAfter(now.toUtc()));
      return stillToPlay ? OrderGroup.upcoming : OrderGroup.past;
    }
    return OrderGroup.cancelled;
  }

  /// Exact status for the badge; each stored status keeps its own label.
  String statusLabelAt(DateTime now) {
    final s = _status;
    if (s == 'pending_payment') {
      return holdActiveAt(now) ? 'Awaiting payment' : 'Expired - not paid';
    }
    if (s == 'confirmed') {
      if (sessions.any((session) => session.isCancelled)) {
        return 'Partially cancelled - check sessions';
      }
      if (isDemo) return 'Confirmed (demo)';
      return groupAt(now) == OrderGroup.past ? 'Completed' : 'Paid & confirmed';
    }
    if (s == 'expired') return 'Expired - not paid';
    if (s == 'refunded') return 'Refunded';
    if (s == 'cancelled') return 'Cancelled';
    if (s == 'cancelled_by_management') return 'Cancelled by management';
    if (s.startsWith('closed')) {
      final reason = RegExp(r'\((.+)\)').firstMatch(status)?.group(1);
      return reason == null ? 'Closed by KRP' : 'Closed by KRP ($reason)';
    }
    return status.isEmpty ? 'Unknown' : status;
  }
}
