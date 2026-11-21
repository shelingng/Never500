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

  bool _isLoading = true;
  List _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  bool _isAdminEmptyClosureRow(Map b) {
    final status = (b['status']?.toString() ?? '').trim().toLowerCase();
    final ref = (b['booking_reference']?.toString() ?? '').trim().toUpperCase();
    final rawAmt = b['total_amount'] ?? b['amount'];
    double amt = 0;
    if (rawAmt is num) amt = rawAmt.toDouble();
    if (rawAmt is String) amt = double.tryParse(rawAmt) ?? 0;

    if (status.startsWith('closed') && ref.startsWith('ADMIN-') && amt == 0) {
      return true;
    }
    return false;
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('bookings')
          .select(
            '*, profiles!booking_user_id_fkey(full_name, matric_number, phone_number, student_category)',
          )
          .order('created_at', ascending: false);

      final mappedBookings = (response as List)
          .map((r) => Map.from(r as Map))
          .where((b) => !_isAdminEmptyClosureRow(b))
          .map((b) {
        final p = b['profiles'] is Map
            ? Map.from(b['profiles'] as Map)
            : {};

        final rawPayload = b['checkout_payload'];
        Map? firstCartItem;
        if (rawPayload is List &&
            rawPayload.isNotEmpty &&
            rawPayload.first is Map) {
          firstCartItem = Map.from(rawPayload.first as Map);
        }

        final facility = (b['facility_name'] ??
                firstCartItem?['facility_name'] ??
                '')
            .toString()
            .trim();
        final date = (b['booking_date'] ??
                firstCartItem?['booking_date'] ??
                firstCartItem?['date'] ??
                '')
            .toString()
            .trim();
        String time =
            (b['start_time'] ?? firstCartItem?['start_time'] ?? '')
                .toString()
                .trim();
        if (time.isEmpty &&
            firstCartItem?['start_times'] is List &&
            (firstCartItem!['start_times'] as List).isNotEmpty) {
          time = (firstCartItem['start_times'] as List).join(', ');
        }

        final rawAmount = b['total_amount'] ?? b['amount'];
        double amount = 0;
        if (rawAmount is num) {
          amount = rawAmount.toDouble();
        } else if (rawAmount is String) {
          amount = double.tryParse(rawAmount) ?? 0;
        }

        final rawStatus = (b['status'] ?? 'Pending').toString().trim();
        final isClosedByAdmin = rawStatus.toLowerCase().startsWith('closed');
        final displayStatus = isClosedByAdmin
            ? 'Closed by Admin (${rawStatus.replaceFirst(RegExp(r'^closed\s*\(?|\)?$', caseSensitive: false), '').trim()})'
            : rawStatus;

        final lowerStat = rawStatus.toLowerCase();
        final paymentStatus = isClosedByAdmin
            ? 'Refund Required'
            : (lowerStat == 'paid' ||
                    lowerStat == 'confirmed' ||
                    lowerStat == 'booked')
                ? 'Paid'
                : 'Pending';

        final rawId = (b['id'] ?? '').toString();
        final shortId =
            rawId.length > 6 ? rawId.substring(0, 6).toUpperCase() : rawId;

        return {
          'id': rawId,
          'ref': (b['booking_reference'] ?? '#KRP-$shortId').toString(),
          'payId': 'PAY-$shortId',
          'name': (p['full_name'] ?? 'Walk-in / Unknown').toString(),
          'matric': (p['matric_number'] ?? 'N/A').toString(),
          'contact': (p['phone_number'] ?? 'Not provided').toString(),
          'category': (p['student_category'] ?? 'Public').toString(),
          'facility': facility.isNotEmpty ? facility : 'Unknown Facility',
          'date': date,
          'time': time,
          'price': 'RM ${amount.toStringAsFixed(2)}',
          'status': displayStatus,
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

    return _bookings.where((booking) {
      final matchesCategory = _selectedCategory == 'All Categories' ||
          booking['category'] == _selectedCategory;
      final statusMap = {'Paid': 'Confirmed', 'Pending': 'Pending Payment'};
      final normalizedStatus = statusMap[booking['status']] ?? booking['status'];
      final matchesStatus = _selectedStatus == 'All Statuses' ||
          normalizedStatus == _selectedStatus ||
          booking['status'] == _selectedStatus ||
          (_selectedStatus == 'Closed by Admin' &&
              booking['status'].toString().startsWith('Closed by Admin'));

      final searchableText = [
        booking['ref'],
        booking['payId'],
        booking['name'],
        booking['matric'],
        booking['facility'],
        booking['status'],
      ].join(' ').toLowerCase();

      return matchesCategory && matchesStatus && searchableText.contains(query);
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
    });
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'confirmed' || s == 'paid') return const Color(0xFF237346);
    if (s == 'pending payment' || s == 'pending') return const Color(0xFF946000);
    if (s.startsWith('closed by admin') || s == 'cancelled' || s == 'failed') {
      return const Color(0xFFB13D35);
    }
    if (s == 'refunded' || s == 'refund required') return const Color(0xFF6350A1);
    return Colors.blueGrey;
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
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
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(Map booking) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(booking['ref'].toString()),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                _detailRow('Student', booking['name'].toString()),
                _detailRow('Matric number', booking['matric'].toString()),
                _detailRow('Contact', booking['contact'].toString()),
                _detailRow('Category', booking['category'].toString()),
                const Divider(height: 24),
                const Text(
                  'Reservation information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _detailRow('Facility', booking['facility'].toString()),
                _detailRow('Date', booking['date'].toString()),
                _detailRow('Time', booking['time'].toString()),
                _detailRow('Amount', booking['price'].toString()),
                _detailRow('Booking status', booking['status'].toString()),
                const Divider(height: 24),
                const Text(
                  'Payment information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _detailRow('Payment status', booking['paymentStatus'].toString()),
                _detailRow('Payment reference', booking['payId'].toString()),
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
                  Text(
                    'ADMIN BOOKING RECORDS',
                    style: TextStyle(
                      color: _green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Reservations',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _green,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: _green),
                onPressed: _fetchBookings,
                tooltip: 'Refresh database',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Search reservations and view live booking and payment information.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 800;
              if (isMobile) {
                return Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search bookings',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: ['All Categories', 'KRP Student', 'Non-KRP Student']
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c, overflow: TextOverflow.ellipsis),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: [
                              'All Statuses',
                              'Pending Payment',
                              'Confirmed',
                              'Closed by Admin',
                              'Cancelled',
                              'Expired',
                            ]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s, overflow: TextOverflow.ellipsis),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatus = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Clear'),
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search bookings',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: ['All Categories', 'KRP Student', 'Non-KRP Student']
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: [
                          'All Statuses',
                          'Pending Payment',
                          'Confirmed',
                          'Closed by Admin',
                          'Cancelled',
                          'Expired',
                        ]
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatus = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.filter_alt_off_outlined),
                        label: const Text('Clear filters'),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          Text(
            '${bookings.length} reservation(s)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: _green),
              ),
            )
          else if (bookings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.search_off, size: 44, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No bookings match your search and filters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return constraints.maxWidth < 800
                    ? _buildMobileCardList(bookings)
                    : _buildDesktopTable(bookings);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMobileCardList(List bookings) {
    return Column(
      children: bookings.map((booking) {
        final item = booking as Map;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                          item['ref'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          item['payId'].toString(),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _statusBadge(item['status'].toString()),
                        const SizedBox(height: 4),
                        _statusBadge(item['paymentStatus'].toString()),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  item['name'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${item['matric']} · ${item['category']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  item['facility'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${item['date']} · ${item['time']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showDetails(item),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: Colors.black87,
                    ),
                    label: const Text(
                      'View Details',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopTable(List bookings) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8E3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAF9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8E3))),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'REFERENCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'STUDENT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'FACILITY / SCHEDULE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'AMOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ACTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...bookings.map((booking) {
            final item = booking as Map;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8E3))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['ref'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          item['payId'].toString(),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          item['matric'].toString(),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['facility'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${item['date']} · ${item['time']}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item['price'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _green,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statusBadge(item['status'].toString()),
                        const SizedBox(height: 4),
                        _statusBadge(item['paymentStatus'].toString()),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => _showDetails(item),
                        icon: const Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: Colors.black87,
                        ),
                        label: const Text(
                          'Details',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ),
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