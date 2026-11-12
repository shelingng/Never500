import 'package:flutter/material.dart';

class AdminRefundsTab extends StatefulWidget {
  const AdminRefundsTab({super.key});
  @override
  State<AdminRefundsTab> createState() => _AdminRefundsTabState();
}

class _AdminRefundsTabState extends State<AdminRefundsTab> {
  static const _green = Color(0xFF173F32);
  final _search = TextEditingController();
  String _filter = 'All';
  final List<_DisruptionRefund> _records = [
    _DisruptionRefund(
      id: 'DEMO-RF-003',
      booking: 'DEMO-1842',
      student: 'Sample Student A',
      facility: 'Badminton Court 01',
      session: '14 Nov 2026 · 8:00 PM–9:00 PM',
      reason: 'Facility closed by KRP Management for maintenance.',
      amount: 600,
      status: 'Awaiting action',
    ),
    _DisruptionRefund(
      id: 'DEMO-RF-002',
      booking: 'DEMO-1841',
      student: 'Sample Student B',
      facility: 'Ping Pong Table 02',
      session: '14 Nov 2026 · 6:00 PM–7:00 PM',
      reason: 'Facility made unavailable by KRP Management for an event.',
      amount: 600,
      status: 'Processing',
    ),
    _DisruptionRefund(
      id: 'DEMO-RF-001',
      booking: 'DEMO-1839',
      student: 'Sample Student D',
      facility: 'Dart Board',
      session: '15 Nov 2026 · 10:00 PM–11:00 PM',
      reason: 'Session cancelled by KRP Management for a safety inspection.',
      amount: 300,
      status: 'Refunded',
    ),
  ];

  List<_DisruptionRefund> get _visible {
    final query = _search.text.trim().toLowerCase();
    return _records.where((r) {
      return (_filter == 'All' || r.status == _filter) &&
          '${r.id} ${r.booking} ${r.student} ${r.facility}'
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _money(int cents) => 'RM ${(cents / 100).toStringAsFixed(2)}';

  Widget _badge(String status) {
    final color = switch (status) {
      'Refunded' => const Color(0xFF237346),
      'Failed' => const Color(0xFFB13D35),
      'Processing' => const Color(0xFF2665A6),
      _ => const Color(0xFF946000),
    };
    return Chip(
      label: Text(status, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withAlpha(22),
      side: BorderSide.none,
    );
  }

  void _details(_DisruptionRefund r) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(r.id),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking: ${r.booking}'),
                Text('Student: ${r.student}'),
                Text('Facility: ${r.facility}'),
                Text(r.session),
                const Divider(height: 28),
                const Text(
                  'Management disruption reason',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(r.reason),
                const SizedBox(height: 14),
                const Text('Initiated by: KRP Management (demo)'),
                const Text('Booking status: Cancelled by management'),
                Text('Original payment: ${_money(r.amount)}'),
                Text(
                  'Payment status: ${r.status == 'Refunded' ? 'Refunded' : 'Paid'}',
                ),
                Text('Refund amount: ${_money(r.amount)}'),
                Text('Refund status: ${r.status}'),
                const Divider(height: 28),
                const Text(
                  'Demo activity history',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...r.history.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(entry),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No bank transaction or student notification is sent. '
                  'History uses this device’s local time.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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

  Future<void> _transition(_DisruptionRefund r, String next) async {
    final previous = r.status;
    final allowed = switch (previous) {
      'Awaiting action' => next == 'Processing',
      'Processing' => next == 'Refunded' || next == 'Failed',
      'Failed' => next == 'Processing',
      _ => false,
    };
    if (!allowed) return;
    final note = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RefundSimulationDialog(
        id: r.id,
        next: next,
        amount: _money(r.amount),
        reason: r.reason,
      ),
    );
    if (!mounted || note == null || r.status != previous) return;
    setState(() {
      r.status = next;
      final now = DateTime.now();
      final stamp =
          '${now.day}/${now.month}/${now.year} '
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}';
      r.history.add(
        '$stamp · Demo admin: $previous → $next'
        '${note.isEmpty ? '' : '\n$note'}',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Demo status: $next. No money transferred or notification sent.',
        ),
      ),
    );
  }

  Widget _actions(_DisruptionRefund r) {
    final buttons = <Widget>[
      OutlinedButton(
        onPressed: () => _details(r),
        child: const Text('Details / History'),
      ),
    ];
    void add(String label, String next) => buttons.add(
      FilledButton(onPressed: () => _transition(r, next), child: Text(label)),
    );
    switch (r.status) {
      case 'Awaiting action':
        add('Simulate initiating refund', 'Processing');
        break;
      case 'Processing':
        add('Simulate completion', 'Refunded');
        add('Simulate failure', 'Failed');
        break;
      case 'Failed':
        add('Simulate retry', 'Processing');
        break;
    }
    return Wrap(spacing: 10, runSpacing: 10, children: buttons);
  }

  Widget _summary(String title, String value) => Container(
    width: 210,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E8E3)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _green,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final total = _records
        .where((r) => r.status == 'Refunded')
        .fold<int>(0, (sum, r) => sum + r.amount);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAYMENT OPERATIONS',
            style: TextStyle(
              color: _green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Refund Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Management-initiated refunds for affected paid bookings.',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Students cannot cancel bookings or submit refund requests. '
              'KRP Management handles eligible refunds for facility closures, maintenance '
              'or other management unavailability.\n\n'
              'Demo only: these affected bookings are sample records. Slot closures do not '
              'create these records automatically yet. No bank transactions, notifications '
              'or cross-page updates occur. Changes reset when the app restarts.',
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summary(
                'Awaiting admin action',
                '${_records.where((r) => r.status == 'Awaiting action').length}',
              ),
              _summary(
                'Processing',
                '${_records.where((r) => r.status == 'Processing').length}',
              ),
              _summary('Demo total refunded', _money(total)),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Search refunds',
              hintText: 'Refund ID, booking, student or facility',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 230,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_filter),
                  initialValue: _filter,
                  decoration: const InputDecoration(
                    labelText: 'Refund status',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                            'All',
                            'Awaiting action',
                            'Processing',
                            'Refunded',
                            'Failed',
                          ]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (s) {
                    if (s != null) setState(() => _filter = s);
                  },
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _search.clear();
                  _filter = 'All';
                }),
                child: const Text('Clear filters'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('${visible.length} management refund record(s)'),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text('No refunds match your filters.'),
            ),
          ...visible.map(
            (r) => Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          r.id,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _badge(r.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('${r.student} · ${r.booking}'),
                    Text(r.facility),
                    Text(r.session),
                    const SizedBox(height: 10),
                    Text('Management reason: ${r.reason}'),
                    const SizedBox(height: 10),
                    Text(
                      'Refund: ${_money(r.amount)}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: _green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Booking: Cancelled by management'),
                    Text(
                      'Payment: ${r.status == 'Refunded' ? 'Refunded' : 'Paid'}',
                    ),
                    const SizedBox(height: 16),
                    _actions(r),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisruptionRefund {
  final String id, booking, student, facility, session, reason;
  final int amount;
  String status;
  final List<String> history;
  _DisruptionRefund({
    required this.id,
    required this.booking,
    required this.student,
    required this.facility,
    required this.session,
    required this.reason,
    required this.amount,
    required this.status,
  }) : history = [
         'Sample affected paid booking loaded. Refund status: $status.',
       ];
}

class _RefundSimulationDialog extends StatefulWidget {
  final String id, next, amount, reason;
  const _RefundSimulationDialog({
    required this.id,
    required this.next,
    required this.amount,
    required this.reason,
  });
  @override
  State<_RefundSimulationDialog> createState() =>
      _RefundSimulationDialogState();
}

class _RefundSimulationDialogState extends State<_RefundSimulationDialog> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.next} · ${widget.id}'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount: ${widget.amount}'),
              const SizedBox(height: 12),
              Text('Management reason: ${widget.reason}'),
              const SizedBox(height: 12),
              const Text(
                'This simulates a management refund. No actual money is moved.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: widget.next == 'Failed'
                      ? 'Failure reason (required)'
                      : 'Admin note',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    widget.next == 'Failed' &&
                        (value == null || value.trim().isEmpty)
                    ? 'Enter a failure reason.'
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Back'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _note.text.trim());
          }
        },
        child: const Text('Confirm simulation'),
      ),
    ],
  );
}
