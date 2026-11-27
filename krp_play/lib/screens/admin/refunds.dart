import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRefundsTab extends StatefulWidget {
  const AdminRefundsTab({super.key});

  @override
  State<AdminRefundsTab> createState() => _AdminRefundsTabState();
}

class _AdminRefundsTabState extends State<AdminRefundsTab> {
  static const _green = Color(0xFF173F32);
  static const _lime = Color(0xFFD2F865);
  static const _bgLight = Color(0xFFF7F9F7);
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  String _selectedFilter = 'All';
  List _refunds = [];
  Timer? _refundRefreshTimer;
  bool _refundFetchInFlight = false;

  @override
  void initState() {
    super.initState();
    _fetchRefunds();
    _refundRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_refundFetchInFlight) {
        _fetchRefunds(showLoader: false);
      }
    });
  }

  @override
  void dispose() {
    _refundRefreshTimer?.cancel();
    super.dispose();
  }

  double _parseAmount(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0;
  }

  Map _extractBookingDetails(Map? b, Map profile) {
    if (b == null) {
      return {
        'studentName': (profile['full_name'] ?? 'Unknown Student')
            .toString()
            .trim(),
        'matric': (profile['matric_number'] ?? '').toString().trim(),
        'facility': 'Unknown Facility',
        'date': '-',
        'time': '-',
      };
    }

    Map? firstCartItem;
    final rawPayload = b['checkout_payload'];
    if (rawPayload is List &&
        rawPayload.isNotEmpty &&
        rawPayload.first is Map) {
      firstCartItem = Map.from(rawPayload.first as Map);
    }

    final facility =
        (b['facility_name'] ?? firstCartItem?['facility_name'] ?? '')
            .toString()
            .trim();
    final date =
        (b['booking_date'] ??
                firstCartItem?['booking_date'] ??
                firstCartItem?['date'] ??
                '')
            .toString()
            .trim();
    String time = (b['start_time'] ?? firstCartItem?['start_time'] ?? '')
        .toString()
        .trim();
    if (time.isEmpty &&
        firstCartItem?['start_times'] is List &&
        (firstCartItem!['start_times'] as List).isNotEmpty) {
      time = (firstCartItem['start_times'] as List).join(', ');
    }

    final studentName =
        (profile['full_name'] ??
                b['student_name'] ??
                b['full_name'] ??
                'Unknown Student')
            .toString()
            .trim();
    final matric = (profile['matric_number'] ?? b['matric_number'] ?? '')
        .toString()
        .trim();

    return {
      'studentName': studentName.isNotEmpty ? studentName : 'Unknown Student',
      'matric': matric,
      'facility': facility.isNotEmpty ? facility : 'Unknown Facility',
      'date': date.isNotEmpty ? date : '-',
      'time': time.isNotEmpty ? time : '-',
    };
  }

  Future<void> _fetchRefunds({bool showLoader = true}) async {
    if (_refundFetchInFlight) return;
    _refundFetchInFlight = true;
    if (showLoader && mounted) setState(() => _isLoading = true);
    try {
      final rows = await supabase
          .from('refunds')
          .select(
            '*, booking_items(time_slots(slot_date,start_time,end_time,facilities(name)))',
          )
          .order('created_at', ascending: false);

      final bookingsRows = await supabase.from('bookings').select();
      final bookingById = <String, Map>{};
      final userIds = <String>{};

      for (final rawB in (bookingsRows as List)) {
        final b = Map.from(rawB as Map);
        final id = b['id']?.toString().trim() ?? '';
        if (id.isNotEmpty) bookingById[id] = b;

        final uid = (b['user_id'] ?? b['student_id'] ?? '').toString().trim();
        if (uid.isNotEmpty) userIds.add(uid);
      }

      final profileById = <String, Map>{};
      if (userIds.isNotEmpty) {
        try {
          final profRows = await supabase
              .from('profiles')
              .select('id, full_name, matric_number')
              .inFilter('id', userIds.toList());
          for (final rawP in (profRows as List)) {
            final p = Map.from(rawP as Map);
            final pid = p['id']?.toString().trim() ?? '';
            if (pid.isNotEmpty) profileById[pid] = p;
          }
        } catch (_) {}
      }

      final enriched = (rows as List).map((rawR) {
        final r = Map.from(rawR as Map);
        final bid = r['booking_id']?.toString().trim() ?? '';
        final b = bookingById[bid];
        final uid = b != null
            ? (b['user_id'] ?? b['student_id'] ?? '').toString().trim()
            : '';
        final profile = uid.isNotEmpty ? (profileById[uid] ?? {}) : {};
        final details = _extractBookingDetails(b, profile);
        final item = r['booking_items'] as Map?;
        final slot = item?['time_slots'] as Map?;
        if (slot != null) {
          details['facility'] =
              (slot['facilities'] as Map?)?['name'] ?? details['facility'];
          details['date'] = slot['slot_date']?.toString() ?? details['date'];
          details['time'] = '${slot['start_time']} - ${slot['end_time']}';
        }

        return {...r, '_details': details};
      }).toList();

      const priority = {
        'awaiting_action': 0,
        'processing': 1,
        'failed': 2,
        'refunded': 3,
      };
      enriched.sort((a, b) {
        final aStatus = a['status']?.toString().toLowerCase();
        final bStatus = b['status']?.toString().toLowerCase();
        final byStatus = (priority[aStatus] ?? 4).compareTo(
          priority[bStatus] ?? 4,
        );
        if (byStatus != 0) return byStatus;
        return (b['created_at'] ?? '').toString().compareTo(
          (a['created_at'] ?? '').toString(),
        );
      });
      if (mounted) {
        setState(() => _refunds = enriched);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading refunds: $e')));
      }
    } finally {
      _refundFetchInFlight = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _askTextInput({
    required String title,
    required String prompt,
    required String label,
    required String initialValue,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prompt, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 2,
              autofocus: true,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: _lime,
            ),
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isEmpty) return;
              Navigator.pop(ctx, trimmed);
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _updateStatus(Map refund, String newStatus) async {
    final id = refund['id'];
    if (id == null) return;

    final refCode = (refund['refund_reference'] ?? refund['id'] ?? 'REF')
        .toString();

    String? manualRemark;
    String? failureReason;

    if (newStatus == 'refunded') {
      manualRemark = await _askTextInput(
        title: 'Manual Completion Remark',
        prompt: 'Enter manual_remark before marking $refCode as Refunded:',
        label: 'Manual Remark',
        initialValue:
            (refund['manual_remark'] ?? 'Refunded manually via bank transfer')
                .toString(),
        confirmLabel: 'Confirm Refunded',
      );
      if (manualRemark == null || manualRemark.isEmpty) return;
    } else if (newStatus == 'failed') {
      failureReason = await _askTextInput(
        title: 'Failure Reason',
        prompt: 'Enter failure_reason for marking $refCode as Failed:',
        label: 'Failure Reason',
        initialValue:
            (refund['failure_reason'] ?? 'Transfer failed during processing')
                .toString(),
        confirmLabel: 'Confirm Failed',
      );
      if (failureReason == null || failureReason.isEmpty) return;
    }

    setState(() => _isLoading = true);
    try {
      // Database triggers save session state and audit history atomically.
      final previousStatus = refund['status']?.toString();
      final rows = await supabase
          .from('refunds')
          .update({
            'status': newStatus,
            if (newStatus == 'refunded') 'manual_remark': manualRemark,
            if (newStatus == 'failed') 'failure_reason': failureReason,
          })
          .eq('id', id)
          .eq('status', previousStatus ?? '')
          .select('id');
      if (rows.isEmpty) {
        throw StateError(
          'This refund changed in another window. Refresh and try again.',
        );
      }

      await _fetchRefunds();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Refund updated to "${_formatStatusLabel(newStatus)}".',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update refund: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'awaiting_action':
        return 'Awaiting Action';
      case 'processing':
        return 'Processing';
      case 'refunded':
        return 'Refunded';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  List _getFilteredRefunds() {
    if (_selectedFilter == 'All') return _refunds;
    final target = _selectedFilter.toLowerCase().replaceAll(' ', '_');
    return _refunds.where((raw) {
      final st = ((raw as Map)['status'] ?? '').toString().trim().toLowerCase();
      return st == target;
    }).toList();
  }

  Color _badgeBgColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'refunded':
        return const Color(0xFFE6F4EA);
      case 'processing':
        return const Color(0xFFE8F0FE);
      case 'failed':
        return const Color(0xFFFCE8E6);
      default:
        return const Color(0xFFFEF7E0);
    }
  }

  Color _badgeTextColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'refunded':
        return const Color(0xFF137333);
      case 'processing':
        return const Color(0xFF1967D2);
      case 'failed':
        return const Color(0xFFC5221F);
      default:
        return const Color(0xFF9A6700);
    }
  }

  Widget _detailCell(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _green),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A251E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleList = _getFilteredRefunds();
    const filters = [
      'All',
      'Awaiting Action',
      'Processing',
      'Refunded',
      'Failed',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REFUND & CANCELLATION QUEUE',
                      style: TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Refund Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _green,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review refunds triggered by closed sports sessions.',
                      style: TextStyle(fontSize: 13.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDCE4DF)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: _green),
                  onPressed: _fetchRefunds,
                  tooltip: 'Refresh refunds',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filters.map((f) {
              final active = _selectedFilter == f;
              return ChoiceChip(
                label: Text(f),
                selected: active,
                selectedColor: _green,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: active ? Colors.white : const Color(0xFF2C3E34),
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: active ? _green : const Color(0xFFDCE4DF),
                  ),
                ),
                onSelected: (_) => setState(() => _selectedFilter = f),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: _green),
              ),
            )
          else if (visibleList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8E3)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 36,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No refund records found.',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            )
          else
            ...visibleList.map((rawRefund) {
              final refund = rawRefund as Map;
              final refCode =
                  (refund['refund_reference'] ?? refund['id'] ?? 'REF')
                      .toString();
              final amountNum = _parseAmount(refund['amount']);
              final status = (refund['status'] ?? 'awaiting_action')
                  .toString()
                  .trim();
              final statusLower = status.toLowerCase();
              final reason = (refund['reason'] ?? '').toString();
              final manualRemark = (refund['manual_remark'] ?? '').toString();
              final failureReason = (refund['failure_reason'] ?? '').toString();
              final details = refund['_details'] is Map
                  ? Map.from(refund['_details'] as Map)
                  : {};

              final studentName = (details['studentName'] ?? 'Unknown Student')
                  .toString();
              final matric = (details['matric'] ?? '').toString();
              final studentDisplay = matric.isNotEmpty
                  ? '$studentName · $matric'
                  : studentName;
              final facility = (details['facility'] ?? 'Unknown Facility')
                  .toString();
              final dateBooked = (details['date'] ?? '-').toString();
              final timeBooked = (details['time'] ?? '-').toString();

              final isRefunded = statusLower == 'refunded';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8E3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              refCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: _green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _badgeBgColor(status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _formatStatusLabel(status),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _badgeTextColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _bgLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'RM ${amountNum.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _green,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _bgLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _detailCell(
                                  Icons.person_outline,
                                  'Student',
                                  studentDisplay,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _detailCell(
                                  Icons.sports_tennis_outlined,
                                  'Facility Booked',
                                  facility,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _detailCell(
                                  Icons.calendar_today_outlined,
                                  'Date Booked',
                                  dateBooked,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _detailCell(
                                  Icons.schedule_outlined,
                                  'Time Booked',
                                  timeBooked,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (reason.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        reason,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (manualRemark.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Remark: $manualRemark',
                        style: const TextStyle(
                          color: Color(0xFF137333),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (failureReason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Failure Reason: $failureReason',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (statusLower == 'awaiting_action')
                          OutlinedButton(
                            onPressed: () =>
                                _updateStatus(refund, 'processing'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1967D2),
                              side: const BorderSide(color: Color(0xFFD2E3FC)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Start Processing'),
                          ),
                        if (statusLower != 'failed' && !isRefunded)
                          TextButton(
                            onPressed: () => _updateStatus(refund, 'failed'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                            ),
                            child: const Text('Mark Failed'),
                          ),
                        FilledButton.icon(
                          onPressed: isRefunded
                              ? null
                              : () => _updateStatus(refund, 'refunded'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: _lime,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: Text(
                            isRefunded ? 'Refunded' : 'Mark Refunded',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
