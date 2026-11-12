import 'package:flutter/material.dart';

class AdminBookingsTab extends StatefulWidget {
  const AdminBookingsTab({super.key});

  @override
  State<AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<AdminBookingsTab> {
  String _selectedCategory = 'All Categories';
  final TextEditingController _searchController = TextEditingController();

  // Mock database of bookings
  final _bookings = [
    {
      'ref': '#KRP-1842', 'payId': 'PAY-731842', 'name': 'Ng She Ling', 'matric': 'A24CS0285', 'contact': '012-345 6789',
      'category': 'KRP Student', 'facility': 'Badminton Court 01', 'date': '12 Nov 2026', 'time': '8:00 PM - 9:00 PM',
      'price': 'RM 6.00', 'status': 'Confirmed'
    },
    {
      'ref': '#KRP-1841', 'payId': 'PAY-731841', 'name': 'Amir Hakim', 'matric': 'A24CS0117', 'contact': '017-820 4412',
      'category': 'Non-KRP Student', 'facility': 'Ping Pong Table 02', 'date': '12 Nov 2026', 'time': '6:00 PM - 7:00 PM',
      'price': 'RM 6.00', 'status': 'Confirmed'
    },
    {
      'ref': '#KRP-1840', 'payId': 'PAY-731840', 'name': 'Tan Jia Yie', 'matric': 'A24CS0302', 'contact': '016-993 0208',
      'category': 'KRP Student', 'facility': 'Snooker Table', 'date': '13 Nov 2026', 'time': '5:00 PM - 6:00 PM',
      'price': 'RM 10.00', 'status': 'Confirmed'
    },
    {
      'ref': '#KRP-1839', 'payId': 'PAY-731839', 'name': 'Nur Izzati', 'matric': 'A24CS0211', 'contact': '011-310 7291',
      'category': 'KRP Student', 'facility': 'Dart Board', 'date': '13 Nov 2026', 'time': '10:00 PM - 11:00 PM',
      'price': 'RM 3.00', 'status': 'Confirmed'
    },
  ];

  // Logic to filter bookings based on the dropdown category
  get _filteredBookings {
    if (_selectedCategory == 'All Categories') {
      return _bookings;
    }
    return _bookings.where((b) => b['category'].toString().contains(_selectedCategory)).toList();
  }

  // Opens the Refund Modal Bottom Sheet
  void _showRefundModal(Map<String, dynamic> booking, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RefundProcessSheet(
        booking: booking,
        onRefundConfirmed: () {
          setState(() {
            // Update the status in our list to reflect the refund
            _bookings[index]['status'] = 'Refunded';
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredBookings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('— SHARED BOOKING RECORDS', style: TextStyle(color: Color(0xFF173F32), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Reservations', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0D211A))),
          const SizedBox(height: 8),
          const Text('Confirmed payments and facility reservations from the same student booking records.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),

          // Pricing Verification Filter
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: Color(0xFF173F32)),
                    SizedBox(width: 8),
                    Text('KRP residency pricing verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Administrator-controlled category for students.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: ['All Categories', 'KRP Student', 'Non-KRP Student'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Search and Table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search booking, student or facility',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (val) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text('${displayList.length} records', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Horizontal Scrollable Table (to fit all columns including Action button)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 800),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            SizedBox(width: 120, child: Text('REFERENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                            SizedBox(width: 160, child: Text('STUDENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                            SizedBox(width: 140, child: Text('DATE & TIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                            SizedBox(width: 90, child: Text('PAYMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                            SizedBox(width: 100, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                            SizedBox(width: 90, child: Text('ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                          ],
                        ),
                        const Divider(),
                        
                        // Map through filtered list
                        ...displayList.asMap().entries.map((entry) {
                          int actualIndex = _bookings.indexOf(entry.value); // Keep track of actual index in main list
                          return Column(
                            children: [
                              _buildBookingRow(entry.value, actualIndex),
                              const Divider(),
                            ],
                          );
                        }).toList(),

                        if (displayList.isEmpty)
                          const Padding(padding: EdgeInsets.all(32.0), child: Text('No records found for this category.', style: TextStyle(color: Colors.grey))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBookingRow(Map<String, dynamic> booking, int index) {
    bool isRefunded = booking['status'] == 'Refunded';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(booking['ref'], style: const TextStyle(fontWeight: FontWeight.bold)), Text(booking['payId'], style: const TextStyle(color: Colors.grey, fontSize: 10))])),
          SizedBox(width: 160, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(booking['name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text('${booking['matric']} · ${booking['contact']}', style: const TextStyle(color: Colors.grey, fontSize: 10))])),
          SizedBox(width: 140, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(booking['date'], style: const TextStyle(fontWeight: FontWeight.bold)), Text(booking['time'], style: const TextStyle(color: Colors.grey, fontSize: 10))])),
          SizedBox(width: 90, child: Text(booking['price'], style: const TextStyle(fontSize: 12))),
          
          // Status Badge
          SizedBox(
            width: 100, 
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                decoration: BoxDecoration(color: isRefunded ? Colors.grey.shade200 : const Color(0xFFE8F6C8), borderRadius: BorderRadius.circular(6)), 
                child: Text(booking['status'], style: TextStyle(color: isRefunded ? Colors.grey.shade700 : const Color(0xFF173F32), fontWeight: FontWeight.bold, fontSize: 11))
              ),
            ),
          ),
          
          // Refund Action Button
          SizedBox(
            width: 90, 
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: BorderSide(color: isRefunded ? Colors.grey.shade300 : Colors.orange.shade300),
                foregroundColor: isRefunded ? Colors.grey : Colors.orange.shade800,
              ),
              onPressed: isRefunded ? null : () => _showRefundModal(booking, index),
              child: const Text('Refund', style: TextStyle(fontSize: 12)),
            )
          ),
        ],
      ),
    );
  }
}


// -------------------------------------------------------------
// Interactive bottom sheet for Processing a Refund
// -------------------------------------------------------------
class _RefundProcessSheet extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onRefundConfirmed;

  const _RefundProcessSheet({required this.booking, required this.onRefundConfirmed});

  @override
  State<_RefundProcessSheet> createState() => _RefundProcessSheetState();
}

class _RefundProcessSheetState extends State<_RefundProcessSheet> {
  String _selectedReason = 'Facility closed by administrator';
  final TextEditingController _noteController = TextEditingController(text: 'Verified against facility and payment records.');

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('— ADMIN REFUND', style: TextStyle(color: Color(0xFFD2F865), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    const Text('Process a refund', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Select a confirmed booking and record the administrator-\napproved reason.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: 'selected',
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
                    items: [DropdownMenuItem(value: 'selected', child: Text('${widget.booking['ref']} · ${widget.booking['name']} · ${widget.booking['facility']}'))],
                    onChanged: null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Booking Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STUDENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text(widget.booking['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${widget.booking['matric']} · ${widget.booking['contact']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 12),
                        const Text('BOOKING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text(widget.booking['facility'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${widget.booking['date']} · ${widget.booking['time']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 12),
                        const Text('REFUND AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text(widget.booking['price'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('Original payment method', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('Refund reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedReason,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
                    items: ['Facility closed by administrator', 'Student requested cancellation', 'Duplicate payment', 'System error']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _selectedReason = val!),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Internal note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFE65100), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Administrator action', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                              SizedBox(height: 4),
                              Text('This creates a booking-linked refund in bank processing status. Track or resolve it on the Refund Management page.', style: TextStyle(fontSize: 12, color: Color(0xFFE65100))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Fixed Action Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF173F32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  widget.onRefundConfirmed(); // Updates the status in the table
                  Navigator.pop(context); // Closes bottom sheet
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refund sent to bank for processing.')));
                },
                icon: const Text('Send refund to bank', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                label: const Icon(Icons.check, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }
}