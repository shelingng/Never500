import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOverviewTab extends StatefulWidget {
  final VoidCallback? onViewAllBookings;

  const AdminOverviewTab({super.key, this.onViewAllBookings});

  @override
  State<AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<AdminOverviewTab> {
  final supabase = Supabase.instance.client;
  String _selectedView = 'Daily';
  bool _isLoading = true;

  List<dynamic> _recentReservations = [];

  // Dynamic stats container
  Map<String, Map<String, String>> _dashboardStats = {
    'Daily': {'bookings': '0', 'revenue': 'RM 0', 'active': '0', 'reports': '0', 'failed': '0'},
    'Weekly': {'bookings': '0', 'revenue': 'RM 0', 'active': '0', 'reports': '0', 'failed': '0'},
    'Monthly': {'bookings': '0', 'revenue': 'RM 0', 'active': '0', 'reports': '0', 'failed': '0'},
  };

  @override
  void initState() {
    super.initState();
    _fetchOverviewData();
  }

  Future<void> _fetchOverviewData() async {
    setState(() => _isLoading = true);
    try {
      final allBookingsResp = await supabase.from('bookings').select('*, profiles(full_name, matric_number)');
      final List<dynamic> allBookings = List<dynamic>.from(allBookingsResp);

      allBookings.sort((a, b) {
        final idA = a['id'] ?? 0;
        final idB = b['id'] ?? 0;
        if (idA is int && idB is int) return idB.compareTo(idA);
        return 0;
      });

      final recentData = allBookings.take(4).toList();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      int dailyB = 0, weeklyB = 0, monthlyB = 0;
      int dailyR = 0, weeklyR = 0, monthlyR = 0;
      int activeCount = 0;

      for (var b in allBookings) {
        // 🌟 Fix 1: Case-insensitive status check
        final status = (b['status']?.toString() ?? '').toLowerCase();
        if (status == 'confirmed' || status == 'paid') activeCount++;

        final bDateRaw = DateTime.tryParse(b['booking_date'].toString()) ?? now;
        final bDate = DateTime(bDateRaw.year, bDateRaw.month, bDateRaw.day);
        
        // 🌟 Fix 2: Bulletproof amount parsing (handles ints, doubles, and strings)
        final rawAmount = b['amount'];
        int amount = 0;
        if (rawAmount != null) {
          if (rawAmount is num) amount = rawAmount.toInt();
          else if (rawAmount is String) amount = double.tryParse(rawAmount)?.toInt() ?? 0;
        }

        final diffDays = today.difference(bDate).inDays.abs();

        if (diffDays == 0) { dailyB++; dailyR += amount; }
        if (diffDays <= 7) { weeklyB++; weeklyR += amount; }
        if (diffDays <= 30) { monthlyB++; monthlyR += amount; }
      }

      int pendingReports = 0;
      try {
        final allReports = await supabase.from('reports').select('status');
        pendingReports = allReports.where((r) => r['status']?.toString().toLowerCase() == 'submitted' || r['status']?.toString().toLowerCase() == 'under review').length;
      } catch (_) {}

      setState(() {
        _recentReservations = recentData;
        _dashboardStats = {
          'Daily': {'bookings': '$dailyB', 'revenue': 'RM $dailyR', 'active': '$activeCount', 'reports': '$pendingReports', 'failed': '0'},
          'Weekly': {'bookings': '$weeklyB', 'revenue': 'RM $weeklyR', 'active': '$activeCount', 'reports': '$pendingReports', 'failed': '0'},
          'Monthly': {'bookings': '$monthlyB', 'revenue': 'RM $monthlyR', 'active': '$activeCount', 'reports': '$pendingReports', 'failed': '0'},
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
      builder: (context) => _ManualBookingSheet(onBookingAdded: _fetchOverviewData),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF173F32)));
    }

    final currentStats = _dashboardStats[_selectedView]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('— ${DateTime.now().toString().split(' ')[0]}', style: const TextStyle(color: Color(0xFF173F32), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Admin Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0D211A))),
          const SizedBox(height: 8),
          const Text('Live database overview from Supabase.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 32),

          // View Filter & Manual Booking
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              return Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                children: [
                  Container(
                    width: isMobile ? double.infinity : 200,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.white),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedView,
                        isExpanded: true,
                        items: ['Daily', 'Weekly', 'Monthly'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => _selectedView = val!),
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 0, width: isMobile ? 0 : 16),
                  SizedBox(
                    width: isMobile ? double.infinity : null,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF173F32),
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _showManualBookingModal,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add manual booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              );
            }
          ),
          const SizedBox(height: 24),

          // Responsive Grid for Stat Cards
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
              double width = (constraints.maxWidth - ((columns - 1) * 16)) / columns;
              
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(width, Icons.calendar_today, const Color(0xFFE8F5E9), '$_selectedView BOOKINGS'.toUpperCase(), currentStats['bookings']!, 'Live database records'),
                  _buildStatCard(width, Icons.money, const Color(0xFFE3F2FD), '$_selectedView REVENUE'.toUpperCase(), currentStats['revenue']!, 'Confirmed payments'),
                  _buildStatCard(width, Icons.people_outline, const Color(0xFFF3E5F5), 'ACTIVE RESERVATIONS', currentStats['active']!, 'Paid and reserved'),
                  _buildStatCard(width, Icons.info_outline, const Color(0xFFFFF3E0), 'PENDING USER REPORTS', currentStats['reports']!, currentStats['reports'] == '0' ? 'Inbox clear' : 'Needs attention'),
                  _buildStatCard(width, Icons.schedule, const Color(0xFFFFF3E0), 'FAILED REFUNDS', currentStats['failed']!, currentStats['failed'] == '0' ? 'No failures' : 'Action required'),
                ],
              );
            },
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
            child: _recentReservations.isEmpty
                ? const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No bookings found in database.')))
                : Column(
                    children: _recentReservations.asMap().entries.map((entry) {
                      final index = entry.key;
                      final b = entry.value;
                      final profile = b['profiles'] ?? {};
                      
                      return Column(
                        children: [
                          _buildReservationRow(
                            '#KRP-${b['id'].toString().padLeft(4, '0')}', 
                            profile['full_name'] ?? 'Unknown User', 
                            profile['matric_number'] ?? 'N/A', 
                            b['facility_name'] ?? 'Facility', 
                            '${b['booking_date'] ?? ''}\n${b['start_time'] ?? ''}'
                          ),
                          if (index != _recentReservations.length - 1) const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(double width, IconData icon, Color iconBgColor, String title, String value, String subtitle) {
    return Container(
      width: width,
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

// 🌟 Fully Connected Interactive Bottom Sheet
class _ManualBookingSheet extends StatefulWidget {
  final VoidCallback onBookingAdded;
  const _ManualBookingSheet({required this.onBookingAdded});
  
  @override
  State<_ManualBookingSheet> createState() => _ManualBookingSheetState();
}

class _ManualBookingSheetState extends State<_ManualBookingSheet> {
  final supabase = Supabase.instance.client;
  bool _isSubmitting = false;

  final _dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  String _selectedCategory = 'KRP Student';
  String _selectedFacility = 'Badminton Court 01';
  String _selectedSlot = '5:00 PM';

  int get _calculatedPrice {
    bool isKRP = _selectedCategory == 'KRP Student';
    if (_selectedFacility.contains('Badminton')) return isKRP ? 6 : 8;
    if (_selectedFacility.contains('Ping Pong')) return isKRP ? 4 : 6;
    if (_selectedFacility.contains('Snooker')) return isKRP ? 10 : 12;
    if (_selectedFacility.contains('Dart')) return isKRP ? 3 : 5;
    return 6; 
  }

  Future<void> _submitManualBooking() async {
    setState(() => _isSubmitting = true);

    try {
      final user = supabase.auth.currentUser;
      
      // Inserts the manual booking directly into the bookings table
      await supabase.from('bookings').insert({
        'user_id': user?.id, // Assigning to admin for walk-ins
        'facility_name': _selectedFacility,
        'booking_date': _dateController.text,
        'start_time': _selectedSlot,
        'amount': _calculatedPrice,
        'status': 'Paid', // Admin manual bookings are assumed paid
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manual booking added to Supabase successfully!')));
        widget.onBookingAdded(); // Refreshes the dashboard stats instantly
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding booking: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                    Text('Add manual booking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Create a reservation for a walk-in.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
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
                  _buildDropdown(_selectedCategory, ['KRP Student', 'Non-KRP Student', 'Public'], (val) => setState(() => _selectedCategory = val!)),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Facility'),
                  _buildDropdown(_selectedFacility, ['Badminton Court 01', 'Badminton Court 02', 'Ping Pong Table 01', 'Snooker Table', 'Dart Board'], (val) => setState(() => _selectedFacility = val!)),
                  const SizedBox(height: 16),
                  
                  _buildLabel('Date (YYYY-MM-DD)'),
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
                  _buildDropdown(_selectedSlot, ['5:00 PM', '6:00 PM', '8:00 PM', '9:00 PM'], (val) => setState(() => _selectedSlot = val!)),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Official $_selectedCategory price', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('RM $_calculatedPrice.00', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                    onPressed: _isSubmitting ? null : _submitManualBooking,
                    child: _isSubmitting 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)));

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}