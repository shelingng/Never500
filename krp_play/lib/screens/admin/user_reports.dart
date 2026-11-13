import 'package:flutter/material.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  static const _green = Color(0xFF173F32);

  static const _statuses = [
    'Submitted',
    'Under Review',
    'Resolved',
    'Rejected',
  ];

  final _searchController = TextEditingController();
  String _selectedStatus = 'All';

  // Fictional examples for UI testing only.
  final List _reports = [
    {
      'id': 'DEMO-RPT-003',
      'name': 'Sample Student A',
      'matric': 'DEMO-001',
      'facility': 'Badminton Court 01',
      'booking': 'DEMO-1842',
      'date': '12 Nov 2026',
      'subject': 'Court lighting issue',
      'description':
          'One light above the court flickers during play. '
          'Please check the lighting before the next session.',
      'status': 'Submitted',
      'response': '',
    },
    {
      'id': 'DEMO-RPT-002',
      'name': 'Sample Student B',
      'matric': 'DEMO-002',
      'facility': 'Ping Pong Table 02',
      'booking': 'DEMO-1841',
      'date': '11 Nov 2026',
      'subject': 'Damaged table net',
      'description': 'The table net is loose and cannot be tightened properly.',
      'status': 'Under Review',
      'response': 'The sports unit is checking the equipment.',
    },
    {
      'id': 'DEMO-RPT-001',
      'name': 'Sample Student C',
      'matric': 'DEMO-003',
      'facility': 'Snooker Table',
      'booking': 'Not provided',
      'date': '10 Nov 2026',
      'subject': 'Missing equipment',
      'description': 'A cue was missing from the equipment rack.',
      'status': 'Resolved',
      'response': 'Replacement equipment has been provided.',
    },
  ];

   get _filteredReports {
    final query = _searchController.text.trim().toLowerCase();

    return _reports.where((report) {
      final matchesStatus =
          _selectedStatus == 'All' || report['status'] == _selectedStatus;

      final searchable = [
        report['id'] ?? '',
        report['name'] ?? '',
        report['matric'] ?? '',
        report['facility'] ?? '',
        report['booking'] ?? '',
        report['subject'] ?? '',
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
    switch (status) {
      case 'Submitted':
        return const Color(0xFF946000);
      case 'Under Review':
        return const Color(0xFF2665A6);
      case 'Resolved':
        return const Color(0xFF237346);
      case 'Rejected':
        return const Color(0xFFB13D35);
      default:
        return Colors.blueGrey;
    }
  }

  Widget _badge(String status) {
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

  Future<void> _openReport(Map<String, String> report) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _ReportDetailsDialog(report: Map<String, String>.from(report)),
    );

    if (!mounted || result == null) return;

    setState(() {
      report['status'] = result['status']!;
      report['response'] = result['response']!;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo report updated. No notification was sent.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = _filteredReports;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SUPPORT INBOX',
            style: TextStyle(
              color: _green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'User reports',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review issues and update their resolution progress.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Demo data — reports are fictional. Updates are local '
              'and reset when the app restarts.',
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
                    labelText: 'Search reports',
                    hintText: 'Report ID, student, facility or subject',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                
                // 🌟 FIX: Updated layout to match the screenshot for responsiveness
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 2, // Gives the dropdown more width 
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(_selectedStatus),
                            initialValue: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Report status',
                              border: OutlineInputBorder(),
                            ),
                            items: ['All', ..._statuses]
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status,
                                      overflow: TextOverflow.ellipsis, // Prevents overflow on small screens
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedStatus = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1, // Ensures the button fits neatly beside it
                          child: Align(
                            alignment: Alignment.center,
                            child: TextButton.icon(
                              onPressed: _clearFilters,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                              ),
                              icon: const Icon(Icons.filter_alt_off_outlined, color: _green, size: 18),
                              label: const Text('Clear filters', style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${reports.length} report(s)',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          if (reports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.search_off, size: 44, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'No reports match your search and filters.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...reports.map(
              (report) => Card(
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
                          Text(
                            report['id']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _green,
                            ),
                          ),
                          _badge(report['status']!),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        report['subject']!,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${report['name']} · ${report['matric']}'),
                      _detail('Facility', report['facility']!),
                      Text(
                        'Submitted ${report['date']}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // 🌟 FIX: Full-width button matching the screenshot on mobile
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openReport(report),
                          icon: const Icon(Icons.visibility_outlined, color: Colors.black87),
                          label: const Text('View / Update', style: TextStyle(color: Colors.black87)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportDetailsDialog extends StatefulWidget {
  final Map<String, String> report;

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
    _status = widget.report['status']!;
    _responseController = TextEditingController(
      text: widget.report['response'] ?? '',
    );
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
      title: Text(report['id']!),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('Subject', report['subject']!),
                _section('Student', '${report['name']} · ${report['matric']}'),
                _section('Facility', report['facility']!),
                _section('Booking reference', report['booking']!),
                _section('Submitted', report['date']!),
                _section('Description', report['description']!),
                if (report['id'] == 'DEMO-RPT-003') ...[
                  const Text(
                    'Supporting evidence',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/court_lighting_demo.png',
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('Unable to load attachment.');
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Attachment: court_lighting_demo.png',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                ] else
                  _section('Supporting evidence', 'No attachment provided.'),
                const Divider(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Submitted',
                      child: Text('Submitted'),
                    ),
                    DropdownMenuItem(
                      value: 'Under Review',
                      child: Text('Under Review'),
                    ),
                    DropdownMenuItem(
                      value: 'Resolved',
                      child: Text('Resolved'),
                    ),
                    DropdownMenuItem(
                      value: 'Rejected',
                      child: Text('Rejected'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
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
                    final needsResponse =
                        _status == 'Resolved' || _status == 'Rejected';

                    if (needsResponse &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Explain why this report is $_status.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Demo only. Saving does not notify the student.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save demo update')),
      ],
    );
  }
}