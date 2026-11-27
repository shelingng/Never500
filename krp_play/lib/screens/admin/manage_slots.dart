import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'reservations.dart';

enum _SlotStatus { open, reserved, closed }

class _DemoBooking {
  final String bookingId;
  final String id;
  final int amount;
  final bool paid;
  bool cancelled = false;

  _DemoBooking({
    required this.id,
    required this.amount,
    required this.paid,
    this.bookingId = '',
  });
}

class _Slot {
  final DateTime start;
  final List<_DemoBooking> bookings;
  _SlotStatus status;
  String? closureReason;

  _Slot({
    required this.start,
    required this.status,
    required this.bookings,
    this.closureReason,
  });

  DateTime get end => start.add(const Duration(hours: 1));

  bool get hasEnded => !end.isAfter(DateTime.now());

  List<_DemoBooking> get activeBookings =>
      bookings.where((booking) => !booking.cancelled).toList();
}

class AdminSlotsTab extends StatefulWidget {
  final VoidCallback? onNavigateToRefunds;

  const AdminSlotsTab({super.key, this.onNavigateToRefunds});

  @override
  State<AdminSlotsTab> createState() => _AdminSlotsTabState();
}

class _AdminSlotsTabState extends State<AdminSlotsTab> {
  static const _green = Color(0xFF173F32);
  final supabase = Supabase.instance.client;

  static const _facilities = [
    'Badminton Court 01',
    'Badminton Court 02',
    'Ping Pong Table 01',
    'Ping Pong Table 02',
    'Snooker Table',
    'Dart Board',
    'Gym',
  ];

  static const _reasons = [
    'Maintenance',
    'College event',
    'Safety inspection',
    'Operational requirement',
  ];

  final Set<_Slot> _selected = {};

  DateTime _selectedDate = DateTime.now();
  String _facility = _facilities.first;

  bool _isLoading = true;
  String? _lastQueryError;
  List<_Slot> _liveSlots = [];
  RealtimeChannel? _slotsChannel;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _fetchLiveSlots(showLoader: true);
    _slotsChannel = supabase
        .channel('admin:manage_slots_sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) {
            if (mounted) _fetchLiveSlots(showLoader: false);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'booking_items',
          callback: (_) {
            if (mounted) _fetchLiveSlots(showLoader: false);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'time_slots',
          callback: (_) {
            if (mounted) _fetchLiveSlots(showLoader: false);
          },
        )
        .subscribe();

    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && !_isLoading) {
        _fetchLiveSlots(showLoader: false);
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    if (_slotsChannel != null) {
      supabase.removeChannel(_slotsChannel!);
    }
    super.dispose();
  }

  String _normalizeFacilityName(String raw) {
    var s = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceFirstMapped(RegExp(r' 0+(\d+)$'), (m) => ' ${m[1]}');
    if (s == 'dart board' ||
        s == 'dart board 1' ||
        s == 'dart' ||
        s == 'board 1' ||
        s == 'dart 1') {
      return 'dart';
    }
    if (s == 'snooker table' ||
        s == 'snooker table 1' ||
        s == 'snooker' ||
        s == 'table 1' ||
        s == 'snooker 1') {
      return 'snooker';
    }
    if (s == 'badminton court 1' || s == 'badminton 1') {
      return 'badminton court 1';
    }
    if (s == 'badminton court 2' || s == 'badminton 2') {
      return 'badminton court 2';
    }
    if (s == 'ping pong table 1' || s == 'ping pong 1') {
      return 'ping pong table 1';
    }
    if (s == 'ping pong table 2' || s == 'ping pong 2') {
      return 'ping pong table 2';
    }
    return s;
  }

  bool _sameFacility(String a, String b) {
    if (a.trim().isEmpty || b.trim().isEmpty) return false;
    return _normalizeFacilityName(a) == _normalizeFacilityName(b);
  }

  String _normalizeDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length >= 10) return trimmed.substring(0, 10);
    return trimmed;
  }

  int? _parseHour(String rawTime) {
    final t = rawTime.trim().toUpperCase();
    if (t.isEmpty) return null;

    final ampmMatch = RegExp(
      r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)$',
    ).firstMatch(t);
    if (ampmMatch != null) {
      var hour = int.parse(ampmMatch[1]!);
      final period = ampmMatch[3]!;
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return hour;
    }

    final isoMatch = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(t);
    if (isoMatch != null) {
      return int.parse(isoMatch[1]!);
    }

    return null;
  }

  bool _matchesHour(String rawTime, int hour) {
    final parsed = _parseHour(rawTime);
    if (parsed != null) return parsed == hour;

    final t = rawTime.trim().toUpperCase();
    if (t.isEmpty) return false;
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final ampm = hour >= 12 ? 'PM' : 'AM';
    return t.contains('$hour12:00 $ampm') ||
        t.contains('${hour.toString().padLeft(2, '0')}:00');
  }

  bool _isClosedStatus(String status) {
    final s = status.trim().toLowerCase();
    return s.contains('closed') || s.contains('maintenance');
  }

  bool _isInactiveStatus(String status) {
    final s = status.trim().toLowerCase();
    if (_isClosedStatus(s)) return false;
    return s.contains('cancel') ||
        s.contains('expir') ||
        s.contains('fail') ||
        s.contains('refund');
  }

  List _extractItemsFromBookingMap(Map b, String dateStr) {
    final found = [];
    final status = (b['status'] ?? '').toString();
    final isClosed = _isClosedStatus(status);
    if (!isClosed && _isInactiveStatus(status)) return found;

    final id = (b['id'] ?? '').toString();
    final rawAmt = b['total_amount'] ?? b['amount'];
    int amountCents = 0;
    if (rawAmt is num) {
      amountCents = (rawAmt * 100).round();
    } else if (rawAmt is String) {
      amountCents = ((double.tryParse(rawAmt) ?? 0) * 100).round();
    }
    final isPaid =
        status.toLowerCase() == 'paid' ||
        status.toLowerCase() == 'confirmed' ||
        status.toLowerCase() == 'booked';

    final topFacility = (b['facility_name'] ?? '').toString().trim();
    final topDate = _normalizeDate((b['booking_date'] ?? '').toString());
    final topTime = (b['start_time'] ?? '').toString().trim();

    if (_sameFacility(topFacility, _facility) &&
        topDate == dateStr &&
        topTime.isNotEmpty) {
      found.add({
        'id': id,
        'time': topTime,
        'status': status,
        'amount': amountCents,
        'paid': isPaid,
      });
    }

    final rawPayload = b['checkout_payload'];
    if (rawPayload is List && rawPayload.isNotEmpty) {
      // Payload sessions replace legacy top-level booking fields.
      found.clear();
      for (final item in rawPayload) {
        if (item is Map) {
          final f = (item['facility_name'] ?? topFacility).toString().trim();
          final d = _normalizeDate(
            (item['booking_date'] ?? item['date'] ?? topDate).toString(),
          );
          if (_sameFacility(f, _facility) && d == dateStr) {
            if (item['start_times'] is List) {
              for (final st in (item['start_times'] as List)) {
                found.add({
                  'id': id,
                  'time': st.toString().trim(),
                  'status': status,
                  'amount': amountCents,
                  'paid': isPaid,
                });
              }
            } else {
              final t = (item['start_time'] ?? topTime).toString().trim();
              if (t.isNotEmpty) {
                found.add({
                  'id': id,
                  'time': t,
                  'status': status,
                  'amount': amountCents,
                  'paid': isPaid,
                });
              }
            }
          }
        }
      }
    }

    final bookingItems = b['booking_items'];
    if (bookingItems is List && bookingItems.isNotEmpty) {
      // Linked items are authoritative for multi-session orders.
      found.clear();
      for (final rawItem in bookingItems) {
        if (rawItem is Map) {
          final itemStatus = (rawItem['status'] ?? status).toString();
          final itemClosed = _isClosedStatus(itemStatus) || isClosed;
          if (!itemClosed && _isInactiveStatus(itemStatus)) continue;
          final slot = rawItem['time_slots'] as Map?;
          if (slot != null) {
            final facName =
                ((slot['facilities'] as Map?)?['name'] ?? topFacility)
                    .toString()
                    .trim();
            final slotDate = _normalizeDate(
              (slot['slot_date'] ?? topDate).toString(),
            );
            final slotTime = (slot['start_time'] ?? topTime).toString().trim();
            if (_sameFacility(facName, _facility) &&
                slotDate == dateStr &&
                slotTime.isNotEmpty) {
              final itemPrice = rawItem['price'];
              int itemCents = amountCents;
              if (itemPrice is num) {
                itemCents = (itemPrice * 100).round();
              }
              found.add({
                'id': id,
                'time': slotTime,
                'status': itemClosed
                    ? (isClosed ? status : itemStatus)
                    : itemStatus,
                'amount': itemCents,
                'paid': isPaid,
              });
            }
          }
        }
      }
    }

    // Do not repeat the same booking within this facility/date/hour.
    final unique = <String, Map>{};
    for (final raw in found) {
      final row = Map.from(raw as Map);
      final time = (row['time'] ?? '').toString();
      final hour = _parseHour(time);
      final key = '${row['id']}|${hour ?? time}';
      unique[key] = row;
    }
    return unique.values.toList();
  }

  int _slotLoadVersion = 0;
  bool _slotFetchInFlight = false;

  Future<void> _fetchLiveSlots({bool showLoader = true}) async {
    if (!showLoader && _slotFetchInFlight) return;
    _slotFetchInFlight = true;
    final loadVersion = ++_slotLoadVersion;
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _lastQueryError = null;
      });
    }
    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final List occupiedRecords = [];
      String? errMsg;

      try {
        final joinedRows = await supabase
            .from('bookings')
            .select(
              '*, booking_items(price, status, time_slots(slot_date, start_time, facilities(name)))',
            );
        if (!mounted || loadVersion != _slotLoadVersion) return;
        for (final r in (joinedRows as List)) {
          occupiedRecords.addAll(
            _extractItemsFromBookingMap(Map.from(r as Map), dateStr),
          );
        }
      } catch (e) {
        rethrow;
      }

      final lockedRows = await supabase
          .from('time_slots')
          .select('start_time, locked_reason, facilities(name)')
          .eq('slot_date', dateStr)
          .eq('is_available', false);
      if (!mounted || loadVersion != _slotLoadVersion) return;
      for (final raw in lockedRows) {
        final row = Map<String, dynamic>.from(raw);
        if (_sameFacility(
          (row['facilities'] as Map?)?['name']?.toString() ?? '',
          _facility,
        )) {
          occupiedRecords.add({
            'id': 'closure',
            'time': row['start_time'],
            'status':
                'Closed (${row['locked_reason'] ?? 'Management closure'})',
            'amount': 0,
            'paid': false,
          });
        }
      }

      final weekend =
          _selectedDate.weekday == DateTime.saturday ||
          _selectedDate.weekday == DateTime.sunday;
      final hours = weekend
          ? [10, 11, 12, 15, 16, 17, 18, 21, 22]
          : [17, 18, 21, 22];

      final List<_Slot> fetchedSlots = [];

      for (int hour in hours) {
        final hourMatches = occupiedRecords
            .where((rec) => _matchesHour((rec['time'] ?? '').toString(), hour))
            .toList();

        if (hourMatches.isEmpty) {
          fetchedSlots.add(
            _Slot(
              start: DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                hour,
              ),
              status: _SlotStatus.open,
              bookings: [],
            ),
          );
        } else {
          Map? closedMatch;
          for (final m in hourMatches) {
            if (_isClosedStatus((m['status'] ?? '').toString())) {
              closedMatch = m;
              break;
            }
          }

          if (closedMatch != null) {
            final rawStatus = (closedMatch['status'] ?? '').toString();
            final reason = rawStatus
                .toLowerCase()
                .replaceAll('closed', '')
                .replaceAll('(', '')
                .replaceAll(')', '')
                .trim();
            fetchedSlots.add(
              _Slot(
                start: DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  hour,
                ),
                status: _SlotStatus.closed,
                closureReason: reason.isEmpty ? 'Management closure' : reason,
                bookings: [],
              ),
            );
          } else {
            final activeOnly = hourMatches
                .where(
                  (m) => !_isInactiveStatus((m['status'] ?? '').toString()),
                )
                .toList();

            if (activeOnly.isEmpty) {
              fetchedSlots.add(
                _Slot(
                  start: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    hour,
                  ),
                  status: _SlotStatus.open,
                  bookings: [],
                ),
              );
            } else {
              final demoBookings = activeOnly.map((m) {
                final rawId = (m['id'] ?? 'BOOKING').toString();
                final safeId = rawId.length > 8
                    ? rawId.substring(0, 8).toUpperCase()
                    : rawId.toUpperCase();
                return _DemoBooking(
                  id: safeId,
                  bookingId: rawId,
                  amount: (m['amount'] as int?) ?? 0,
                  paid: (m['paid'] as bool?) ?? true,
                );
              }).toList();

              fetchedSlots.add(
                _Slot(
                  start: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    hour,
                  ),
                  status: _SlotStatus.reserved,
                  closureReason: null,
                  bookings: demoBookings,
                ),
              );
            }
          }
        }
      }

      if (mounted && loadVersion == _slotLoadVersion) {
        setState(() {
          _lastQueryError = errMsg;
          final selectedStarts = _selected.map((slot) => slot.start).toSet();
          _liveSlots = fetchedSlots;
          _selected
            ..clear()
            ..addAll(
              fetchedSlots.where(
                (slot) =>
                    selectedStarts.contains(slot.start) &&
                    !slot.hasEnded &&
                    slot.status != _SlotStatus.closed,
              ),
            );
        });
      }
    } catch (e) {
      debugPrint('Error fetching slots: $e');
      if (mounted && loadVersion == _slotLoadVersion) {
        setState(() => _lastQueryError = e.toString());
      }
    } finally {
      if (loadVersion == _slotLoadVersion) _slotFetchInFlight = false;
      if (mounted && loadVersion == _slotLoadVersion)
        setState(() => _isLoading = false);
    }
  }

  Future<void> _showErrorDialog(String title, Object error) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SelectableText(error.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewClosure(List<_Slot> requested) async {
    final targets = requested
        .where((slot) => !slot.hasEnded && slot.status != _SlotStatus.closed)
        .toList();
    if (targets.isEmpty) {
      _message('Select an open or reserved session first.');
      return;
    }

    String reason = _reasons.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Closure'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Closing ${targets.length} session(s) for $_facility.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(
                  labelText: 'Closure reason',
                  border: OutlineInputBorder(),
                ),
                items: _reasons
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) reason = value;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Only the selected sessions are cancelled. Refund requests use each affected session price; other sessions remain booked.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Close Sessions'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;
    setState(() => _isLoading = true);

    try {
      final result = await _setSessionClosure(targets, true, reason);
      final count = (result['refunds_created'] as num?)?.toInt() ?? 0;
      _message(
        'Closed ${targets.length} selected session(s). $count refund request(s) created. Other sessions are kept.',
      );
      if (mounted && count > 0) widget.onNavigateToRefunds?.call();
    } catch (e) {
      await _showErrorDialog('Session closure failed', e);
    }
    await _fetchLiveSlots();
  }

  Future<Map<String, dynamic>> _setSessionClosure(
    List<_Slot> slots,
    bool closed,
    String reason,
  ) async {
    final rows = await supabase.from('facilities').select('id,name');
    final matches = rows
        .where((r) => _sameFacility(r['name'].toString(), _facility))
        .toList();
    if (matches.length != 1)
      throw StateError('Facility could not be uniquely identified.');
    final date = slots.first.start;
    final result = await supabase.rpc(
      'admin_set_session_closure',
      params: {
        'p_facility_id': matches.single['id'],
        'p_date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'p_start_times': slots
            .map((s) => '${s.start.hour.toString().padLeft(2, '0')}:00:00')
            .toList(),
        'p_closed': closed,
        'p_reason': reason,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> _reopen(_Slot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reopen session?'),
        content: const Text(
          'This will remove the closure block from the database and allow students to book this slot again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep closed'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reopen session'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    setState(() => _isLoading = true);

    try {
      await _setSessionClosure([slot], false, '');
      _message(
        'Session reopened. Cancelled bookings and refund requests are kept.',
      );
    } catch (e) {
      await _showErrorDialog('Reopen failed', e);
    }

    await _fetchLiveSlots();
  }

  String _money(int cents) => 'RM ${(cents / 100).toStringAsFixed(2)}';
  String _dateLabel(DateTime date) =>
      '${date.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.year}';
  String _time(DateTime date) =>
      '${date.hour % 12 == 0 ? 12 : date.hour % 12}:00 ${date.hour < 12 ? 'AM' : 'PM'}';
  String _timeRange(_Slot slot) => '${_time(slot.start)} - ${_time(slot.end)}';
  String _statusLabel(_Slot slot) {
    switch (slot.status) {
      case _SlotStatus.open:
        return 'Open';
      case _SlotStatus.reserved:
        return 'Reserved';
      case _SlotStatus.closed:
        return 'Closed by management';
    }
  }

  Color _statusColor(_Slot slot) {
    switch (slot.status) {
      case _SlotStatus.open:
        return Colors.green.shade800;
      case _SlotStatus.reserved:
        return Colors.blue.shade800;
      case _SlotStatus.closed:
        return Colors.grey.shade700;
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  bool _loadingSessionDetails = false;

  Future<void> _viewDetails(_Slot slot) async {
    if (_loadingSessionDetails) return;
    _loadingSessionDetails = true;
    final owner = supabase.auth.currentUser?.id;
    final facility = _facility;
    final date = _dateLabel(slot.start);
    final time = _timeRange(slot);
    final slotStatus = _statusLabel(slot);
    final reason = slot.closureReason;
    final ids = slot.bookings
        .map((booking) => booking.bookingId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    try {
      if (owner == null || await supabase.rpc('is_admin') != true) {
        throw StateError('Admin access required');
      }
      final List<Map<String, dynamic>> rows = [];
      if (ids.isNotEmpty) {
        final response = await supabase
            .from('bookings')
            .select(
              'id, booking_reference, status, total_amount, is_demo, '
              'customer_name, customer_matric_number, '
              'profiles!booking_user_id_fkey(full_name, matric_number), '
              'payments(status, created_at)',
            )
            .inFilter('id', ids);
        rows.addAll(response.map((row) => Map<String, dynamic>.from(row)));
      }
      if (!mounted || supabase.auth.currentUser?.id != owner) return;
      final byId = {for (final row in rows) row['id'].toString(): row};

      String value(dynamic raw) {
        final text = raw?.toString().trim() ?? '';
        return text.isEmpty ? 'Not recorded' : text;
      }

      Widget line(String label, dynamic raw) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: SelectableText('$label: ${value(raw)}'),
      );

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Session details'),
          scrollable: true,
          content: SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                line('Facility', facility),
                line('Date', date),
                line('Time', time),
                line('Slot status', slotStatus),
                if (reason != null) line('Closure reason', reason),
                if (slot.bookings.isEmpty)
                  const Text('No bookings for this session.'),
                for (final booking in slot.bookings)
                  Builder(
                    builder: (_) {
                      final row = byId[booking.bookingId];
                      if (row == null) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Booking details unavailable. Close and retry.',
                          ),
                        );
                      }
                      final profile = row['profiles'] as Map?;
                      final payments =
                          [
                            for (final payment
                                in (row['payments'] as List? ?? []))
                              Map<String, dynamic>.from(payment as Map),
                          ]..sort(
                            (a, b) => (b['created_at'] ?? '')
                                .toString()
                                .compareTo((a['created_at'] ?? '').toString()),
                          );
                      final paid = payments.any(
                        (payment) =>
                            payment['status']?.toString().toLowerCase() ==
                            'paid',
                      );
                      final paymentStatus = row['is_demo'] == true
                          ? 'Demo payment'
                          : paid
                          ? 'Paid'
                          : payments.isEmpty
                          ? 'No payment record'
                          : value(payments.first['status']);
                      final reference = value(row['booking_reference']);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 24),
                          line('Booking reference', reference),
                          line(
                            'Student name',
                            profile?['full_name'] ?? row['customer_name'],
                          ),
                          line(
                            'Matric number',
                            profile?['matric_number'] ??
                                row['customer_matric_number'],
                          ),
                          line('Booking status', row['status']),
                          line('Payment status', paymentStatus),
                          line('This session price', _money(booking.amount)),
                          line(
                            'Whole order total',
                            row['total_amount'] == null
                                ? null
                                : 'RM${num.parse(row['total_amount'].toString()).toStringAsFixed(2)}',
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: const Text('View full booking'),
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => Scaffold(
                                    appBar: AppBar(
                                      title: const Text('Booking history'),
                                    ),
                                    body: AdminBookingsTab(
                                      initialSearch:
                                          row['booking_reference']
                                              ?.toString() ??
                                          booking.bookingId,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted && supabase.auth.currentUser?.id == owner) {
        _message('Could not load booking details. Please try again.');
      }
    } finally {
      _loadingSessionDetails = false;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = firstDate.add(const Duration(days: 30));

    DateTime initialDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _green,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selected.clear();
        _selectedDate = picked;
      });
      _fetchLiveSlots();
    }
  }

  Widget _slotCard(_Slot slot, double width) {
    final past = slot.hasEnded;
    final closed = slot.status == _SlotStatus.closed;
    final reserved = slot.status == _SlotStatus.reserved;

    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _timeRange(slot),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Checkbox(
                    value: _selected.contains(slot),
                    onChanged: past || closed
                        ? null
                        : (checked) {
                            setState(() {
                              if (checked == true) {
                                _selected.add(slot);
                              } else {
                                _selected.remove(slot);
                              }
                            });
                          },
                  ),
                ],
              ),
              Text(
                _statusLabel(slot),
                style: TextStyle(
                  color: _statusColor(slot),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                past
                    ? 'Session ended'
                    : closed
                    ? 'Reason: ${slot.closureReason}'
                    : reserved
                    ? 'Booked · ${slot.activeBookings.first.paid ? 'Paid' : 'Unpaid'}'
                    : 'Available for booking',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!past)
                    OutlinedButton(
                      onPressed: closed
                          ? () => _reopen(slot)
                          : () => _reviewClosure([slot]),
                      child: Text(
                        closed
                            ? 'Reopen'
                            : reserved
                            ? 'Review closure'
                            : 'Close session',
                      ),
                    ),
                  TextButton(
                    onPressed: () => _viewDetails(slot),
                    child: const Text('View details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AVAILABILITY CONTROL',
            style: TextStyle(
              color: _green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage slots',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _green,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Review the booking impact before closing a session.'),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAF8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDCE4DF)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Date: ${_dateLabel(_selectedDate)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E34),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 0, width: isMobile ? 0 : 16),
                  Expanded(
                    flex: isMobile ? 0 : 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _facility,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Facility',
                        border: OutlineInputBorder(),
                      ),
                      items: _facilities
                          .map(
                            (facility) => DropdownMenuItem(
                              value: facility,
                              child: Text(facility),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selected.clear();
                            _facility = value;
                          });
                          _fetchLiveSlots();
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          if (_lastQueryError != null) ...[
            const SizedBox(height: 8),
            Text(
              'Query notice: $_lastQueryError',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Closing a reserved session creates a refund request for that session only. No money is transferred automatically.',
            style: TextStyle(color: _green),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () => _reviewClosure(_selected.toList()),
                icon: const Icon(Icons.event_busy_outlined),
                label: Text('Review selected (${_selected.length})'),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _selected
                    ..clear()
                    ..addAll(
                      _liveSlots.where(
                        (slot) =>
                            !slot.hasEnded && slot.status != _SlotStatus.closed,
                      ),
                    );
                }),
                child: const Text('Select available and reserved sessions'),
              ),
              if (_selected.isNotEmpty)
                TextButton(
                  onPressed: () => setState(_selected.clear),
                  child: const Text('Clear selection'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: _green),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1000
                        ? 3
                        : constraints.maxWidth >= 650
                        ? 2
                        : 1;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _liveSlots
                          .map((slot) => _slotCard(slot, width))
                          .toList(),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
