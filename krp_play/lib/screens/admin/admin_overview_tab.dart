import 'admin_metric_card.dart';
import 'refunds.dart';
import 'user_reports.dart';
import 'reservations.dart';
import 'package:flutter/material.dart';
import '../../models/student_category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOverviewTab extends StatefulWidget {
  final VoidCallback? onViewAllBookings;
  final VoidCallback? onViewReports;
  final ValueChanged<String>? onViewRefunds;

  const AdminOverviewTab({
    super.key,
    this.onViewAllBookings,
    this.onViewReports,
    this.onViewRefunds,
  });

  @override
  State<AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<AdminOverviewTab> {
  final supabase = Supabase.instance.client;
  String _selectedView = 'Daily';
  bool _isLoading = true;

  RealtimeChannel? _bookingSubscription;

  List<dynamic> _recentReservations = [];
  List<dynamic> _dashboardBookingRows = [];

  Map<String, Map<String, String>> _dashboardStats = {
    'Daily': {
      'bookings': '0',
      'revenue': 'RM 0',
      'active': '0',
      'reports': '0',
      'failed': '0',
    },
    'Weekly': {
      'bookings': '0',
      'revenue': 'RM 0',
      'active': '0',
      'reports': '0',
      'failed': '0',
    },
    'Monthly': {
      'bookings': '0',
      'revenue': 'RM 0',
      'active': '0',
      'reports': '0',
      'failed': '0',
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchOverviewData();
    _setupRealtime();
  }

  void _setupRealtime() {
    _bookingSubscription = supabase
        .channel('public:bookings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            if (mounted) {
              _fetchOverviewData();
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_bookingSubscription != null) {
      supabase.removeChannel(_bookingSubscription!);
    }
    super.dispose();
  }

  Future<void> _fetchOverviewData() async {
    setState(() => _isLoading = true);
    try {
      final allBookingsResp = await supabase
          .from('bookings')
          .select('*, profiles!booking_user_id_fkey(full_name, matric_number)');
      final List<dynamic> allBookings = List<dynamic>.from(allBookingsResp);

      allBookings.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime(2000);
        final dateB =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime(2000);
        return dateB.compareTo(dateA);
      });

      final List<dynamic> bookingRows = allBookings.where((b) {
        final status = (b['status']?.toString() ?? '').trim().toLowerCase();
        return !status.startsWith('closed');
      }).toList();

      final recentData = bookingRows.take(4).toList();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int dailyB = 0, weeklyB = 0, monthlyB = 0;
      int dailyR = 0, weeklyR = 0, monthlyR = 0;
      int dailyActive = 0, weeklyActive = 0, monthlyActive = 0;

      for (var b in bookingRows) {
        final status = (b['status']?.toString() ?? '').toLowerCase().trim();
        final isActive =
            status == 'confirmed' || status == 'paid' || status == 'booked';

        final rawPayload = b['checkout_payload'];
        Map<String, dynamic>? firstCartItem;
        if (rawPayload is List &&
            rawPayload.isNotEmpty &&
            rawPayload.first is Map) {
          firstCartItem = Map<String, dynamic>.from(rawPayload.first as Map);
        }

        final String dateString =
            (b['booking_date'] ??
                    firstCartItem?['booking_date'] ??
                    firstCartItem?['date'] ??
                    b['created_at'] ??
                    now)
                .toString();

        final bDateRaw = DateTime.tryParse(dateString) ?? now;
        final bDate = DateTime(bDateRaw.year, bDateRaw.month, bDateRaw.day);

        final rawAmount = b['total_amount'] ?? b['amount'];
        int amount = 0;
        if (rawAmount != null) {
          if (rawAmount is num) {
            amount = rawAmount.toInt();
          } else if (rawAmount is String) {
            amount = double.tryParse(rawAmount)?.toInt() ?? 0;
          }
        }

        final diffDays = bDate.difference(today).inDays.abs();

        if (diffDays == 0) {
          dailyB++;
          dailyR += amount;
          if (isActive) dailyActive++;
        }
        if (diffDays <= 7) {
          weeklyB++;
          weeklyR += amount;
          if (isActive) weeklyActive++;
        }
        if (diffDays <= 30) {
          monthlyB++;
          monthlyR += amount;
          if (isActive) monthlyActive++;
        }
      }

      int dailyRep = 0, weeklyRep = 0, monthlyRep = 0;
      try {
        final allReports = await supabase
            .from('reports')
            .select('status, created_at');
        for (var r in allReports) {
          final rStatus = (r['status']?.toString() ?? '').toLowerCase();
          if (rStatus == 'submitted' || rStatus == 'under review') {
            final rDateRaw =
                DateTime.tryParse(r['created_at']?.toString() ?? '') ?? now;
            final rDate = DateTime(rDateRaw.year, rDateRaw.month, rDateRaw.day);
            final diffDays = rDate.difference(today).inDays.abs();

            if (diffDays == 0) dailyRep++;
            if (diffDays <= 7) weeklyRep++;
            if (diffDays <= 30) monthlyRep++;
          }
        }
      } catch (_) {}

      int failedRefunds = 0;
      try {
        final failedRows = await supabase
            .from('refunds')
            .select('id, status')
            .eq('status', 'failed');
        failedRefunds = (failedRows as List).length;
      } catch (_) {}

      setState(() {
        _recentReservations = recentData;
        _dashboardBookingRows = bookingRows;
        _dashboardStats = {
          'Daily': {
            'bookings': '$dailyB',
            'revenue': 'RM $dailyR',
            'active': '$dailyActive',
            'reports': '$dailyRep',
            'failed': '$failedRefunds',
          },
          'Weekly': {
            'bookings': '$weeklyB',
            'revenue': 'RM $weeklyR',
            'active': '$weeklyActive',
            'reports': '$weeklyRep',
            'failed': '$failedRefunds',
          },
          'Monthly': {
            'bookings': '$monthlyB',
            'revenue': 'RM $monthlyR',
            'active': '$monthlyActive',
            'reports': '$monthlyRep',
            'failed': '$failedRefunds',
          },
        };
      });
    } catch (e) {
      debugPrint('Dashboard Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showManualBookingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ManualBookingSheet(onBookingAdded: _fetchOverviewData),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF173F32)),
      );
    }

    final currentStats = _dashboardStats[_selectedView]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '— ${DateTime.now().toString().split(' ')[0]}',
                    style: const TextStyle(
                      color: Color(0xFF173F32),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D211A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF173F32)),
                onPressed: _fetchOverviewData,
                tooltip: 'Refresh dashboard',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Bookings, payments and requests at a glance.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),

          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              return Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                children: [
                  Container(
                    width: isMobile ? double.infinity : 200,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedView,
                        isExpanded: true,
                        items: ['Daily', 'Weekly', 'Monthly']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedView = val!),
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 0, width: isMobile ? 0 : 16),
                  SizedBox(
                    width: isMobile ? double.infinity : null,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF173F32),
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _showManualBookingModal,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add manual booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              int columns = constraints.maxWidth > 800
                  ? 3
                  : (constraints.maxWidth > 500 ? 2 : 1);
              double width =
                  (constraints.maxWidth - ((columns - 1) * 16)) / columns;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(
                    width,
                    Icons.calendar_today,
                    const Color(0xFFE8F5E9),
                    '$_selectedView BOOKINGS'.toUpperCase(),
                    currentStats['bookings']!,
                    'Live database records',
                  ),
                  _buildStatCard(
                    width,
                    Icons.money,
                    const Color(0xFFE3F2FD),
                    '$_selectedView REVENUE'.toUpperCase(),
                    currentStats['revenue']!,
                    'Confirmed payments',
                  ),
                  _buildStatCard(
                    width,
                    Icons.people_outline,
                    const Color(0xFFF3E5F5),
                    'ACTIVE RESERVATIONS',
                    currentStats['active']!,
                    'Paid and reserved',
                  ),
                  _buildStatCard(
                    width,
                    Icons.info_outline,
                    const Color(0xFFFFF3E0),
                    'PENDING USER REPORTS',
                    currentStats['reports']!,
                    currentStats['reports'] == '0'
                        ? 'Inbox clear'
                        : 'Needs attention',
                  ),
                  _buildStatCard(
                    width,
                    Icons.schedule,
                    const Color(0xFFFFF3E0),
                    'FAILED REFUNDS',
                    currentStats['failed']!,
                    currentStats['failed'] == '0'
                        ? 'No failures'
                        : 'Action required',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          const Text(
            '— LIVE UPDATES',
            style: TextStyle(
              color: Color(0xFF173F32),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent reservations',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: widget.onViewAllBookings,
                child: const Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: Color(0xFF173F32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF173F32),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: _recentReservations.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No bookings found in database.'),
                    ),
                  )
                : Column(
                    children: _recentReservations.asMap().entries.map((entry) {
                      final index = entry.key;
                      final b = entry.value;
                      final profile = b['profiles'] ?? {};

                      final String rawId = b['id'].toString();
                      final String shortId = rawId.length > 8
                          ? rawId.substring(0, 8).toUpperCase()
                          : rawId.toUpperCase();

                      final rawPayload = b['checkout_payload'];
                      Map<String, dynamic>? firstCartItem;

                      if (rawPayload is List &&
                          rawPayload.isNotEmpty &&
                          rawPayload.first is Map) {
                        firstCartItem = Map<String, dynamic>.from(
                          rawPayload.first as Map,
                        );
                      }

                      final String facility =
                          b['facility_name'] ??
                          firstCartItem?['facility_name'] ??
                          'Facility Not Set';
                      final String bDate =
                          b['booking_date'] ??
                          firstCartItem?['date'] ??
                          'No Date';

                      String bTime = b['start_time'] ?? 'No Time';
                      if (b['start_time'] == null &&
                          firstCartItem?['start_times'] is List &&
                          (firstCartItem!['start_times'] as List).isNotEmpty) {
                        bTime = (firstCartItem['start_times'] as List).first
                            .toString();
                      }

                      final String displayName =
                          (firstCartItem?['student_name'] ??
                                  profile['full_name'] ??
                                  'Unknown User')
                              .toString();
                      final String displayMatric =
                          (firstCartItem?['matric_number'] ??
                                  profile['matric_number'] ??
                                  'N/A')
                              .toString();

                      return Column(
                        children: [
                          _buildReservationRow(
                            (b['booking_reference'] ?? '#KRP-$shortId')
                                .toString(),
                            displayName,
                            displayMatric,
                            facility,
                            '$bDate\n$bTime',
                          ),
                          if (index != _recentReservations.length - 1)
                            const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    double width,
    IconData icon,
    Color iconBgColor,
    String title,
    String value,
    String subtitle,
  ) => AdminMetricCard(
    width: width,
    icon: icon,
    iconBackground: iconBgColor,
    title: title,
    value: value,
    subtitle: subtitle,
    onTap: () => _openStat(title),
  );

  void _openStat(String title) {
    if (title.contains('REPORT')) {
      final action = widget.onViewReports;
      if (action != null) {
        action();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const Scaffold(
            appBar: null,
            body: SafeArea(child: AdminReportsTab()),
          ),
        ),
      );
      return;
    }
    if (title.contains('REFUND')) {
      _showFailedRefunds();
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = _selectedView == 'Daily'
        ? 0
        : _selectedView == 'Weekly'
        ? 7
        : 30;
    final rows = _dashboardBookingRows.where((raw) {
      final b = raw as Map;
      final payload = b['checkout_payload'];
      final first =
          payload is List && payload.isNotEmpty && payload.first is Map
          ? payload.first as Map
          : <dynamic, dynamic>{};
      final parsed =
          DateTime.tryParse(
            (b['booking_date'] ??
                    first['booking_date'] ??
                    first['date'] ??
                    b['created_at'] ??
                    now)
                .toString(),
          ) ??
          now;
      final delta = DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
      ).difference(today).inDays.abs();
      final status = (b['status'] ?? '').toString().trim().toLowerCase();
      return delta <= limit &&
          (!title.contains('ACTIVE') ||
              ['confirmed', 'paid', 'booked'].contains(status));
    }).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF7F9F7),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF173F32),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close details',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  '${rows.length} reservation${rows.length == 1 ? '' : 's'} · $_selectedView view',
                  style: const TextStyle(color: Color(0xFF65756C)),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: rows.isEmpty
                      ? const Center(child: Text('No matching reservations.'))
                      : ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final b = rows[index] as Map;
                            final profile = b['profiles'] is Map
                                ? b['profiles'] as Map
                                : <dynamic, dynamic>{};
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8E4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (b['booking_reference'] ?? b['id'])
                                        .toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF173F32),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    (profile['full_name'] ?? 'Student')
                                        .toString(),
                                  ),
                                  Text(
                                    '${b['facility_name'] ?? 'See booking details'} · ${b['booking_date'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF65756C),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        'RM${(num.tryParse((b['total_amount'] ?? b['amount'] ?? 0).toString()) ?? 0).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        (b['status'] ?? '').toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF65756C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (widget.onViewAllBookings != null) {
                        widget.onViewAllBookings!();
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const Scaffold(
                              body: SafeArea(child: AdminBookingsTab()),
                            ),
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF173F32),
                    ),
                    child: const Text('Open bookings'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFailedRefunds() {
    final future = supabase
        .from('refunds')
        .select('refund_reference,amount,status,reason')
        .eq('status', 'failed');
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .65,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Failed refunds',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close details',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError)
                        return const Center(
                          child: Text(
                            'Could not load failed refunds. Close and try again.',
                          ),
                        );
                      final rows = snapshot.data as List? ?? [];
                      if (rows.isEmpty)
                        return const Center(child: Text('No failed refunds.'));
                      return ListView.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, index) {
                          final r = rows[index] as Map;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              (r['refund_reference'] ?? 'Refund').toString(),
                            ),
                            subtitle: Text((r['reason'] ?? '').toString()),
                            trailing: Text(
                              'RM${(num.tryParse(r['amount'].toString()) ?? 0).toStringAsFixed(2)}',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (widget.onViewRefunds != null) {
                        widget.onViewRefunds!('Failed');
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const Scaffold(
                              body: SafeArea(child: AdminRefundsTab()),
                            ),
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF173F32),
                    ),
                    child: const Text('Open refund management'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReservationRow(
    String bookingId,
    String name,
    String matric,
    String facility,
    String date,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookingId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                matric,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(facility, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                date,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualBookingSheet extends StatefulWidget {
  final VoidCallback onBookingAdded;
  const _ManualBookingSheet({required this.onBookingAdded});

  @override
  State<_ManualBookingSheet> createState() => _ManualBookingSheetState();
}

class _ManualBookingSheetState extends State<_ManualBookingSheet> {
  final supabase = Supabase.instance.client;
  bool _isSubmitting = false;
  bool _isCheckingSlots = true;

  final _studentNameController = TextEditingController();
  final _matricOrEmailController = TextEditingController();
  final _dateController = TextEditingController(
    text: DateTime.now().toString().split(' ')[0],
  );

  String _selectedCategory = 'KRP Student';
  String _selectedFacility = 'Badminton Court 01';
  String? _selectedSlot;
  String? _matchedStudentLabel;

  /// Only slots that are NOT booked or closed for the chosen facility + date.
  List<String> _openSlots = [];

  static const _facilities = [
    'Badminton Court 01',
    'Badminton Court 02',
    'Ping Pong Table 01',
    'Ping Pong Table 02',
    'Snooker Table',
    'Dart Board',
    'Gym',
  ];

  static const _weekdaySlots = ['5:00 PM', '6:00 PM', '9:00 PM', '10:00 PM'];

  static const _weekendSlots = [
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '9:00 PM',
    '10:00 PM',
  ];

  List<String> get _operatingSlots {
    final parsed =
        DateTime.tryParse(_dateController.text.trim()) ?? DateTime.now();
    final isWeekend =
        parsed.weekday == DateTime.saturday ||
        parsed.weekday == DateTime.sunday;
    return isWeekend ? _weekendSlots : _weekdaySlots;
  }

  @override
  void initState() {
    super.initState();
    _openSlots = List<String>.from(_operatingSlots);
    _selectedSlot = _openSlots.first;
    _fetchAvailableSlots();
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _matricOrEmailController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _normalizeFacilityName(String raw) {
    return raw.trim().toLowerCase().replaceFirstMapped(
      RegExp(r' 0+(\d+)$'),
      (m) => ' ${m[1]}',
    );
  }

  bool _sameFacility(String a, String b) {
    if (a.trim().isEmpty || b.trim().isEmpty) return false;
    final na = _normalizeFacilityName(a);
    final nb = _normalizeFacilityName(b);
    return na == nb || na.contains(nb) || nb.contains(na);
  }

  int? _parseHourFromSlotLabel(String label) {
    final clean = label.trim().toUpperCase();
    final match = RegExp(r'^(\d{1,2}):00\s*(AM|PM)$').firstMatch(clean);
    if (match == null) return null;
    int h = int.tryParse(match.group(1)!) ?? 0;
    final period = match.group(2);
    if (period == 'AM') {
      if (h == 12) h = 0;
    } else {
      if (h != 12) h += 12;
    }
    return h;
  }

  String _endTimeForSlot(String startLabel) {
    final h = _parseHourFromSlotLabel(startLabel);
    if (h == null) return '';
    final endH = (h + 1) % 24;
    final hour12 = endH > 12 ? endH - 12 : (endH == 0 ? 12 : endH);
    final ampm = endH >= 12 ? 'PM' : 'AM';
    return '$hour12:00 $ampm';
  }

  bool _matchesHour(String rawTime, int hour) {
    final t = rawTime.trim().toUpperCase();
    if (t.isEmpty) return false;
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final str24 = '${hour.toString().padLeft(2, '0')}:00';
    final str12 = '$hour12:00 $ampm';
    final hour24Padded = hour.toString().padLeft(2, '0');
    return t.contains(str24) ||
        t.contains(str12.toUpperCase()) ||
        t.startsWith('$hour24Padded:') ||
        t.startsWith('$hour12:00');
  }

  bool _isInactiveStatus(String status) {
    final s = status.trim().toLowerCase();
    return s.contains('cancel') || s.contains('expir') || s.contains('fail');
  }

  bool _bookingMatchesFacilityAndDate(Map b, String dateStr) {
    final topFacility = (b['facility_name'] ?? '').toString().trim();
    final topDate = (b['booking_date'] ?? '').toString().trim();

    bool facilityOk = _sameFacility(topFacility, _selectedFacility);
    bool dateOk = topDate.startsWith(dateStr);

    final rawPayload = b['checkout_payload'];
    if (rawPayload is List) {
      for (final item in rawPayload) {
        if (item is Map) {
          final itemFac = (item['facility_name'] ?? '').toString().trim();
          final itemDate = (item['booking_date'] ?? item['date'] ?? '')
              .toString()
              .trim();
          if (_sameFacility(itemFac, _selectedFacility)) facilityOk = true;
          if (itemDate.startsWith(dateStr)) dateOk = true;
        }
      }
    }

    return facilityOk && dateOk;
  }

  bool _bookingMatchesHour(Map b, int hour) {
    if (_matchesHour((b['start_time'] ?? '').toString(), hour)) return true;

    final rawPayload = b['checkout_payload'];
    if (rawPayload is List) {
      for (final item in rawPayload) {
        if (item is Map) {
          if (_matchesHour((item['start_time'] ?? '').toString(), hour)) {
            return true;
          }
          if (item['start_times'] is List) {
            for (final st in (item['start_times'] as List)) {
              if (_matchesHour(st.toString(), hour)) return true;
            }
          }
        }
      }
    }
    return false;
  }

  Future<void> _fetchAvailableSlots() async {
    final dateStr = _dateController.text.trim();
    if (DateTime.tryParse(dateStr) == null) return;

    setState(() => _isCheckingSlots = true);
    try {
      final rows = await supabase.from('bookings').select();
      final activeBookings = (rows as List)
          .map((r) => Map.from(r as Map))
          .where(
            (b) =>
                _bookingMatchesFacilityAndDate(b, dateStr) &&
                !_isInactiveStatus((b['status'] ?? '').toString()),
          )
          .toList();

      List availabilityRows = [];
      try {
        final rpcRes = await supabase.rpc(
          'slot_availability',
          params: {'p_date': dateStr},
        );
        if (rpcRes is List) {
          availabilityRows = rpcRes;
        }
      } catch (_) {}

      final Set<int> blockedHours = {};
      for (final slotLabel in _operatingSlots) {
        final hour = _parseHourFromSlotLabel(slotLabel);
        if (hour == null) continue;

        final bookedInTable = activeBookings.any(
          (b) => _bookingMatchesHour(b, hour),
        );
        final bookedInRpc = availabilityRows.any((r) {
          final row = r as Map;
          final status = (row['status'] ?? '').toString().toLowerCase();
          if (status == 'available' || _isInactiveStatus(status)) return false;
          final rowFac = (row['facility_name'] ?? '').toString();
          if (!_sameFacility(rowFac, _selectedFacility)) return false;
          return _matchesHour((row['start_time'] ?? '').toString(), hour);
        });

        if (bookedInTable || bookedInRpc) {
          blockedHours.add(hour);
        }
      }

      final available = _operatingSlots.where((slotLabel) {
        final h = _parseHourFromSlotLabel(slotLabel);
        return h != null && !blockedHours.contains(h);
      }).toList();

      if (!mounted) return;
      setState(() {
        _openSlots = available;
        if (_openSlots.isEmpty) {
          _selectedSlot = null;
        } else if (_selectedSlot == null ||
            !_openSlots.contains(_selectedSlot)) {
          _selectedSlot = _openSlots.first;
        }
      });
    } catch (e) {
      debugPrint('Error checking slot availability: $e');
      if (mounted) {
        setState(() {
          _openSlots = List<String>.from(_operatingSlots);
          _selectedSlot ??= _openSlots.first;
        });
      }
    } finally {
      if (mounted) setState(() => _isCheckingSlots = false);
    }
  }

  Future _lookupStudentProfile(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    try {
      if (q.contains('@')) {
        return await supabase
            .from('profiles')
            .select('id, full_name, matric_number, student_category')
            .ilike('email', q)
            .limit(1)
            .maybeSingle();
      } else {
        return await supabase
            .from('profiles')
            .select('id, full_name, matric_number, student_category')
            .ilike('matric_number', q)
            .limit(1)
            .maybeSingle();
      }
    } catch (_) {
      return null;
    }
  }

  int get _calculatedPrice => _priceForCategory(_selectedCategory);

  int _priceForCategory(String categoryLabel) {
    // SCRUM-38: only a recognised KRP category gets the KRP rate.
    final isKRP = StudentCategory.parse(categoryLabel) == StudentCategory.krp;
    if (_selectedFacility.contains('Badminton')) return isKRP ? 6 : 8;
    if (_selectedFacility.contains('Ping Pong')) return isKRP ? 4 : 6;
    if (_selectedFacility.contains('Snooker')) return isKRP ? 10 : 12;
    if (_selectedFacility.contains('Dart')) return isKRP ? 3 : 5;
    if (_selectedFacility == 'Gym') return isKRP ? 3 : 5;
    return 6;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_dateController.text.trim()) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF173F32),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      await _fetchAvailableSlots();
    }
  }

  Future<void> _submitManualBooking() async {
    if (_selectedSlot == null || !_openSlots.contains(_selectedSlot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available time slot selected.')),
      );
      return;
    }

    final dateStr = _dateController.text.trim();
    if (DateTime.tryParse(dateStr) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid date (YYYY-MM-DD).'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final adminUser = supabase.auth.currentUser;
      final identifier = _matricOrEmailController.text.trim();
      final matchedProfile = await _lookupStudentProfile(identifier);

      final String? targetUserId =
          matchedProfile?['id']?.toString() ?? adminUser?.id;

      final resolvedName = _studentNameController.text.trim().isNotEmpty
          ? _studentNameController.text.trim()
          : (matchedProfile?['full_name']?.toString() ?? 'Walk-in Student');

      final resolvedMatric = identifier.isNotEmpty && !identifier.contains('@')
          ? identifier.toUpperCase()
          : (matchedProfile?['matric_number']?.toString() ?? 'N/A');

      // SCRUM-38: a registered student is charged by the category stored in
      // their profile, not by the dropdown, so the KRP discount cannot be
      // given to a non-KRP student by mistake.
      final profileCategory = StudentCategory.parse(
        matchedProfile?['student_category'],
      );
      final categoryLabel = profileCategory?.label ?? _selectedCategory;
      final price = _priceForCategory(categoryLabel);
      final storedCategory =
          profileCategory?.value ??
          StudentCategory.parse(categoryLabel)?.value ??
          'public';

      final refCode =
          'WALKIN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      final endSlot = _endTimeForSlot(_selectedSlot!);

      final payload = <String, dynamic>{
        'user_id': targetUserId,
        'booking_reference': refCode,
        'facility_name': _selectedFacility,
        'booking_date': dateStr,
        'start_time': _selectedSlot,
        'end_time': endSlot,
        'total_amount': price,
        if (storedCategory != 'public') 'customer_category': storedCategory,
        'status': 'confirmed',
        'checkout_payload': [
          {
            'facility_name': _selectedFacility,
            'booking_date': dateStr,
            'date': dateStr,
            'start_time': _selectedSlot,
            'end_time': endSlot,
            'start_times': [_selectedSlot],
            'student_category': storedCategory,
            'student_name': resolvedName,
            'matric_number': resolvedMatric,
            'amount': price,
            'is_manual_walkin': true,
          },
        ],
      };

      try {
        await supabase.from('bookings').insert(payload);
      } catch (e) {
        final msg = e.toString().toLowerCase();
        final fallbackPayload = Map<String, dynamic>.from(payload);
        if (msg.contains('end_time')) {
          fallbackPayload.remove('end_time');
        }
        if (msg.contains('status')) {
          fallbackPayload['status'] = 'Paid';
        }
        await supabase.from('bookings').insert(fallbackPayload);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              matchedProfile != null
                  ? 'Manual booking ($refCode) linked to ${matchedProfile['full_name']}, '
                        'charged RM$price as $categoryLabel.'
                  : 'Manual booking ($refCode) added, charged RM$price as $categoryLabel.',
            ),
          ),
        );
        widget.onBookingAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding booking: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add manual booking',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Create a reservation for a walk-in.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Student category'),
                  _buildDropdown(_selectedCategory, [
                    'KRP Student',
                    'Non-KRP Student',
                    'Public',
                  ], (val) => setState(() => _selectedCategory = val!)),
                  const SizedBox(height: 16),

                  _buildLabel(
                    'Student Matric No. or Email (links to student app)',
                  ),
                  TextField(
                    controller: _matricOrEmailController,
                    onChanged: (val) async {
                      final profile = await _lookupStudentProfile(val);
                      if (!mounted) return;
                      setState(() {
                        if (profile != null) {
                          _matchedStudentLabel =
                              'Matched: ${profile['full_name']} (${profile['matric_number'] ?? ''})';
                          if (_studentNameController.text.trim().isEmpty &&
                              profile['full_name'] != null) {
                            _studentNameController.text = profile['full_name']
                                .toString();
                          }
                        } else {
                          _matchedStudentLabel = null;
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. A24CS0285 or student@graduate.utm.my',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  if (_matchedStudentLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _matchedStudentLabel!,
                      style: const TextStyle(
                        color: Color(0xFF173F32),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  _buildLabel('Student name (optional)'),
                  TextField(
                    controller: _studentNameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Ahmad Daniel',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Facility'),
                  _buildDropdown(_selectedFacility, _facilities, (val) async {
                    if (val != null) {
                      setState(() => _selectedFacility = val);
                      await _fetchAvailableSlots();
                    }
                  }),
                  const SizedBox(height: 16),

                  _buildLabel('Date (YYYY-MM-DD)'),
                  TextField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: InputDecoration(
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel('Available time slot'),
                      if (_isCheckingSlots)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Checking slots...',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                  if (_openSlots.isEmpty && !_isCheckingSlots)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Text(
                        'All time slots for this facility and date are already booked or closed.',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _openSlots.contains(_selectedSlot)
                          ? _selectedSlot
                          : (_openSlots.isNotEmpty ? _openSlots.first : null),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: _openSlots
                          .map(
                            (slot) => DropdownMenuItem<String>(
                              value: slot,
                              child: Text(slot),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSlot = val);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Official $_selectedCategory price',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'RM $_calculatedPrice.00',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF173F32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed:
                        (_isSubmitting ||
                            _isCheckingSlots ||
                            _openSlots.isEmpty)
                        ? null
                        : _submitManualBooking,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirm booking',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );

  Widget _buildDropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
