import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef JsonMap = Map<String, dynamic>;

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
  bool _refundFetchInFlight = false;
  Timer? _refundRefreshTimer;
  String _selectedFilter = 'All';
  List<JsonMap> _refunds = [];

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

  Future<List<JsonMap>> _loadBookingsWithSlots() async {
    try {
      final rows = await supabase
          .from('bookings')
          .select(
            '*, booking_items(id, price, status, '
            'time_slots(id, status, slot_date, start_time, end_time, facilities(name)))',
          );
      return [for (final r in (rows as List)) JsonMap.from(r as Map)];
    } catch (_) {
      final rows = await supabase.from('bookings').select();
      return [for (final r in (rows as List)) JsonMap.from(r as Map)];
    }
  }

  Future<void> _insertRefundSafely(JsonMap basePayload) async {
    const candidateMethods = [
      'bank_transfer',
      'fpx',
      'touch_n_go_ewallet',
      'tng_ewallet',
      'cash',
      'manual',
      'other',
      null,
    ];

    Object? lastError;
    for (final method in candidateMethods) {
      try {
        final attempt = JsonMap.from(basePayload);
        attempt['refund_method'] = method;
        await supabase.from('refunds').insert(attempt);
        return;
      } catch (e) {
        lastError = e;
        if (!e.toString().toLowerCase().contains('refunds_refund_method_check')) {
          rethrow;
        }
      }
    }
    if (lastError != null) throw lastError;
  }

  bool _hasClosedSlot(JsonMap booking) {
    final items = booking['booking_items'];
    if (items is! List) return false;
    for (final rawItem in items) {
      if (rawItem is! Map) continue;
      final itemStatus = (rawItem['status'] ?? '').toString().trim().toLowerCase();
      if (itemStatus.startsWith('closed') || itemStatus.contains('maintenance')) {
        return true;
      }
      final slot = rawItem['time_slots'];
      if (slot is Map) {
        final slotStatus = (slot['status'] ?? '').toString().trim().toLowerCase();
        if (slotStatus.startsWith('closed') || slotStatus.contains('maintenance')) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _syncClosedBookingsToRefunds(List<JsonMap> allBookings) async {
    final existingRefunds = await supabase.from('refunds').select('booking_id');

    final refundedBookingIds = <String>{};
    for (final r in (existingRefunds as List)) {
      final bid = (r as Map)['booking_id']?.toString().trim();
      if (bid != null && bid.isNotEmpty) {
        refundedBookingIds.add(bid);
      }
    }

    for (final b in allBookings) {
      final status = (b['status'] ?? '').toString().trim().toLowerCase();
      final refCodeBooking =
          (b['booking_reference'] ?? '').toString().trim().toUpperCase();
      final bookingId = b['id']?.toString().trim() ?? '';
      if (bookingId.isEmpty) continue;

      final isEmptyAdminBlock = refCodeBooking.startsWith('ADMIN-');
      final isPaidOrConfirmed =
          status == 'confirmed' || status == 'paid' || status.startsWith('closed');
      final isClosedBooking =
          status.startsWith('closed') || (isPaidOrConfirmed && _hasClosedSlot(b));

      if (isClosedBooking &&
          !isEmptyAdminBlock &&
          !refundedBookingIds.contains(bookingId)) {
        final amount = _parseAmount(b['total_amount'] ?? b['amount']);
        final nowIso = DateTime.now().toIso8601String();
        final adminId = supabase.auth.currentUser?.id;
        final shortSuffix = bookingId.length >= 6
            ? bookingId.substring(0, 6).toUpperCase()
            : bookingId.toUpperCase();

        String? paymentId = b['payment_id']?.toString().trim();
        if (paymentId == null || paymentId.isEmpty) {
          try {
            final payRow = await supabase
                .from('payments')
                .select('id')
                .eq('booking_id', bookingId)
                .limit(1)
                .maybeSingle();
            paymentId = payRow?['id']?.toString().trim();
          } catch (_) {}
        }

        final payload = <String, dynamic>{
          'refund_reference': 'RF-$shortSuffix',
          'booking_id': bookingId,
          'amount': amount,
          'reason': 'Facility closed by KRP Management: Maintenance',
          'refund_channel': 'bank_transfer',
          'status': 'awaiting_action',
          if (paymentId != null && paymentId.isNotEmpty)
            'payment_id': paymentId,
          if (adminId != null) 'processed_by': adminId,
          'created_at': nowIso,
          'updated_at': nowIso,
        };

        await _insertRefundSafely(payload);
        refundedBookingIds.add(bookingId);
      }
    }
  }

  JsonMap _extractBookingDetails(JsonMap? b, JsonMap profile, JsonMap refund) {
    JsonMap? firstCartItem;
    final rawPayload = b?['checkout_payload'];
    if (rawPayload is List &&
        rawPayload.isNotEmpty &&
        rawPayload.first is Map) {
      firstCartItem = JsonMap.from(rawPayload.first as Map);
    }

    String slotFacility = '';
    String slotDate = '';
    final slotTimes = <String>[];

    final rawItems = b?['booking_items'];
    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is! Map) continue;
        final slot = rawItem['time_slots'];
        if (slot is! Map) continue;
        final fac = slot['facilities'];
        if (slotFacility.isEmpty && fac is Map && fac['name'] != null) {
          slotFacility = fac['name'].toString().trim();
        }
        if (slotDate.isEmpty && slot['slot_date'] != null) {
          slotDate = slot['slot_date'].toString().trim();
        }
        if (slot['start_time'] != null) {
          slotTimes.add(slot['start_time'].toString().trim());
        }
      }
    }
    slotTimes.sort();

    final facility = (b?['facility_name'] ??
            firstCartItem?['facility_name'] ??
            (slotFacility.isNotEmpty ? slotFacility : null) ??
            refund['facility_name'] ??
            '')
        .toString()
        .trim();

    final date = (b?['booking_date'] ??
            firstCartItem?['booking_date'] ??
            firstCartItem?['date'] ??
            (slotDate.isNotEmpty ? slotDate : null) ??
            refund['booking_date'] ??
            '')
        .toString()
        .trim();

    String time = (b?['start_time'] ??
            firstCartItem?['start_time'] ??
            (slotTimes.isNotEmpty ? slotTimes.join(', ') : null) ??
            refund['start_time'] ??
            '')
        .toString()
        .trim();
    if (time.isEmpty &&
        firstCartItem?['start_times'] is List &&
        (firstCartItem!['start_times'] as List).isNotEmpty) {
      time = (firstCartItem['start_times'] as List).join(', ');
    }

    final studentName = (profile['full_name'] ??
            b?['student_name'] ??
            b?['full_name'] ??
            refund['student_name'] ??
            'Unknown Student')
        .toString()
        .trim();
    final matric = (profile['matric_number'] ??
            b?['matric_number'] ??
            refund['matric_number'] ??
            '')
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
      final bookingsRows = await _loadBookingsWithSlots();

      try {
        await _syncClosedBookingsToRefunds(bookingsRows);
      } catch (syncError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sync refund warning: $syncError')),
          );
        }
      }

      final rows = await supabase
          .from('refunds')
          .select()
          .order('created_at', ascending: false);

      final bookingById = <String, JsonMap>{};
      final userIds = <String>{};

      for (final b in bookingsRows) {
        final id = b['id']?.toString().trim() ?? '';
        if (id.isNotEmpty) bookingById[id] = b;

        final uid = (b['user_id'] ?? b['student_id'] ?? '').toString().trim();
        if (uid.isNotEmpty) userIds.add(uid);
      }

      for (final rawR in (rows as List)) {
        final r = rawR as Map;
        final uid = (r['user_id'] ?? r['student_id'] ?? '').toString().trim();
        if (uid.isNotEmpty) userIds.add(uid);
      }

      final profileById = <String, JsonMap>{};
      if (userIds.isNotEmpty) {
        try {
          final profRows = await supabase
              .from('profiles')
              .select('id, full_name, matric_number')
              .inFilter('id', userIds.toList());
          for (final rawP in (profRows as List)) {
            final p = JsonMap.from(rawP as Map);
            final pid = p['id']?.toString().trim() ?? '';
            if (pid.isNotEmpty) profileById[pid] = p;
          }
        } catch (_) {}
      }

      final enriched = (rows as List).map((rawR) {
        final r = JsonMap.from(rawR as Map);
        final bid = r['booking_id']?.toString().trim() ?? '';
        final b = bookingById[bid];
        final uid = (b?['user_id'] ??
                b?['student_id'] ??
                r['user_id'] ??
                r['student_id'] ??
                '')
            .toString()
            .trim();
        final profile = uid.isNotEmpty
            ? (profileById[uid] ?? <String, dynamic>{})
            : <String, dynamic>{};
        final details = _extractBookingDetails(b, profile, r);

        return <String, dynamic>{
          ...r,
          '_details': details,
        };
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

  Future<void> _updateStatus(JsonMap refund, String newStatus) async {
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
      final previousStatus = refund['status']?.toString();
      final nowIso = DateTime.now().toIso8601String();
      final adminId = supabase.auth.currentUser?.id;

      final updateMap = <String, dynamic>{
        'status': newStatus,
        'updated_at': nowIso,
        if (adminId != null) 'processed_by': adminId,
        if (newStatus == 'processing') 'initiated_at': nowIso,
        if (newStatus == 'refunded') ...{
          'manual_remark': manualRemark,
          'completed_at': nowIso,
        },
        if (newStatus == 'failed') 'failure_reason': failureReason,
      };

      await supabase.from('refunds').update(updateMap).eq('id', id);

      final bookingId = refund['booking_id']?.toString().trim();
      if (newStatus == 'refunded' &&
          bookingId != null &&
          bookingId.isNotEmpty) {
        try {
          final existingBooking = await supabase
              .from('bookings')
              .select('status')
              .eq('id', bookingId)
              .maybeSingle();
          final currentBookingStatus = (existingBooking?['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          final isAlreadyClosed =
              currentBookingStatus.contains('closed') ||
              currentBookingStatus.contains('maintenance');

          if (!isAlreadyClosed) {
            await supabase
                .from('bookings')
                .update({'status': 'Refunded'})
                .eq('id', bookingId);
          }
        } catch (_) {}
      }

      try {
        await supabase.from('refund_events').insert({
          'refund_id': id.toString(),
          'event_type': 'status_updated',
          'previous_status': previousStatus,
          'new_status': newStatus,
          'note':
              manualRemark ??
              failureReason ??
              'Refund status changed to $newStatus by admin',
          if (adminId != null) 'performed_by': adminId,
        });
      } catch (_) {}

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

  List<JsonMap> _getFilteredRefunds() {
    if (_selectedFilter == 'All') return _refunds;
    final target = _selectedFilter.toLowerCase().replaceAll(' ', '_');
    return _refunds.where((r) {
      final st = (r['status'] ?? '').toString().trim().toLowerCase();
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
            ...visibleList.map((refund) {
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
                  ? JsonMap.from(refund['_details'] as Map)
                  : <String, dynamic>{};

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