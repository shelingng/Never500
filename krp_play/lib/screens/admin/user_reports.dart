import 'package:flutter/material.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('— SUPPORT INBOX', style: TextStyle(color: Color(0xFF173F32), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('User reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0D211A))),
          const SizedBox(height: 8),
          const Text('Review student issues, supporting evidence and resolution progress from one shared record.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search name, matric or report ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: ['All', 'Submitted', 'Under Review', 'Resolved', 'Rejected'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedStatus = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('No reports match the selected filters.', style: TextStyle(color: Colors.grey))),
          ),
        ],
      ),
    );
  }
}