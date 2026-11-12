import 'package:flutter/material.dart';

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

  _Slot({required this.start, required this.status, required this.bookings});

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

  final Map<String, List<_Slot>> _sessions = {};
  final Set<_Slot> _selected = {};

  late final List<DateTime> _dates;

  int _dateIndex = 0;
  String _facility = _facilities.first;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _dates = List.generate(
      7,
      (index) => DateTime(now.year, now.month, now.day + index),
    );
  }

  String get _sessionKey =>
      '$_facility|${_dates[_dateIndex].toIso8601String()}';

  int get _demoPrice {
    if (_facility.startsWith('Badminton')) return 600;
    if (_facility.startsWith('Ping Pong')) return 400;
    if (_facility == 'Snooker Table') return 1000;
    if (_facility == 'Dart Board') return 300;
    return 200;
  }

  String _money(int cents) => 'RM ${(cents / 100).toStringAsFixed(2)}';

  String _dateLabel(DateTime date) {
    const months = [
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:00 ${date.hour < 12 ? 'AM' : 'PM'}';
  }

  String _timeRange(_Slot slot) => '${_time(slot.start)} - ${_time(slot.end)}';

  List<_Slot> get _slots {
    return _sessions.putIfAbsent(_sessionKey, () {
      final date = _dates[_dateIndex];
      final weekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

      final hours = weekend
          ? [10, 11, 12, 14, 15, 16, 17, 18, 20, 21, 22]
          : [17, 18, 20, 21, 22];

      return hours.map((hour) {
        // Local fixtures only:
        // 8 PM demonstrates a paid reservation.
        // 9 PM demonstrates an unpaid reservation.
        final reserved = hour == 20 || hour == 21;

        return _Slot(
          start: DateTime(date.year, date.month, date.day, hour),
          status: reserved ? _SlotStatus.reserved : _SlotStatus.open,
          bookings: reserved
              ? [
                  _DemoBooking(
                    id:
                        'DEMO-${_facilities.indexOf(_facility) + 1}'
                        '-${date.month}${date.day}-$hour',
                    amount: _demoPrice,
                    paid: hour == 20,
                  ),
                ]
              : [],
        );
      }).toList();
    });
  }

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

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _reviewClosure(List<_Slot> requested) async {
    final targets = requested
        .where((slot) => !slot.hasEnded && slot.status != _SlotStatus.closed)
        .toList();

    if (targets.isEmpty) {
      _message('Select an open or reserved session first.');
      return;
    }

    final affected = targets.expand((slot) => slot.activeBookings).toList();

    final paid = affected.where((booking) => booking.paid).toList();

    final refundTotal = paid.fold<int>(
      0,
      (total, booking) => total + booking.amount,
    );

    String reason = _reasons.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Review closure'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _facility,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_dateLabel(_dates[_dateIndex])),
                  const SizedBox(height: 12),
                  ...targets.map(
                    (slot) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('${_timeRange(slot)}: ${_statusLabel(slot)}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: reason,
                    isExpanded: true,
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
                  Text('Sessions to close: ${targets.length}'),
                  Text('Affected demo bookings: ${affected.length}'),
                  Text('Paid bookings: ${paid.length}'),
                  Text(
                    'Refund preview: ${_money(refundTotal)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (affected.isNotEmpty) ...[
                    const Divider(height: 28),
                    const Text(
                      'Affected bookings',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...affected.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${booking.id}\n'
                          '${booking.paid ? 'Paid' : 'Unpaid'}'
                          ' · ${_money(booking.amount)}',
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 28),
                  const Text(
                    'Confirming closes these sessions in this demo and '
                    'marks their active demo bookings as cancelled by '
                    'management. Unpaid bookings have no refund.',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'In the connected app, eligible paid booking items '
                    'would enter Refund Management as Awaiting action. '
                    'This preview does not create shared refund records, '
                    'send notifications or transfer money.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Simulate closure'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      for (final slot in targets) {
        slot.status = _SlotStatus.closed;
        slot.closureReason = reason;

        for (final booking in slot.activeBookings) {
          booking.cancelled = true;
        }
      }

      _selected.clear();
    });

    _message(
      'Demo: ${targets.length} session(s) closed. '
      '${affected.length} booking(s) cancelled. '
      'Would queue ${_money(refundTotal)} for refund.',
    );
  }

  Future<void> _reopen(_Slot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reopen session?'),
        content: Text(
          '$_facility\n'
          '${_dateLabel(slot.start)}\n'
          '${_timeRange(slot)}\n\n'
          'This makes the session available for new bookings in the demo. '
          'Previously cancelled bookings remain cancelled. '
          'Reopening does not reverse refunds.',
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

    setState(() {
      slot.status = _SlotStatus.open;
      slot.closureReason = null;
    });

    _message('Demo session reopened. Cancelled bookings remain cancelled.');
  }

  void _viewDetails(_Slot slot) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Session details'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
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
                  const Text('No demo bookings for this session.'),
                ...slot.bookings.map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${booking.id}\n'
                      '${booking.cancelled ? 'Cancelled by management' : 'Active reservation'}\n'
                      '${booking.paid ? 'Paid' : 'Unpaid'}'
                      ' · ${_money(booking.amount)}',
                    ),
                  ),
                ),
                const Text(
                  'Sample records only. No live booking data is loaded.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
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
                    ? 'Demo booking · '
                          '${slot.activeBookings.first.paid ? 'Paid' : 'Unpaid'}'
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
    final slots = _slots;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'UI DEMO · Changes stay in this screen while it is mounted. '
              'Restarting resets them. Student bookings, Refund Management '
              'and notifications are not connected yet.',
              style: TextStyle(color: _green),
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_dates.length, (index) {
                const weekdays = [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ];

                final date = _dates[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      '${weekdays[date.weekday - 1]}\n${_dateLabel(date)}',
                    ),
                    selected: index == _dateIndex,
                    onSelected: (_) {
                      setState(() {
                        _dateIndex = index;
                        _selected.clear();
                      });
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _facility,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Facility',
              border: OutlineInputBorder(),
            ),
            items: _facilities
                .map(
                  (facility) =>
                      DropdownMenuItem(value: facility, child: Text(facility)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _facility = value;
                _selected.clear();
              });
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Reserved sessions can be closed by management after review. '
            'Eligible paid bookings require a refund; unpaid bookings do not.',
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
                onPressed: () {
                  setState(() {
                    _selected
                      ..clear()
                      ..addAll(
                        slots.where(
                          (slot) =>
                              !slot.hasEnded &&
                              slot.status != _SlotStatus.closed,
                        ),
                      );
                  });
                },
                child: const Text('Select available and reserved sessions'),
              ),
              if (_selected.isNotEmpty)
                TextButton(
                  onPressed: () => setState(_selected.clear),
                  child: const Text('Clear selection'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Each session is one hour. Break periods are excluded. '
            'Demo reservations are shown at 8 PM and 9 PM.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
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
                children: slots.map((slot) => _slotCard(slot, width)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
