import 'package:flutter/material.dart';

class AdminBookingsTab extends StatefulWidget {
  const AdminBookingsTab({super.key});

  @override
  State<AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<AdminBookingsTab> {
  static const _green = Color(0xFF173F32);

  final _searchController = TextEditingController();

  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All Statuses';

  // Fictional UI examples only. No database or real payment connection.
  final List<Map<String, String>> _bookings = [
    {
      'ref': 'DEMO-1842',
      'payId': 'DEMO-PAY-1842',
      'name': 'Sample Student A',
      'matric': 'DEMO-001',
      'contact': 'Not provided',
      'category': 'KRP Student',
      'facility': 'Badminton Court 01',
      'date': '14 Nov 2026',
      'time': '8:00 PM–9:00 PM',
      'price': 'RM 6.00',
      'status': 'Confirmed',
      'paymentStatus': 'Paid',
    },
    {
      'ref': 'DEMO-1841',
      'payId': 'DEMO-PAY-1841',
      'name': 'Sample Student B',
      'matric': 'DEMO-002',
      'contact': 'Not provided',
      'category': 'Non-KRP Student',
      'facility': 'Ping Pong Table 02',
      'date': '14 Nov 2026',
      'time': '6:00 PM–7:00 PM',
      'price': 'RM 6.00',
      'status': 'Confirmed',
      'paymentStatus': 'Paid',
    },
    {
      'ref': 'DEMO-1840',
      'payId': 'Not available',
      'name': 'Sample Student C',
      'matric': 'DEMO-003',
      'contact': 'Not provided',
      'category': 'KRP Student',
      'facility': 'Snooker Table',
      'date': '15 Nov 2026',
      'time': '5:00 PM–6:00 PM',
      'price': 'RM 10.00',
      'status': 'Pending Payment',
      'paymentStatus': 'Pending',
    },
    {
      'ref': 'DEMO-1839',
      'payId': 'DEMO-PAY-1839',
      'name': 'Sample Student D',
      'matric': 'DEMO-004',
      'contact': 'Not provided',
      'category': 'KRP Student',
      'facility': 'Dart Board',
      'date': '15 Nov 2026',
      'time': '10:00 PM–11:00 PM',
      'price': 'RM 3.00',
      'status': 'Cancelled',
      'paymentStatus': 'Refunded',
    },
  ];

  List<Map<String, String>> get _filteredBookings {
    final query = _searchController.text.trim().toLowerCase();

    return _bookings.where((booking) {
      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          booking['category'] == _selectedCategory;

      final matchesStatus =
          _selectedStatus == 'All Statuses' ||
          booking['status'] == _selectedStatus;

      final searchableText = [
        booking['ref'] ?? '',
        booking['payId'] ?? '',
        booking['name'] ?? '',
        booking['matric'] ?? '',
        booking['facility'] ?? '',
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
    switch (status) {
      case 'Confirmed':
      case 'Paid':
        return const Color(0xFF237346);
      case 'Pending Payment':
      case 'Pending':
        return const Color(0xFF9A6500);
      case 'Cancelled':
      case 'Failed':
        return const Color(0xFFB13D35);
      case 'Refunded':
        return const Color(0xFF6350A1);
      default:
        return Colors.blueGrey;
    }
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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

  void _showDetails(Map<String, String> booking) {
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
                const Text(
                  'Booking details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                _detailRow('Student', booking['name']!),
                _detailRow('Matric number', booking['matric']!),
                _detailRow('Contact', booking['contact']!),
                _detailRow('Category', booking['category']!),
                const Divider(height: 24),
                _detailRow('Facility', booking['facility']!),
                _detailRow('Date', booking['date']!),
                _detailRow('Time', booking['time']!),
                _detailRow('Amount', booking['price']!),
                _detailRow('Booking status', booking['status']!),
                _detailRow('Payment status', booking['paymentStatus']!),
                _detailRow('Payment reference', booking['payId']!),
                const SizedBox(height: 16),
                const Text(
                  'Demo record only. No actual booking or payment.',
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

  Future<void> _showDemoRefund(Map<String, String> booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Simulate refund'),
        content: Text(
          'Simulate a full refund for ${booking['ref']} '
          '(${booking['price']})?\n\n'
          'This changes this demo record to Cancelled / Refunded. '
          'No money is transferred, and the separate Refunds page '
          'is not updated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simulate refund'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      booking['status'] = 'Cancelled';
      booking['paymentStatus'] = 'Refunded';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo record updated. No actual refund was processed.'),
      ),
    );
  }

  Widget _filter({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        // Rebuild when Clear filters resets the selected value.
        key: ValueKey('$label:$value'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: options
            .map(
              (option) =>
                  DropdownMenuItem<String>(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _filteredBookings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADMIN BOOKING RECORDS',
            style: TextStyle(
              color: _green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reservations',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search reservations and inspect booking and payment statuses.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Honest prototype notice.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Demo data — these records are not connected to student '
              'bookings or Supabase. Changes reset when the app restarts.',
              style: TextStyle(color: Color(0xFF705500)),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8E3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search bookings',
                    hintText: 'Reference, student, matric or facility',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _filter(
                      label: 'Student category',
                      value: _selectedCategory,
                      options: const [
                        'All Categories',
                        'KRP Student',
                        'Non-KRP Student',
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                    ),
                    _filter(
                      label: 'Booking status',
                      value: _selectedStatus,
                      options: const [
                        'All Statuses',
                        'Pending Payment',
                        'Confirmed',
                        'Cancelled',
                        'Expired',
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatus = value);
                      },
                    ),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Clear filters'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${bookings.length} reservation(s)',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          if (bookings.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.search_off, size: 44, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No bookings match your search and filters.'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8E3)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 52,
                  dataRowMinHeight: 88,
                  dataRowMaxHeight: 110,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Reference')),
                    DataColumn(label: Text('Student')),
                    DataColumn(label: Text('Facility / Schedule')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Booking')),
                    DataColumn(label: Text('Payment')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: bookings.map((booking) {
                    final canRefund =
                        booking['status'] == 'Confirmed' &&
                        booking['paymentStatus'] == 'Paid';

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            booking['ref']!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(booking['name']!),
                              Text(
                                booking['matric']!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                booking['category']!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(booking['facility']!),
                              Text(booking['date']!),
                              Text(
                                booking['time']!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(booking['price']!)),
                        DataCell(_statusBadge(booking['status']!)),
                        DataCell(_statusBadge(booking['paymentStatus']!)),
                        DataCell(
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => _showDetails(booking),
                                child: const Text('Details'),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: canRefund
                                    ? () => _showDemoRefund(booking)
                                    : null,
                                child: const Text('Demo refund'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
