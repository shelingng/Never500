import 'package:flutter/material.dart';

class AdminOverviewTab extends StatefulWidget {
  final VoidCallback? onViewAllBookings;

  const AdminOverviewTab({super.key, this.onViewAllBookings});

  @override
  State<AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<AdminOverviewTab> {
  String _selectedView = 'Daily';

  // Dynamic stats based on the selected dropdown value
  final Map<String, Map<String, String>> _dashboardStats = {
    'Daily': {
      'bookings': '2', 'revenue': 'RM 12', 'active': '4', 'reports': '00', 'failed': '00'
    },
    'Weekly': {
      'bookings': '18', 'revenue': 'RM 108', 'active': '12', 'reports': '01', 'failed': '00'
    },
    'Monthly': {
      'bookings': '64', 'revenue': 'RM 384', 'active': '05', 'reports': '04', 'failed': '02'
    },
  };

  void _showManualBookingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualBookingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStats = _dashboardStats[_selectedView]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('— WEDNESDAY, 11 NOVEMBER', style: TextStyle(color: Color(0xFF173F32), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Good afternoon, Aisyah.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0D211A))),
          const SizedBox(height: 8),
          const Text('Here\'s what\'s happening across the shared KRP Play prototype records.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),

          // View Filter & Manual Booking
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.white),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedView,
                      isExpanded: true,
                      items: ['Daily', 'Weekly', 'Monthly'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedView = val!;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF173F32),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showManualBookingModal,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add manual booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),

          // Dynamic Stat Cards
          _buildStatCard(Icons.calendar_today, const Color(0xFFE8F5E9), '$_selectedView BOOKINGS'.toUpperCase(), currentStats['bookings']!, '$_selectedView prototype records'),
          _buildStatCard(Icons.money, const Color(0xFFE3F2FD), '$_selectedView REVENUE'.toUpperCase(), currentStats['revenue']!, 'Confirmed payments'),
          _buildStatCard(Icons.people_outline, const Color(0xFFF3E5F5), 'ACTIVE RESERVATIONS', currentStats['active']!, 'Paid and reserved'),
          _buildStatCard(Icons.info_outline, const Color(0xFFFFF3E0), 'PENDING USER REPORTS', currentStats['reports']!, currentStats['reports'] == '00' ? 'Inbox clear' : 'Needs attention'),
          _buildStatCard(Icons.schedule, const Color(0xFFFFF3E0), 'FAILED REFUNDS', currentStats['failed']!, currentStats['failed'] == '00' ? 'No failures' : 'Action required'),
          
          const SizedBox(height: 32),
          
          // Shared System Activity
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('— SHARED SYSTEM ACTIVITY', style: TextStyle(color: Color(0xFF173F32), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent activity', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)), child: const Text('Prototype data', style: TextStyle(fontSize: 10)))
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildActivityCard(Icons.calendar_today, 'New booking received', '#KRP-1842')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildActivityCard(Icons.payment, 'Payment confirmed', 'RM 6.00')),
                  ],
                )
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Live Updates (Recent Reservations)
          const Text('— LIVE UPDATES', style: TextStyle(color: Color(0xFF173F32), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent reservations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: widget.onViewAllBookings,
                child: const Row(children: [Text('View all', style: TextStyle(color: Color(0xFF173F32), fontWeight: FontWeight.bold)), Icon(Icons.arrow_forward, color: Color(0xFF173F32), size: 16)]),
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                _buildReservationRow('#KRP-1842', 'Ng She Ling', 'A24CS0285', 'Badminton Court 01', '11 Nov 2026\n8:00 PM'),
                const Divider(height: 1),
                _buildReservationRow('#KRP-1841', 'Amir Hakim', 'A24CS0117', 'Ping Pong Table 02', '11 Nov 2026\n6:00 PM'),
                const Divider(height: 1),
                _buildReservationRow('#KRP-1840', 'Tan Jia Yie', 'A24CS0302', 'Snooker Table', '12 Nov 2026\n5:00 PM'),
                const Divider(height: 1),
                _buildReservationRow('#KRP-1839', 'Nur Izzati', 'A24CS0211', 'Dart Board', '12 Nov 2026\n10:00 PM'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, Color iconBgColor, String title, String value, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.black54)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActivityCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReservationRow(String bookingId, String name, String matric, String facility, String date) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bookingId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(matric, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(facility, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(date, textAlign: TextAlign.right, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}

// Interactive bottom sheet for manual booking
class _ManualBookingSheet extends StatefulWidget {
  @override
  State<_ManualBookingSheet> createState() => _ManualBookingSheetState();
}

class _ManualBookingSheetState extends State<_ManualBookingSheet> {
  final TextEditingController _nameController = TextEditingController(text: 'Walk-in Student');
  final TextEditingController _matricController = TextEditingController(text: 'A24CS0000');
  final TextEditingController _contactController = TextEditingController(text: '012-000 0000');
  final TextEditingController _dateController = TextEditingController(text: '12/11/2026');

  String _selectedCategory = 'KRP Student';
  String _selectedFacility = 'Badminton Court 01';
  String _selectedSlot = '5:00 PM – 6:00 PM';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                    const Text('Add manual booking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Create a reservation for a walk-in or assisted student.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
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
                  _buildLabel('Student name'),
                  _buildTextField(_nameController),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Matric number'),
                  _buildTextField(_matricController),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Contact number'),
                  _buildTextField(_contactController),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Student category'),
                  _buildDropdown(
                    _selectedCategory,
                    ['KRP Student', 'Non-KRP Student', 'Public'],
                    (val) => setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Facility'),
                  _buildDropdown(
                    _selectedFacility,
                    ['Badminton Court 01', 'Badminton Court 02', 'Ping Pong Table 01'],
                    (val) => setState(() => _selectedFacility = val!),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Date'),
                  TextField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Time slot'),
                  _buildDropdown(
                    _selectedSlot,
                    ['5:00 PM – 6:00 PM', '6:00 PM – 7:00 PM', '8:00 PM – 9:00 PM'],
                    (val) => setState(() => _selectedSlot = val!),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Fixed Action Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Official $_selectedCategory price · RM 6/court/hour', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Text('RM 6.00', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF173F32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manual booking added successfully!')));
                    },
                    child: const Text('Confirm booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}