import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminBookingsTab extends StatefulWidget {
  const AdminBookingsTab({super.key});

  @override
  State<AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<AdminBookingsTab> {
  static const _green = Color(0xFF173F32);
  final supabase = Supabase.instance.client;

  final _searchController = TextEditingController();
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All Statuses';
  DateTime? _selectedDate;

  bool _isLoading = true;
  List _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  String _normalizeCategoryLabel(dynamic rawCategory) {
    final c = (rawCategory?.toString() ?? '').trim().toLowerCase();
    if (c == 'krp' || c == 'krp student') return 'KRP Student';
    if (c == 'non_krp' || c == 'non-krp' || c == 'non-krp student' || c == 'non krp') {
      return 'Non-KRP Student';
    }
    if (c == 'public') return 'Public';
    return rawCategory?.toString().trim().isNotEmpty == true
        ? rawCategory.toString().trim()
        : 'Public';
  }

  String _normalizeStatusFilterValue(String rawStatus) {
    final s = rawStatus.trim().toLowerCase();
    if (s == 'confirmed' || s == 'paid') return 'Confirmed';
    if (s == 'pending_payment' || s == 'pending payment' || s == 'pending') {
      return 'Pending Payment';
    }
    if (s == 'cancelled' || s == 'canceled') return 'Cancelled';
    if (s == 'expired') return 'Expired';
    return rawStatus;
  }

  String _formatDateIso(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatDateLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
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

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('bookings')
          .select('*, profiles!booking_user_id_fkey(full_name, matric_number, phone_number, student_category)')
          .order('created_at', ascending: false);

      final mappedBookings = response
          .where((b) => !(b['status']?.toString().trim().toLowerCase().startsWith('closed') ?? false))
          .map((b) {
            final p = b['profiles'] ?? {};

            final rawPayload = b['checkout_payload'];
            Map<String, dynamic>? firstCartItem;
            if (rawPayload is List && rawPayload.isNotEmpty && rawPayload.first is Map) {
              firstCartItem = Map<String, dynamic>.from(rawPayload.first as Map);
            }

            final facilityName = (b['facility_name']?.toString().trim().isNotEmpty == true)
                ? b['facility_name'].toString()
                : (firstCartItem?['facility_name']?.toString() ?? 'Unknown Facility');

            final bookingDate = (b['booking_date']?.toString().trim().isNotEmpty == true)
                ? b['booking_date'].toString()
                : (firstCartItem?['date']?.toString() ?? firstCartItem?['booking_date']?.toString() ?? '');

            String startTime = b['start_time']?.toString() ?? '';
            if (startTime.trim().isEmpty &&
                firstCartItem?['start_times'] is List &&
                (firstCartItem!['start_times'] as List).isNotEmpty) {
              startTime = (firstCartItem['start_times'] as List).first.toString();
            }

            final rawAmount = b['total_amount'] ?? b['amount'];
            int amount = 0;
            if (rawAmount != null) {
              if (rawAmount is num) {
                amount = rawAmount.toInt();
              } else if (rawAmount is String) {
                amount = double.tryParse(rawAmount)?.toInt() ?? 0;
              }
            }

            final rawStatus = (b['status']?.toString() ?? 'Pending').trim();
            final lowerStatus = rawStatus.toLowerCase();
            final paymentStatus = (lowerStatus == 'paid' || lowerStatus == 'confirmed')
                ? 'Paid'
                : (lowerStatus == 'expired' || lowerStatus == 'cancelled')
                    ? 'Unpaid'
                    : 'Pending';

            return {
              'id': b['id'],
              'ref': '#KRP-${b['id'].toString().padLeft(4, '0')}',
              'payId': 'PAY-${b['id']}',
              'name': p['full_name'] ?? 'Walk-in / Unknown',
              'matric': p['matric_number'] ?? 'N/A',
              'contact': p['phone_number'] ?? 'Not provided',
              'rawCategory': (p['student_category'] ?? 'Public').toString(),
              'category': _normalizeCategoryLabel(p['student_category']),
              'facility': facilityName,
              'date': bookingDate,
              'time': startTime,
              'price': 'RM $amount.00',
              'status': rawStatus,
              'normalizedStatus': _normalizeStatusFilterValue(rawStatus),
              'paymentStatus': paymentStatus,
            };
          }).toList();

      if (mounted) setState(() => _bookings = mappedBookings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List get _filteredBookings {
    final query = _searchController.text.trim().toLowerCase();
    final targetDateIso = _selectedDate != null ? _formatDateIso(_selectedDate!) : null;

    return _bookings.where((booking) {
      final matchesCategory = _selectedCategory == 'All Categories' ||
          booking['category'] == _selectedCategory;

      final matchesStatus = _selectedStatus == 'All Statuses' ||
          booking['normalizedStatus'] == _selectedStatus ||
          booking['status'].toString().toLowerCase() == _selectedStatus.toLowerCase();

      final bookingDateStr = (booking['date']?.toString() ?? '').trim();
      final matchesDate = targetDateIso == null || bookingDateStr.startsWith(targetDateIso);

      final searchableText = [
        booking['ref'],
        booking['payId'],
        booking['name'],
        booking['matric'],
        booking['facility'],
        booking['date'],
      ].join(' ').toLowerCase();

      return matchesCategory && matchesStatus && matchesDate && searchableText.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'All Categories';
      _selectedStatus = 'All Statuses';
      _selectedDate = null;
    });
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'confirmed' || s == 'paid') return const Color(0xFF237346);
    if (s == 'pending_payment' || s == 'pending payment' || s == 'pending') {
      return const Color(0xFF946000);
    }
    if (s == 'cancelled' || s == 'failed' || s == 'unpaid') {
      return const Color(0xFFB13D35);
    }
    if (s == 'refunded') return const Color(0xFF6350A1);
    return Colors.blueGrey;
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(22), borderRadius: BorderRadius.circular(6)),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.grey))),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _showDetails(Map<String, dynamic> booking) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(booking['ref']!),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Student information', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                _detailRow('Student', booking['name']!),
                _detailRow('Matric number', booking['matric']!),
                _detailRow('Contact', booking['contact']!),
                _detailRow('Category', booking['category']!),
                const Divider(height: 24),
                const Text('Reservation information', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _detailRow('Facility', booking['facility']!),
                _detailRow('Date', booking['date']!),
                _detailRow('Time', booking['time']!),
                _detailRow('Amount', booking['price']!),
                _detailRow('Booking status', booking['status']!),
                const Divider(height: 24),
                const Text('Payment information', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _detailRow('Payment status', booking['paymentStatus']!),
                _detailRow('Payment reference', booking['payId']!),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDateFilterButton() {
    final hasDate = _selectedDate != null;
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: hasDate
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear date',
                  onPressed: () => setState(() => _selectedDate = null),
                )
              : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          hasDate ? _formatDateLabel(_selectedDate!) : 'All Dates',
          style: TextStyle(
            fontSize: 14,
            color: hasDate ? Colors.black87 : Colors.grey.shade700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _filteredBookings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ADMIN BOOKING RECORDS', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                  SizedBox(height: 8),
                  Text('Reservations', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _green)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: _green),
                onPressed: _fetchBookings,
                tooltip: 'Refresh database',
              )
            ],
          ),
          const SizedBox(height: 8),
          const Text('Search reservations and view live booking and payment information.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;
              final categoryDropdown = DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: ['All Categories', 'KRP Student', 'Non-KRP Student']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              );

              final statusDropdown = DropdownButtonFormField<String>(
                value: _selectedStatus,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: ['All Statuses', 'Pending Payment', 'Confirmed', 'Cancelled', 'Expired']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              );

              if (isMobile) {
                return Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search bookings',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: categoryDropdown),
                        const SizedBox(width: 8),
                        Expanded(child: statusDropdown),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDateFilterButton()),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _clearFilters,
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
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search bookings',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: categoryDropdown),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: statusDropdown),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _buildDateFilterButton()),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.filter_alt_off_outlined),
                        label: const Text('Clear'),
                      ),
                    ),
                  ],
                );
              }
            }
          ),

          const SizedBox(height: 24),
          Text('${bookings.length} reservation(s)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: _green)))
          else if (bookings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: const Column(
                children: [
                  Icon(Icons.search_off, size: 44, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No bookings match your search and filters.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return constraints.maxWidth < 800 ? _buildMobileCardList(bookings) : _buildDesktopTable(bookings);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMobileCardList(List bookings) {
    return Column(
      children: bookings.map((booking) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking['ref'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                          Text(booking['payId'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _statusBadge(booking['status']),
                        const SizedBox(height: 4),
                        _statusBadge(booking['paymentStatus']),
                      ],
                    )
                  ],
                ),
                const Divider(height: 24),
                Text(booking['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${booking['matric']} · ${booking['category']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 12),
                Text(booking['facility'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${booking['date']} · ${booking['time']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showDetails(booking),
                    icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.black87),
                    label: const Text('View Details', style: TextStyle(color: Colors.black87)),
                  ),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopTable(List bookings) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8E3))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(color: Color(0xFFF9FAF9), borderRadius: BorderRadius.vertical(top: Radius.circular(14)), border: Border(bottom: BorderSide(color: Color(0xFFE2E8E3)))),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('REFERENCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 3, child: Text('STUDENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 3, child: Text('FACILITY / SCHEDULE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 2, child: Text('AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 3, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 2, child: Text('ACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
              ],
            ),
          ),
          ...bookings.map((booking) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8E3)))),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(booking['ref'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(booking['payId'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11))])),
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(booking['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), Text('${booking['matric']} · ${booking['category']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))])),
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(booking['facility'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), Text('${booking['date']} · ${booking['time']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11))])),
                  Expanded(flex: 2, child: Text(booking['price'], style: const TextStyle(fontWeight: FontWeight.bold, color: _green))),
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_statusBadge(booking['status']), const SizedBox(height: 4), _statusBadge(booking['paymentStatus'])])),
                  Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: () => _showDetails(booking), icon: const Icon(Icons.visibility_outlined, size: 16, color: Colors.black87), label: const Text('Details', style: TextStyle(fontSize: 12, color: Colors.black87))))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}