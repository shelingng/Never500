import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/booking_order.dart';
import '../services/booking_service.dart';

// SCRUM-48: the student's saved booking history, loaded from Supabase so it is
// the same on every device. Used by Profile > My bookings and Booking Records.

const _green = Color(0xFF1A332C);
const _lime = Color(0xFFC5F84B);
const _muted = Color(0xFF66756D);
const _divider = Color(0xFFE2E9E4);

class BookingHistoryView extends StatefulWidget {
  final BookingService? service;

  /// Overridable for tests; real use is the current time.
  final DateTime Function()? clock;

  const BookingHistoryView({super.key, this.service, this.clock});

  @override
  State<BookingHistoryView> createState() => _BookingHistoryViewState();
}

class _BookingHistoryViewState extends State<BookingHistoryView> {
  late final BookingService _service = widget.service ?? BookingService();
  List<BookingOrder>? _orders;
  String? _error;
  bool _loading = true;
  OrderGroup? _selected;

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _service.getMyOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
        // Open the first tab that has something in it.
        _selected ??= OrderGroup.values.firstWhere(
          (g) => orders.any((o) => o.groupAt(_now) == g),
          orElse: () => OrderGroup.upcoming,
        );
      });
    } catch (error) {
      debugPrint('Booking history failed: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Your bookings could not be loaded. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: _green),
              SizedBox(height: 12),
              Text('Loading your bookings...', style: TextStyle(color: _muted)),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return _message(
        Icons.cloud_off_outlined,
        'Something went wrong',
        _error!,
        action: OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Try again'),
        ),
      );
    }

    final now = _now;
    final orders = _orders ?? const <BookingOrder>[];
    final selected = _selected ?? OrderGroup.upcoming;
    final shown = orders.where((o) => o.groupAt(now) == selected).toList();
    if (selected == OrderGroup.upcoming || selected == OrderGroup.pending) {
      // Soonest first for things still to come; newest first otherwise.
      shown.sort((a, b) => _firstStart(a).compareTo(_firstStart(b)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              // Wraps on narrow screens so every tab stays visible.
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final group in OrderGroup.values)
                    ChoiceChip(
                      label: Text(
                        '${_groupTitle(group)} '
                        '(${orders.where((o) => o.groupAt(now) == group).length})',
                      ),
                      selected: selected == group,
                      selectedColor: _lime,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: _divider),
                      labelStyle: TextStyle(
                        color: _green,
                        fontWeight: selected == group
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _selected = group),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: _green),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          _message(
            Icons.calendar_month_outlined,
            _emptyTitle(selected),
            _emptySubtitle(selected),
          )
        else
          for (final order in shown) _orderCard(order, now),
      ],
    );
  }

  DateTime _firstStart(BookingOrder order) => order.sessions.isEmpty
      ? (order.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
      : order.sessions.first.startsAt;

  String _groupTitle(OrderGroup group) => switch (group) {
    OrderGroup.upcoming => 'Upcoming',
    OrderGroup.pending => 'Pending payment',
    OrderGroup.past => 'Past',
    OrderGroup.cancelled => 'Cancelled',
  };

  String _emptyTitle(OrderGroup group) => switch (group) {
    OrderGroup.upcoming => 'No upcoming bookings',
    OrderGroup.pending => 'Nothing waiting for payment',
    OrderGroup.past => 'No past bookings',
    OrderGroup.cancelled => 'No cancelled bookings',
  };

  String _emptySubtitle(OrderGroup group) => switch (group) {
    OrderGroup.upcoming => 'Paid bookings you have not played yet appear here.',
    OrderGroup.pending =>
      'Reserved slots you still need to pay for appear here.',
    OrderGroup.past => 'Bookings you have already played appear here.',
    OrderGroup.cancelled =>
      'Expired, closed and refunded bookings appear here.',
  };

  (Color, Color) _badgeColors(OrderGroup group) => switch (group) {
    OrderGroup.upcoming => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
    OrderGroup.pending => (const Color(0xFFFFF8E6), const Color(0xFF8A6100)),
    OrderGroup.past => (const Color(0xFFF0F2F1), _muted),
    OrderGroup.cancelled => (const Color(0xFFFDECEC), const Color(0xFFC62828)),
  };

  Widget _orderCard(BookingOrder order, DateTime now) {
    final group = order.groupAt(now);
    final (badgeBg, badgeFg) = _badgeColors(group);
    final payment = order.settledPayment;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusLabelAt(now),
                  style: TextStyle(
                    color: badgeFg,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formatRinggit(order.total),
                style: const TextStyle(
                  color: _green,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: order.reference));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking reference copied')),
              );
            },
            child: Text(
              order.reference,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            order.sessions.length == 1
                ? '1 session'
                : '${order.sessions.length} sessions',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          for (final session in order.sessions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule, size: 15, color: _green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${session.facilityName} · ${formatKlDate(session.date)} · ${session.interval} · ${session.sessionStatusLabel}',
                      style: const TextStyle(
                        color: _green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formatRinggit(session.price),
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          const Divider(height: 22, color: _divider),
          ..._paymentLines(order, payment, now),
        ],
      ),
    );
  }

  List<Widget> _paymentLines(
    BookingOrder order,
    OrderPayment? payment,
    DateTime now,
  ) {
    Widget line(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(text, style: const TextStyle(color: _muted, fontSize: 12)),
    );

    if (payment != null && payment.isDemo) {
      return [line('Demo payment. No money was charged.')];
    }
    if (payment != null) {
      return [
        line('Paid ${formatRinggit(payment.amount)} by ${payment.methodLabel}'),
        if (payment.reference != null)
          line('Payment ref: ${payment.reference}'),
        if (payment.paidAt != null)
          line('Paid at: ${formatKlInstant(payment.paidAt!)}'),
      ];
    }
    if (order.holdActiveAt(now)) {
      return [
        line(
          'Not paid yet. Slots are held until '
          '${formatKlInstant(order.paymentDeadline!)}.',
        ),
      ];
    }
    return [line('No payment received.')];
  }

  Widget _message(
    IconData icon,
    String title,
    String subtitle, {
    Widget? action,
  }) => Container(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _divider),
    ),
    child: Column(
      children: [
        Icon(icon, size: 44, color: _muted),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _green,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted),
        ),
        if (action != null) ...[const SizedBox(height: 14), action],
      ],
    ),
  );
}
