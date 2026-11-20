import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  static const _green = Color(0xFF173F32);
  final supabase = Supabase.instance.client;

  static const _statuses = ['Submitted', 'Under Review', 'Resolved', 'Rejected'];

  final _searchController = TextEditingController();
  String _selectedStatus = 'All';

  bool _isLoading = true;
  List _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('reports')
          .select('*, profiles!reports_user_id_fkey(full_name, matric_number)')
          .order('created_at', ascending: false);

      final mappedReports = response.map((r) {
        final p = r['profiles'] ?? {};
        // Format date string safely
        String formattedDate = '';
        if (r['created_at'] != null) {
          final d = DateTime.tryParse(r['created_at'].toString());
          if (d != null) formattedDate = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        }

        return {
          'db_id': r['id'], // Actual database ID for updating
          'id': 'RPT-${r['id'].toString().padLeft(4, '0')}',
          'name': p['full_name'] ?? 'Unknown User',
          'matric': p['matric_number'] ?? 'N/A',
          'facility': r['facility_name'] ?? 'Facility Not Specified',
          'booking': r['booking_id'] != null ? '#KRP-${r['booking_id'].toString().padLeft(4,'0')}' : 'General',
          'date': formattedDate,
          'subject': r['issue_type'] ?? 'General Issue',
          'description': r['description'] ?? 'No description provided.',
          'status': r['status'] ?? 'Submitted',
          'response': r['admin_response'] ?? '',
          'image_url': r['image_url'], // If you have images
        };
      }).toList();

      if (mounted) setState(() => _reports = mappedReports);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading reports: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List get _filteredReports {
    final query = _searchController.text.trim().toLowerCase();
    return _reports.where((report) {
      final matchesStatus = _selectedStatus == 'All' || report['status'] == _selectedStatus;
      final searchable = [
        report['id'], report['name'], report['matric'], report['facility'], report['subject']
      ].join(' ').toLowerCase();
      return matchesStatus && searchable.contains(query);
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
      _selectedStatus = 'All';
    });
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'submitted') return const Color(0xFF946000);
    if (s == 'under review') return const Color(0xFF2665A6);
    if (s == 'resolved') return const Color(0xFF237346);
    if (s == 'rejected') return const Color(0xFFB13D35);
    return Colors.blueGrey;
  }

  Widget _badge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withAlpha(22), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _openReport(Map<String, dynamic> report) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReportDetailsDialog(report: report),
    );

    if (!mounted || result == null) return;

    try {
      // 🌟 Update Supabase Database
      await supabase.from('reports').update({
        'status': result['status'],
        'admin_response': result['response'],
      }).eq('id', report['db_id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report updated successfully!')));
        _fetchReports(); // Refresh the list
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating report: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reports = _filteredReports;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('SUPPORT INBOX', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                  SizedBox(height: 8),
                  Text('User reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _green)),
                ],
              ),
              IconButton(icon: const Icon(Icons.refresh, color: _green), onPressed: _fetchReports)
            ],
          ),
          const SizedBox(height: 8),
          const Text('Review issues and update their resolution progress directly in the live database.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8E3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(labelText: 'Search reports', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_selectedStatus),
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(labelText: 'Report status', border: OutlineInputBorder()),
                        items: ['All', ..._statuses].map((status) => DropdownMenuItem(value: status, child: Text(status, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (value) { if (value != null) setState(() => _selectedStatus = value); },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextButton.icon(onPressed: _clearFilters, icon: const Icon(Icons.filter_alt_off_outlined, color: _green, size: 18), label: const Text('Clear', style: TextStyle(color: _green, fontWeight: FontWeight.w600))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('${reports.length} report(s)', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 12),
          
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: _green)))
          else if (reports.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: Text('No reports match your filters.')))
          else
            ...reports.map((report) => Card(
              margin: const EdgeInsets.only(bottom: 14),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(report['id'], style: const TextStyle(fontWeight: FontWeight.bold, color: _green)),
                        _badge(report['status']),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(report['subject'], style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${report['name']} · ${report['matric']}'),
                    _detail('Facility', report['facility']),
                    Text('Submitted ${report['date']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openReport(report),
                        icon: const Icon(Icons.visibility_outlined, color: Colors.black87),
                        label: const Text('View / Update', style: TextStyle(color: Colors.black87)),
                      ),
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }
}

class _ReportDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> report;
  const _ReportDetailsDialog({required this.report});

  @override
  State<_ReportDetailsDialog> createState() => _ReportDetailsDialogState();
}

class _ReportDetailsDialogState extends State<_ReportDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _status;
  late final TextEditingController _responseController;

  @override
  void initState() {
    super.initState();
    _status = widget.report['status'];
    // Prevent dropdown crashes if DB status is something unexpected
    if (!['Submitted', 'Under Review', 'Resolved', 'Rejected'].contains(_status)) {
      _status = 'Submitted';
    }
    _responseController = TextEditingController(text: widget.report['response']);
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'status': _status,
      'response': _responseController.text.trim(),
    });
  }

  Widget _section(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return AlertDialog(
      title: Text(report['id']),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('Subject', report['subject']),
                _section('Student', '${report['name']} · ${report['matric']}'),
                _section('Facility', report['facility']),
                _section('Booking reference', report['booking']),
                _section('Submitted', report['date']),
                _section('Description', report['description']),
                
                if (report['image_url'] != null && report['image_url'].toString().isNotEmpty) ...[
                  const Text('Supporting evidence', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      report['image_url'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Text('Unable to load attachment from Supabase.'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  _section('Supporting evidence', 'No image attachment provided.'),
                
                const Divider(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Submitted', child: Text('Submitted')),
                    DropdownMenuItem(value: 'Under Review', child: Text('Under Review')),
                    DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                    DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) { if (value != null) setState(() => _status = value); },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _responseController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Response to student',
                    hintText: 'Explain the action taken or decision.',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final needsResponse = _status == 'Resolved' || _status == 'Rejected';
                    if (needsResponse && (value == null || value.trim().isEmpty)) {
                      return 'Explain why this report is $_status.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF173F32)), child: const Text('Update live database')),
      ],
    );
  }
}