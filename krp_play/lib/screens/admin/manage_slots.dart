import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _SlotStatus { open, reserved, closed }

class _DemoBooking {
  final String id;
  final int amount;
  final bool paid;
  bool cancelled = false;

  _DemoBooking({required this.id, required this.amount, required this.paid});
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
    if (rawPayload is List) {
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
    if (bookingItems is List) {
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
                'paid': true,
              });
            }
          }
        }
      }
    }

    return found;
  }

  Future<void> _syncTimeSlotsAvailability(
    String dateStr,
    int hour, {
    required bool available,
  }) async {
    final rows = await supabase
        .from('time_slots')
        .select('id, start_time, facilities(name)')
        .eq('slot_date', dateStr);

    var updatedCount = 0;
    for (final r in (rows as List)) {
      final row = r as Map;
      final facName = ((row['facilities'] as Map?)?['name'] ?? '')
          .toString()
          .trim();
      final startTime = (row['start_time'] ?? '').toString().trim();
      if (_sameFacility(facName, _facility) && _matchesHour(startTime, hour)) {
        await supabase
            .from('time_slots')
            .update({'is_available': available})
            .eq('id', row['id']);
        updatedCount++;
      }
    }

    if (updatedCount == 0) {
      final facilitiesRows = await supabase.from('facilities').select('id, name');
      String? facilityId;
      for (final f in (facilitiesRows as List)) {
        final fMap = f as Map;
        if (_sameFacility((fMap['name'] ?? '').toString(), _facility)) {
          facilityId = fMap['id']?.toString();
          break;
        }
      }
      if (facilityId != null) {
        final startStr = '${hour.toString().padLeft(2, '0')}:00:00';
        final endHour = (hour + 1) % 24;
        final endStr = '${endHour.toString().padLeft(2, '0')}:00:00';
        await supabase.from('time_slots').insert({
          'facility_id': facilityId,
          'slot_date': dateStr,
          'start_time': startStr,
          'end_time': endStr,
          'is_available': available,
        });
      }
    }
  }

  Future<String?> _resolvePaymentId(Map bookingRecord, String bookingId) async {
    final directId = bookingRecord['payment_id']?.toString().trim();
    if (directId != null && directId.isNotEmpty) {
      return directId;
    }

    try {
      final paymentRow = await supabase
          .from('payments')
          .select('id')
          .eq('booking_id', bookingId)
          .limit(1)
          .maybeSingle();
      final fetchedId = paymentRow?['id']?.toString().trim();
      if (fetchedId != null && fetchedId.isNotEmpty) {
        return fetchedId;
      }
    } catch (_) {}

    return null;
  }

  Future<void> _fetchLiveSlots({bool showLoader = true}) async {
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
        for (final r in (joinedRows as List)) {
          occupiedRecords.addAll(
            _extractItemsFromBookingMap(Map.from(r as Map), dateStr),
          );
        }
      } catch (e) {
        errMsg = e.toString();
        try {
          final plainRows = await supabase.from('bookings').select();
          for (final r in (plainRows as List)) {
            occupiedRecords.addAll(
              _extractItemsFromBookingMap(Map.from(r as Map), dateStr),
            );
          }
          errMsg = null;
        } catch (e2) {
          errMsg = e2.toString();
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
                .where((m) => !_isInactiveStatus((m['status'] ?? '').toString()))
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

      if (mounted) {
        setState(() {
          _lastQueryError = errMsg;
          _liveSlots = fetchedSlots;
          _selected.clear();
        });
      }
    } catch (e) {
      debugPrint('Error fetching slots: $e');
      if (mounted) {
        setState(() => _lastQueryError = e.toString());
      }
    } finally {
      if (showLoader && mounted) setState(() => _isLoading = false);
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
                'Booked sessions closed by management will stay in Reservations history and create a refund record in Refund Management.',
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

    int createdRefundCount = 0;

    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final allRows = await supabase.from('bookings').select();
      final records = (allRows as List)
          .map((r) => Map.from(r as Map))
          .where((b) => _extractItemsFromBookingMap(b, dateStr).isNotEmpty)
          .toList();

      for (final slot in targets) {
        final hour12 = slot.start.hour > 12
            ? slot.start.hour - 12
            : (slot.start.hour == 0 ? 12 : slot.start.hour);
        final ampm = slot.start.hour >= 12 ? 'PM' : 'AM';
        final slotTime = '$hour12:00 $ampm';

        final matchingRecords = records.where((record) {
          final stat = (record['status']?.toString() ?? '').toLowerCase();
          final items = _extractItemsFromBookingMap(record, dateStr);
          return items.any(
                (it) =>
                    _matchesHour((it['time'] ?? '').toString(), slot.start.hour),
              ) &&
              !_isClosedStatus(stat) &&
              !_isInactiveStatus(stat);
        }).toList();

        if (slot.status == _SlotStatus.reserved || matchingRecords.isNotEmpty) {
          for (var record in matchingRecords) {
            final bookingId = record['id']?.toString().trim();
            if (bookingId == null || bookingId.isEmpty) continue;

            double refundAmount = 0;
            final rawAmt = record['total_amount'] ?? record['amount'];
            if (rawAmt is num) refundAmount = rawAmt.toDouble();
            if (rawAmt is String) refundAmount = double.tryParse(rawAmt) ?? 0;

            await supabase
                .from('bookings')
                .update({'status': 'Closed ($reason)'})
                .eq('id', bookingId);

            try {
              await supabase
                  .from('booking_items')
                  .update({'status': 'Closed ($reason)'})
                  .eq('booking_id', bookingId);
            } catch (_) {}

            final existingRefund = await supabase
                .from('refunds')
                .select('id')
                .eq('booking_id', bookingId)
                .maybeSingle();

            if (existingRefund == null) {
              final paymentId = await _resolvePaymentId(record, bookingId);
              final nowIso = DateTime.now().toIso8601String();
              final adminId = supabase.auth.currentUser?.id;
              final refCode =
                  'RF-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

              final insertMap = <String, dynamic>{
                'refund_reference': refCode,
                'booking_id': bookingId,
                'amount': refundAmount,
                'reason': 'Facility closed by KRP Management: $reason',
                'refund_method': 'manual',
                'refund_channel': 'bank_transfer',
                'status': 'awaiting_action',
                if (paymentId != null) 'payment_id': paymentId,
                if (adminId != null) 'processed_by': adminId,
                'created_at': nowIso,
                'updated_at': nowIso,
              };

              final insertedRefund = await supabase
                  .from('refunds')
                  .insert(insertMap)
                  .select('id')
                  .single();

              final refundId = insertedRefund['id']?.toString();
              if (refundId != null) {
                try {
                  await supabase.from('refund_events').insert({
                    'refund_id': refundId,
                    'event_type': 'created_from_closure',
                    'previous_status': null,
                    'new_status': 'awaiting_action',
                    'note': 'Closed $_facility ($dateStr $slotTime) — $reason',
                    if (adminId != null) 'performed_by': adminId,
                  });
                } catch (_) {}
              }
              createdRefundCount++;
            } else {
              createdRefundCount++;
            }
          }
        }

        final uniqueRef =
            'ADMIN-${slot.start.hour}-${DateTime.now().millisecondsSinceEpoch}';
        await supabase.from('bookings').insert({
          'user_id': supabase.auth.currentUser?.id,
          'facility_name': _facility,
          'booking_date': dateStr,
          'start_time': slotTime,
          'status': 'Closed ($reason)',
          'total_amount': 0,
          'booking_reference': uniqueRef,
        });

        await _syncTimeSlotsAvailability(dateStr, slot.start.hour, available: false);
      }

      if (createdRefundCount > 0) {
        _message(
          'Booked slot closed ($createdRefundCount refund record(s)) — opening Refund Management.',
        );
      } else {
        _message('Sessions successfully closed in live database.');
      }
    } catch (e) {
      await _showErrorDialog('Refund / Closure Error', e);
    }

    await _fetchLiveSlots();

    if (mounted && createdRefundCount > 0) {
      widget.onNavigateToRefunds?.call();
    }
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
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final allRows = await supabase.from('bookings').select();
      for (final r in (allRows as List)) {
        final record = Map.from(r as Map);
        final stat = (record['status']?.toString() ?? '').toLowerCase();
        if (!_isClosedStatus(stat)) continue;
        final items = _extractItemsFromBookingMap(record, dateStr);
        final matchesHour = items.any(
          (it) => _matchesHour((it['time'] ?? '').toString(), slot.start.hour),
        );
        if (matchesHour) {
          final refCode = (record['booking_reference'] ?? '').toString();
          if (refCode.startsWith('ADMIN-')) {
            await supabase.from('bookings').delete().eq('id', record['id']);
          } else {
            await supabase
                .from('bookings')
                .update({'status': 'Refunded'})
                .eq('id', record['id']);
            try {
              await supabase
                  .from('booking_items')
                  .update({'status': 'Refunded'})
                  .eq('booking_id', record['id']);
            } catch (_) {}
          }
        }
      }

      await _syncTimeSlotsAvailability(dateStr, slot.start.hour, available: true);

      _message('Session reopened in live database.');
    } catch (e) {
      await _showErrorDialog('Reopen Error', e);
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

  void _viewDetails(_Slot slot) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Session details'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_facility),
            Text(_dateLabel(slot.start)),
            Text(_timeRange(slot)),
            const SizedBox(height: 12),
            Text('Status: ${_statusLabel(slot)}'),
            if (slot.closureReason != null)
              Text('Closure reason: ${slot.closureReason}'),
            const Divider(height: 24),
            if (slot.bookings.isEmpty)
              const Text('No bookings for this session.'),
            ...slot.bookings.map(
              (booking) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${booking.id}\n${booking.cancelled ? 'Cancelled by management' : 'Active reservation'}\n${booking.paid ? 'Paid' : 'Unpaid'} · ${_money(booking.amount)}',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
      setState(() => _selectedDate = picked);
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
                          setState(() => _facility = value);
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
            'Reserved sessions closed by management automatically create a refund record and navigate to Refund Management.',
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