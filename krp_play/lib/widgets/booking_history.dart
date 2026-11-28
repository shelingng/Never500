import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/booking_order.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/booking_service.dart';

// SCRUM-48: the student's saved booking history, loaded from Supabase so it is
// the same on every device. Used by Profile > My bookings and Booking Records.

const _green = Color(0xFF1A332C);
const _darkGreen = Color(0xFF103B2B);
const _lime = Color(0xFFC5F84B);
const _muted = Color(0xFF66756D);
const _divider = Color(0xFFE2E9E4);
const _softBg = Color(0xFFF5F8F6);

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class BookingHistoryView extends StatefulWidget {
  final BookingService? service;

  /// Overridable for tests; real use is the current time.
  final DateTime Function()? clock;

  /// Opens the Billplz page. Overridable for tests; real use opens a new tab.
  final Future<bool> Function(Uri url)? openUrl;

  const BookingHistoryView({
    super.key,
    this.service,
    this.clock,
    this.openUrl,
  });

  @override
  State<BookingHistoryView> createState() => _BookingHistoryViewState();
}

class _BookingHistoryViewState extends State<BookingHistoryView> {
  late final BookingService _service = widget.service ?? BookingService();
  List<BookingOrder>? _orders;
  String? _error;
  bool _loading = true;
  OrderGroup? _selected;

  /// Booking ids whose payment link is being fetched.
  final Set<String> _opening = {};

  Future<bool> _open(Uri url) =>
      (widget.openUrl ??
              (u) => launchUrl(
                u,
                mode: LaunchMode.externalApplication,
                webOnlyWindowName: '_blank',
              ))
          .call(url);

  // SCRUM-48 (S14): reopen the Billplz page for a booking that is still held.
  // The backend returns the existing bill if there is one, so paying again
  // never creates a second charge.
  Future<void> _payNow(BookingOrder order) async {
    if (_opening.contains(order.id)) return;
    setState(() => _opening.add(order.id));
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await _service.createBillplzPayment(order.id);
      final opened = await _open(Uri.parse(url));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Payment page opened. After paying, tap "I\'ve paid, check status".'
                : 'Could not open the payment page. Allow pop-ups and try again.',
          ),
        ),
      );
    } on PaymentException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      // The hold may have ended or the booking may already be paid.
      await _load();
    } catch (error) {
      debugPrint('Pay now failed: $error');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not start the payment. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening.remove(order.id));
    }
  }

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
        _header(orders, now),
        const SizedBox(height: 14),
        _groupTiles(orders, now, selected),
        const SizedBox(height: 16),
        if (shown.isEmpty)
          _message(
            _groupIcon(selected),
            _emptyTitle(selected),
            _emptySubtitle(selected),
          )
        else
          for (final order in shown) _orderCard(order, now),
      ],
    );
  }

  // ---------- Header ----------

  Widget _header(List<BookingOrder> orders, DateTime now) {
    final next = _nextSession(orders, now);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_darkGreen, Color(0xFF1F5A41)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEXT SESSION',
                  style: TextStyle(
                    color: _lime,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                if (next == null) ...[
                  const Text(
                    'Nothing booked yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your next paid session will show here.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(
                        _facilityIcon(next.facilityName),
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          next.facilityName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_dayLabel(next.date)} · ${next.interval}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Earliest paid session that has not ended yet.
  OrderSession? _nextSession(List<BookingOrder> orders, DateTime now) {
    OrderSession? next;
    for (final order in orders) {
      if (order.groupAt(now) != OrderGroup.upcoming) continue;
      for (final s in order.sessions) {
        if (s.isCancelled || !s.endsAt.isAfter(now.toUtc())) continue;
        if (next == null || s.startsAt.isBefore(next.startsAt)) next = s;
      }
    }
    return next;
  }

  // ---------- Filter tiles ----------

  Widget _groupTiles(
    List<BookingOrder> orders,
    DateTime now,
    OrderGroup selected,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final perRow = constraints.maxWidth >= 560 ? 4 : 2;
        final width = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final group in OrderGroup.values)
              SizedBox(
                width: width,
                child: _groupTile(
                  group,
                  orders.where((o) => o.groupAt(now) == group).length,
                  selected == group,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _groupTile(OrderGroup group, int count, bool isSelected) {
    final (tint, accent) = _badgeColors(group);
    return Material(
      key: ValueKey('tab-${group.name}'),
      color: isSelected ? _green : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selected = group),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? _green : _divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? _lime : tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _groupIcon(group),
                  size: 18,
                  color: isSelected ? _green : accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: isSelected ? Colors.white : _green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _groupTitle(group),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : _muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Labels ----------

  DateTime _firstStart(BookingOrder order) => order.sessions.isEmpty
      ? (order.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
      : order.sessions.first.startsAt;

  String _dayLabel(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${formatKlDate(date)}';

  String _groupTitle(OrderGroup group) => switch (group) {
    OrderGroup.upcoming => 'Upcoming',
    OrderGroup.pending => 'Pending payment',
    OrderGroup.past => 'Past',
    OrderGroup.cancelled => 'Cancelled',
  };

  IconData _groupIcon(OrderGroup group) => switch (group) {
    OrderGroup.upcoming => Icons.event_available,
    OrderGroup.pending => Icons.hourglass_top,
    OrderGroup.past => Icons.history,
    OrderGroup.cancelled => Icons.event_busy,
  };

  IconData _facilityIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('badminton')) return Icons.sports_tennis;
    if (n.contains('ping pong') || n.contains('table tennis')) {
      return Icons.sports_handball;
    }
    if (n.contains('snooker')) return Icons.sports_bar;
    if (n.contains('dart')) return Icons.adjust;
    if (n.contains('gym')) return Icons.fitness_center;
    return Icons.sports;
  }

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

  // ---------- Booking card ----------

  Widget _orderCard(BookingOrder order, DateTime now) {
    final group = order.groupAt(now);
    final (badgeBg, badgeFg) = _badgeColors(group);
    final facilities = {for (final s in order.sessions) s.facilityName};
    final title = facilities.isEmpty
        ? 'Booking'
        : facilities.length == 1
        ? facilities.first
        : '${facilities.length} facilities';
    final firstDate = order.sessions.isEmpty ? null : order.sessions.first.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: badgeFg),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row: icon, facility, date, amount and status.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            facilities.length == 1
                                ? _facilityIcon(facilities.first)
                                : Icons.sports,
                            color: badgeFg,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: _green,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 6,
                                children: [
                                  if (firstDate != null)
                                    Text(
                                      _dayLabel(firstDate),
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (firstDate != null)
                                    const Text(
                                      '·',
                                      style: TextStyle(color: _muted),
                                    ),
                                  Text(
                                    order.sessions.length == 1
                                        ? '1 session'
                                        : '${order.sessions.length} sessions',
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatRinggit(order.total),
                              style: const TextStyle(
                                color: _green,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Sessions.
                    for (final session in order.sessions)
                      _sessionRow(session, showFacility: facilities.length > 1),
                    if (order.holdActiveAt(now)) _holdNotice(order),
                    const SizedBox(height: 6),
                    const Divider(height: 18, color: _divider),
                    _footer(order, now),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionRow(OrderSession session, {required bool showFacility}) {
    final cancelled = session.isCancelled;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _softBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 16,
            color: cancelled ? const Color(0xFFC62828) : _green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showFacility
                      ? '${session.facilityName} · ${session.interval}'
                      : session.interval,
                  style: TextStyle(
                    color: _green,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: cancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '${_dayLabel(session.date)} · ${session.sessionStatusLabel}',
                  style: TextStyle(
                    color: cancelled ? const Color(0xFFC62828) : _muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatRinggit(session.price),
            style: const TextStyle(
              color: _green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _holdNotice(BookingOrder order) {
    const amber = Color(0xFF8A6100);
    final opening = _opening.contains(order.id);
    final deadline = formatKlInstant(order.paymentDeadline!);
    // "24 Nov 2026, 3:05 PM" -> "3:05 PM" for the heading.
    final deadlineTime = deadline.split(', ').last;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3DFA8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE9B3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_outlined, size: 18, color: amber),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pay before $deadlineTime',
                      style: const TextStyle(
                        color: amber,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Not paid yet. Slots are held until $deadline.',
                      style: const TextStyle(color: amber, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_service.usesRealPayment) ...[
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                key: ValueKey('pay-${order.id}'),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: _lime,
                  disabledBackgroundColor: _green.withValues(alpha: 0.6),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: opening ? null : () => _payNow(order),
                icon: opening
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      )
                    : const Icon(Icons.lock_outline, size: 18),
                label: Text(
                  opening
                      ? 'Opening...'
                      : 'Pay ${formatRinggit(order.total)} now',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                key: ValueKey('check-${order.id}'),
                style: TextButton.styleFrom(foregroundColor: _green),
                onPressed: opening ? null : _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text(
                  "I've paid, check status",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const Text(
              'Secure payment by Billplz (FPX). Opens in a new tab.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ] else
            const Text(
              'Online payment is not set up in this app run. '
              'Start the app with the payment backend to pay.',
              style: TextStyle(color: amber, fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _footer(BookingOrder order, DateTime now) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Tooltip(
          message: 'Tap to copy the full reference',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Clipboard.setData(ClipboardData(text: order.reference));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking reference copied')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _softBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                      size: 14, color: _muted),
                  const SizedBox(width: 6),
                  Text(
                    order.shortReference,
                    style: const TextStyle(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy, size: 13, color: _muted),
                ],
              ),
            ),
          ),
        ),
        _paymentSummary(order, now),
      ],
    );
  }

  Widget _paymentSummary(BookingOrder order, DateTime now) {
    final payment = order.settledPayment;
    String text;
    IconData icon;
    if (payment != null && payment.isDemo) {
      text = 'Demo payment. No money was charged.';
      icon = Icons.science_outlined;
    } else if (payment != null) {
      text = 'Paid ${formatRinggit(payment.amount)} by ${payment.methodLabel}'
          '${payment.paidAt != null ? ' · ${formatKlInstant(payment.paidAt!)}' : ''}';
      icon = Icons.verified_outlined;
    } else if (order.holdActiveAt(now)) {
      text = 'Payment pending';
      icon = Icons.payments_outlined;
    } else {
      text = 'No payment received.';
      icon = Icons.money_off_outlined;
    }
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _muted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text, style: const TextStyle(color: _muted, fontSize: 12)),
        ),
      ],
    );
    final ref = payment?.reference;
    if (ref == null || payment!.isDemo) return row;
    return Tooltip(message: 'Payment ref: $ref', child: row);
  }

  Widget _message(
    IconData icon,
    String title,
    String subtitle, {
    Widget? action,
  }) => Container(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _divider),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: _softBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 34, color: _muted),
        ),
        const SizedBox(height: 12),
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
