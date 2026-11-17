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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 4),
                Text(r.reason),
                const SizedBox(height: 14),
                const Text('Initiated by: KRP Management (demo)'),
                const Text('Booking status: Cancelled by management'),
                Text('Original payment: ${_money(r.amount)}'),
                Text('Payment status: ${r.status == 'Refunded' ? 'Refunded' : 'Paid'}'),
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
                    child: Text(entry, style: const TextStyle(fontSize: 13)),
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
        content: Text('Demo status: $next. No money transferred or notification sent.'),
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
      FilledButton(onPressed: () => _transition(r, next), style: FilledButton.styleFrom(backgroundColor: _green), child: Text(label)),
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
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E8E3)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
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
      padding: const EdgeInsets.all(24),
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
              fontWeight: FontWeight.w900,
              color: _green,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Management-initiated refunds for affected paid bookings.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
              style: TextStyle(color: Color(0xFF705500)),
            ),
          ),
          const SizedBox(height: 24),

          // 🌟 Responsive 3-Column Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summary('AWAITING ADMIN ACTION', '${_records.where((r) => r.status == 'Awaiting action').length}'),
                    const SizedBox(height: 12),
                    _summary('PROCESSING', '${_records.where((r) => r.status == 'Processing').length}'),
                    const SizedBox(height: 12),
                    _summary('DEMO TOTAL REFUNDED', _money(total)),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: _summary('AWAITING ADMIN ACTION', '${_records.where((r) => r.status == 'Awaiting action').length}')),
                    const SizedBox(width: 16),
                    Expanded(child: _summary('PROCESSING', '${_records.where((r) => r.status == 'Processing').length}')),
                    const SizedBox(width: 16),
                    Expanded(child: _summary('DEMO TOTAL REFUNDED', _money(total))),
                  ],
                );
              }
            }
          ),
          
          const SizedBox(height: 32),
          
          // 🌟 Responsive Search & Filter Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              
              if (isMobile) {
                return Column(
                  children: [
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Search refunds',
                        hintText: 'Refund ID, booking, student...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(_filter),
                            initialValue: _filter,
                            decoration: InputDecoration(
                              labelText: 'Refund status',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: ['All', 'Awaiting action', 'Processing', 'Refunded', 'Failed']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (s) {
                              if (s != null) setState(() => _filter = s);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _search.clear();
                            _filter = 'All';
                          }),
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Search refunds',
                          hintText: 'Refund ID, booking, student or facility',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_filter),
                        initialValue: _filter,
                        decoration: InputDecoration(
                          labelText: 'Refund status',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['All', 'Awaiting action', 'Processing', 'Refunded', 'Failed']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (s) {
                          if (s != null) setState(() => _filter = s);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _search.clear();
                          _filter = 'All';
                        }),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                        icon: const Icon(Icons.filter_alt_off_outlined),
                        label: const Text('Clear filters', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              }
            }
          ),
          
          const SizedBox(height: 24),
          Text('${visible.length} management refund record(s)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text('No refunds match your filters.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ),
            
          // 🌟 Responsive 2-Column Grid for Refund Cards
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = constraints.maxWidth > 850 ? 2 : 1;
              double width = (constraints.maxWidth - ((columns - 1) * 16)) / columns;
              
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: visible.map((r) => SizedBox(
                  width: width,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade300)
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                r.id,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              _badge(r.status),
                            ],
                          ),
                          const Divider(height: 24),
                          Text('${r.student} · ${r.booking}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(r.facility, style: TextStyle(color: Colors.grey.shade700)),
                          Text(r.session, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                          
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('MANAGEMENT REASON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(r.reason, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Payment', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text(r.status == 'Refunded' ? 'Refunded' : 'Paid', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Refund Amount', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text(
                                    _money(r.amount),
                                    style: const TextStyle(fontSize: 18, color: _green, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          _actions(r),
                        ],
                      ),
                    ),
                  ),
                )).toList(),
              );
            },
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
  State<_RefundSimulationDialog> createState() => _RefundSimulationDialogState();
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
              Text('Amount: ${widget.amount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              const Text('Management reason:', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(widget.reason, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('This simulates a management refund. No actual money is moved.', style: TextStyle(fontSize: 12, color: Colors.orange))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: widget.next == 'Failed' ? 'Failure reason (required)' : 'Admin note',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => widget.next == 'Failed' && (value == null || value.trim().isEmpty) ? 'Enter a failure reason.' : null,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF173F32)),
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