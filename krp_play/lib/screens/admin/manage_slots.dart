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

  _Slot({required this.start, required this.status, required this.bookings, this.closureReason});

  DateTime get end => start.add(const Duration(hours: 1));

  bool get hasEnded => !end.isAfter(DateTime.now());

  List<_DemoBooking> get activeBookings =>
      bookings.where((booking) => !booking.cancelled).toList();
}

class AdminSlotsTab extends StatefulWidget {
  const AdminSlotsTab({super.key});

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
  List<_Slot> _liveSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveSlots();
  }

  _fetchLiveSlots() async {
    setState(() => _isLoading = true);
    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final liveData = await supabase
          .from('bookings')
          .select()
          .eq('facility_name', _facility)
          .eq('booking_date', dateStr);

      List<dynamic> availabilityRows = [];
      try {
        final rpcRes = await supabase.rpc(
          'slot_availability',
          params: {'p_date': dateStr},
        );
        if (rpcRes is List) {
          availabilityRows = rpcRes;
        }
      } catch (_) {}

      final weekend =
          _selectedDate.weekday == DateTime.saturday ||
          _selectedDate.weekday == DateTime.sunday;
      final hours = weekend
          ? [10, 11, 12, 14, 15, 16, 17, 18, 20, 21, 22]
          : [17, 18, 20, 21, 22];

      final List<_Slot> fetchedSlots = [];
      final normalizedFacility = _facility.replaceFirstMapped(
        RegExp(r' 0+(\d+)$'),
        (m) => ' ${m[1]}',
      );

      for (int hour in hours) {
        final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final str24 = '${hour.toString().padLeft(2, '0')}:00:00';
        final str12 = '$hour12:00 $ampm';
        final hour24Padded = hour.toString().padLeft(2, '0');

        bool matchesHour(String rawTime) {
          final t = rawTime.trim().toUpperCase();
          return t.contains(str24) ||
              t.contains(str12.toUpperCase()) ||
              t.startsWith('$hour24Padded:') ||
              t.contains('$hour12:00');
        }

        final matchingBookings = liveData.where((b) {
          final dbTime = b['start_time']?.toString() ?? '';
          return matchesHour(dbTime);
        }).toList();

        final matchingSlots = availabilityRows.where((r) {
          final status = (r['status']?.toString() ?? '').toLowerCase();
          if (status == 'available') return false;
          final rowFacility = (r['facility_name']?.toString() ?? '').trim();
          final rowFacilityPadded = rowFacility.replaceFirstMapped(
            RegExp(r' (\d+)$'),
            (m) => ' ${m[1]!.padLeft(2, '0')}',
          );
          final sameFacility =
              rowFacility.toLowerCase() == _facility.toLowerCase() ||
              rowFacility.toLowerCase() == normalizedFacility.toLowerCase() ||
              rowFacilityPadded.toLowerCase() == _facility.toLowerCase();
          if (!sameFacility) return false;
          return matchesHour(r['start_time']?.toString() ?? '');
        }).toList();

        if (matchingBookings.isEmpty && matchingSlots.isEmpty) {
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
        } else if (matchingBookings.isNotEmpty) {
          final b = matchingBookings.first;
          final status = (b['status']?.toString() ?? '').toLowerCase();
          final isClosed =
              status.contains('closed') || status.contains('maintenance');

          final rawId = b['id']?.toString() ?? 'UNKNOWN';
          final safeId = rawId.length > 8
              ? rawId.substring(0, 8).toUpperCase()
              : rawId.toUpperCase();

          final rawAmt = b['total_amount'] ?? b['amount'];
          int safeAmt = 0;
          if (rawAmt != null) {
            if (rawAmt is num) {
              safeAmt = rawAmt.toInt();
            } else if (rawAmt is String) {
              safeAmt = double.tryParse(rawAmt)?.toInt() ?? 0;
            }
          }

          fetchedSlots.add(
            _Slot(
              start: DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                hour,
              ),
              status: isClosed ? _SlotStatus.closed : _SlotStatus.reserved,
              closureReason: isClosed
                  ? status
                        .replaceAll('closed', '')
                        .replaceAll('(', '')
                        .replaceAll(')', '')
                        .trim()
                  : null,
              bookings: isClosed
                  ? []
                  : [
                      _DemoBooking(
                        id: safeId,
                        amount: safeAmt,
                        paid:
                            status == 'paid' ||
                            status == 'confirmed' ||
                            status == 'booked',
                      ),
                    ],
            ),
          );
        } else {
          final slotRow = matchingSlots.first;
          final slotStatus =
              (slotRow['status']?.toString() ?? 'reserved').toLowerCase();
          final refId =
              '${slotRow['facility_name'] ?? _facility}-$str12';
          final safeId = refId.length > 12
              ? refId.substring(0, 12).toUpperCase()
              : refId.toUpperCase();

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
              bookings: [
                _DemoBooking(
                  id: safeId,
                  amount: 0,
                  paid:
                      slotStatus == 'paid' ||
                      slotStatus == 'confirmed' ||
                      slotStatus == 'booked',
                ),
              ],
            ),
          );
        }
      }

      setState(() {
        _liveSlots = fetchedSlots;
        _selected.clear();
      });
    } catch (e) {
      debugPrint('Error fetching slots: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 SAFELY FETCH IDS INSTEAD OF USING ILIKE
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
                'This will write directly to the live database and block students from booking these times.',
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
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final records = await supabase
          .from('bookings')
          .select('id, start_time, status')
          .eq('facility_name', _facility)
          .eq('booking_date', dateStr);

      for (final slot in targets) {
        final hour12 = slot.start.hour > 12
            ? slot.start.hour - 12
            : (slot.start.hour == 0 ? 12 : slot.start.hour);
        final ampm = slot.start.hour >= 12 ? 'PM' : 'AM';
        final slotTime = '$hour12:00 $ampm';
        final hour24Padded = slot.start.hour.toString().padLeft(2, '0');

        if (slot.status == _SlotStatus.reserved) {
          bool updatedExisting = false;
          for (var record in records) {
            final st = record['start_time'].toString();
            if (st.contains('$hour24Padded:') || st.contains('$hour12:00')) {
              await supabase
                  .from('bookings')
                  .update({'status': 'Closed ($reason)'})
                  .eq('id', record['id']);
              updatedExisting = true;
            }
          }
          if (!updatedExisting) {
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
          }
        } else {
          // Open slot: insert a closure row so admin & student screens see it closed
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
        }
      }
      _message('Sessions successfully closed in live database.');
    } catch (e) {
      _message('Error closing sessions: $e');
    }

    _fetchLiveSlots();
  }

  // 🌟 SAFELY DELETE BY ID INSTEAD OF USING ILIKE
  Future<void> _reopen(_Slot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reopen session?'),
        content: const Text('This will remove the closure block from the database and allow students to book this slot again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep closed')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Reopen session')),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    setState(() => _isLoading = true);

    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      
      final records = await supabase.from('bookings').select('id, start_time, status')
        .eq('facility_name', _facility)
        .eq('booking_date', dateStr);

      for (var record in records) {
        final st = record['start_time'].toString();
        final stat = record['status'].toString().toLowerCase();
        
        final hour24Padded = slot.start.hour.toString().padLeft(2, '0');
        final hour12 = slot.start.hour > 12 ? slot.start.hour - 12 : (slot.start.hour == 0 ? 12 : slot.start.hour);

        if (stat.contains('closed') && (st.contains('$hour24Padded:') || st.contains('$hour12:00'))) {
           await supabase.from('bookings').delete().eq('id', record['id']);
        }
      }

      _message('Session reopened in live database.');
    } catch (e) {
      _message('Error reopening: $e');
    }

    _fetchLiveSlots();
  }

  String _money(int cents) => 'RM ${(cents / 100).toStringAsFixed(2)}';
  String _dateLabel(DateTime date) => '${date.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.year}';
  String _time(DateTime date) => '${date.hour % 12 == 0 ? 12 : date.hour % 12}:00 ${date.hour < 12 ? 'AM' : 'PM'}';
  String _timeRange(_Slot slot) => '${_time(slot.start)} - ${_time(slot.end)}';
  String _statusLabel(_Slot slot) {
    switch (slot.status) {
      case _SlotStatus.open: return 'Open';
      case _SlotStatus.reserved: return 'Reserved';
      case _SlotStatus.closed: return 'Closed by management';
    }
  }
  Color _statusColor(_Slot slot) {
    switch (slot.status) {
      case _SlotStatus.open: return Colors.green.shade800;
      case _SlotStatus.reserved: return Colors.blue.shade800;
      case _SlotStatus.closed: return Colors.grey.shade700;
    }
  }
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

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
            if (slot.closureReason != null) Text('Closure reason: ${slot.closureReason}'),
            const Divider(height: 24),
            if (slot.bookings.isEmpty) const Text('No demo bookings for this session.'),
            ...slot.bookings.map((booking) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('${booking.id}\n${booking.cancelled ? 'Cancelled by management' : 'Active reservation'}\n${booking.paid ? 'Paid' : 'Unpaid'} · ${_money(booking.amount)}'))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ),
    );
  }

  _selectDate(BuildContext context) async {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(_timeRange(slot), style: const TextStyle(fontWeight: FontWeight.bold))),
                  Checkbox(
                    value: _selected.contains(slot),
                    onChanged: past || closed ? null : (checked) {
                      setState(() { if (checked == true) _selected.add(slot); else _selected.remove(slot); });
                    },
                  ),
                ],
              ),
              Text(_statusLabel(slot), style: TextStyle(color: _statusColor(slot), fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                past ? 'Session ended' : closed ? 'Reason: ${slot.closureReason}' : reserved ? 'Demo booking · ${slot.activeBookings.first.paid ? 'Paid' : 'Unpaid'}' : 'Available for booking',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!past) OutlinedButton(onPressed: closed ? () => _reopen(slot) : () => _reviewClosure([slot]), child: Text(closed ? 'Reopen' : reserved ? 'Review closure' : 'Close session')),
                  TextButton(onPressed: () => _viewDetails(slot), child: const Text('View details')),
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
          const Text('AVAILABILITY CONTROL', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Manage slots', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _green)),
          const SizedBox(height: 8),
          const Text('Review the booking impact before closing a session.'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFEAF2EE), borderRadius: BorderRadius.circular(12)),
            child: const Text(
              'UI DEMO · Changes stay in this screen while it is mounted. Restarting resets them. Student bookings, Refund Management and notifications are not connected yet.',
              style: TextStyle(color: _green),
            ),
          ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAF8), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFDCE4DF))),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Date: ${_dateLabel(_selectedDate)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C3E34))), const Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey)]),
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 0, width: isMobile ? 0 : 16),
                  Expanded(
                    flex: isMobile ? 0 : 2,
                    child: DropdownButtonFormField<String>(
                      value: _facility,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Facility', border: OutlineInputBorder()),
                      items: _facilities.map((facility) => DropdownMenuItem(value: facility, child: Text(facility))).toList(),
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
            }
          ),
          const SizedBox(height: 16),
          
          const Text('Reserved sessions can be closed by management after review. Eligible paid bookings require a refund; unpaid bookings do not.', style: TextStyle(color: _green)),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _selected.isEmpty ? null : () => _reviewClosure(_selected.toList()),
                icon: const Icon(Icons.event_busy_outlined),
                label: Text('Review selected (${_selected.length})'),
              ),
              TextButton(
                onPressed: () => setState(() { _selected..clear()..addAll(_liveSlots.where((slot) => !slot.hasEnded && slot.status != _SlotStatus.closed)); }),
                child: const Text('Select available and reserved sessions'),
              ),
              if (_selected.isNotEmpty) TextButton(onPressed: () => setState(_selected.clear), child: const Text('Clear selection')),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Each session is one hour. Break periods are excluded. Demo reservations are shown at 8 PM and 9 PM.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          
          _isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: _green)))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1000 ? 3 : constraints.maxWidth >= 650 ? 2 : 1;
                  final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(spacing: 12, runSpacing: 12, children: _liveSlots.map((slot) => _slotCard(slot, width)).toList());
                },
              ),
        ],
      ),
    );
  }
}