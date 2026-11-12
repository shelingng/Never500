import 'package:flutter/material.dart';

class AdminRefundsTab extends StatefulWidget {
  const AdminRefundsTab({super.key});

  @override
  State<AdminRefundsTab> createState() => _AdminRefundsTabState();
}

class _AdminRefundsTabState extends State<AdminRefundsTab> {
  String _selectedStatus = 'All';
  String? _selectedDate;
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // Mock database for refund history 
  final _refundRecords = [
    {
      'id': 'RF-088',
      'bookingRef': '#KRP-1842',
      'studentName': 'Ng She Ling',
      'matric': 'A24CS0285',
      'facility': 'Badminton Court 01',
      'date': '12/11/2026',
      'bookingDate': '11 Nov 2026',
      'amount': 6.00,
      'reason': 'Facility closed by administrator',
      'status': 'Refunded',
    },
    {
      'id': 'RF-089',
      'bookingRef': '#KRP-1820',
      'studentName': 'Amir Hakim',
      'matric': 'A24CS0117',
      'facility': 'Ping Pong Table 02',
      'date': '10/11/2026',
      'bookingDate': '09 Nov 2026',
      'amount': 6.00,
      'reason': 'System error',
      'status': 'Processing',
    },
    {
      'id': 'RF-090',
      'bookingRef': '#KRP-1815',
      'studentName': 'Tan Jia Yie',
      'matric': 'A24CS0302',
      'facility': 'Snooker Table',
      'date': '08/11/2026',
      'bookingDate': '07 Nov 2026',
      'amount': 10.00,
      'reason': 'Student requested cancellation',
      'status': 'Refunded',
    },
  ];

  // Filtering Logic
  get _filteredRefunds {
    return _refundRecords.where((record) {
      // 1. Filter by Status
      bool matchesStatus = _selectedStatus == 'All' || record['status'] == _selectedStatus;
      
      // 2. Filter by Search (Name, Matric, Booking ID, or Refund ID)
      String search = _searchController.text.toLowerCase();
      bool matchesSearch = search.isEmpty || 
          record['studentName'].toString().toLowerCase().contains(search) ||
          record['matric'].toString().toLowerCase().contains(search) ||
          record['bookingRef'].toString().toLowerCase().contains(search) ||
          record['id'].toString().toLowerCase().contains(search);
          
      // 3. Filter by Date
      bool matchesDate = _selectedDate == null || record['date'] == _selectedDate;

      return matchesStatus && matchesSearch && matchesDate;
    }).toList();
  }

  // Active Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, 11, 12), // Default to prototype timeline
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF173F32), // Custom Green header
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format to dd/mm/yyyy
        _selectedDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        _dateController.text = _selectedDate!;
      });
    }
  }

  // Clear selected date
  void _clearDate() {
    setState(() {
      _selectedDate = null;
      _dateController.clear();
    });
  }

  // Mark a processing refund as complete
  void _markAsRefunded(int index) {
    setState(() {
      _refundRecords[index]['status'] = 'Refunded';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refund marked as successfully completed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredRefunds;
    
    // Dynamic Calculations for Summary Cards
    int processingCount = _refundRecords.where((r) => r['status'] == 'Processing').length;
    double totalRefunded = _refundRecords
        .where((r) => r['status'] == 'Refunded')
        .fold(0.0, (sum, item) => sum + (item['amount'] as double));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('— PAYMENT OPERATIONS', style: TextStyle(color: Color(0xFF173F32), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Refund history', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0D211A))),
          const SizedBox(height: 8),
          const Text('Review and manage processed refunds for facility-related disruptions.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),

          // Dynamic Summary Cards
          _buildSummaryCard('PROCESSING (BANK)', '$processingCount'),
          _buildSummaryCard('TOTAL REFUNDED', 'RM ${totalRefunded.toStringAsFixed(2)}'),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search student, matric, or booking ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 2. Filters (Status & Date)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                            items: ['All', 'Processing', 'Refunded'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setState(() => _selectedStatus = val!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          // 🌟 FIX: Removed AbsorbPointer and used readOnly + onTap so the clear button works!
                          TextField(
                            controller: _dateController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: InputDecoration(
                              hintText: 'dd/mm/yyyy',
                              suffixIcon: _selectedDate == null 
                                  ? const Icon(Icons.calendar_today, size: 16)
                                  : IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: _clearDate, // This will now successfully clear the date and refresh the list
                                      splashRadius: 20,
                                    ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 40),
                
                // 3. Dynamic List of Refund History Cards
                const Text('— REFUND RECORDS', style: TextStyle(color: Color(0xFF173F32), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 16),
                
                if (displayList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No refunds match your filters.', style: TextStyle(color: Colors.grey))),
                  ),
                  
                // Map through filtered records
                ...displayList.map((record) {
                  int actualIndex = _refundRecords.indexOf(record);
                  return _buildDetailedRefundCard(record, actualIndex);
                }).toList(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailedRefundCard(dynamic record, int actualIndex) {
    bool isProcessing = record['status'] == 'Processing';
    
    // Create initials for avatar (e.g. "Ng She Ling" -> "NS")
    String initials = record['studentName'].split(' ').take(2).map((w) => w[0]).join();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isProcessing ? Colors.orange.shade300 : Colors.grey.shade200, width: isProcessing ? 1.5 : 1.0),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(record['date'], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isProcessing ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  record['status'], 
                  style: TextStyle(color: isProcessing ? Colors.orange.shade800 : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Reason Box
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('REASON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(record['reason'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Student Info block
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(record['id'], style: const TextStyle(fontWeight: FontWeight.bold)), 
                  const Text('REFUND ID', style: TextStyle(fontSize: 10, color: Colors.grey))
                ]
              ),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.all(8), 
                decoration: BoxDecoration(color: const Color(0xFFE8F6C8), borderRadius: BorderRadius.circular(8)), 
                child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF173F32)))
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(record['studentName'], style: const TextStyle(fontWeight: FontWeight.bold)), 
                  Text(record['matric'], style: const TextStyle(fontSize: 10, color: Colors.grey))
                ]
              ),
            ],
          ),
          const Divider(height: 32),
          
          // Booking Info & Amount Block
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BOOKING REFERENCE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text('${record['bookingRef']} · ${record['facility']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(record['bookingDate'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('REFUND', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text('RM ${record['amount'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF173F32))),
                ],
              )
            ],
          ),
          
          // Admin Action for Processing Refunds
          if (isProcessing) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF173F32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => _markAsRefunded(actualIndex),
                icon: const Icon(Icons.check, color: Colors.white, size: 16),
                label: const Text('Mark as Refunded', style: TextStyle(color: Colors.white)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}