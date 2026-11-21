import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  static const _green = Color(0xFF173F32);
  static const _storageBucket = 'report-attachments';
  final supabase = Supabase.instance.client;

  final _searchController = TextEditingController();
  String _selectedStatus = 'All';
  DateTime? _selectedDate;

  bool _isLoading = true;
  List _reports = [];

  static const _statusOptions = [
    'All',
    'Submitted',
    'Under Review',
    'Resolved',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  String _normalizeStatus(dynamic rawStatus) {
    final s = (rawStatus?.toString() ?? '').trim().toLowerCase().replaceAll('_', ' ');
    if (s == 'submitted' || s == 'open' || s == 'new' || s == 'pending') {
      return 'Submitted';
    }
    if (s == 'under review' || s == 'in review' || s == 'reviewing' || s == 'in progress') {
      return 'Under Review';
    }
    if (s == 'resolved' || s == 'closed' || s == 'completed') {
      return 'Resolved';
    }
    if (s == 'rejected' || s == 'declined' || s == 'dismissed') {
      return 'Rejected';
    }
    return rawStatus?.toString().trim().isNotEmpty == true
        ? rawStatus.toString().trim()
        : 'Submitted';
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

  String _extractDateOnly(dynamic rawDate) {
    final str = (rawDate?.toString() ?? '').trim();
    if (str.isEmpty) return '';
    final parsed = DateTime.tryParse(str);
    if (parsed != null) {
      return _formatDateIso(parsed.toLocal());
    }
    return str.length >= 10 ? str.substring(0, 10) : str;
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

  Future<String> _resolveAttachmentUrl(String rawPath) async {
    final cleaned = rawPath.trim();
    if (cleaned.isEmpty) return '';
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return cleaned;
    }

    String bucket = _storageBucket;
    String objectPath = cleaned;
    if (cleaned.contains('/')) {
      final firstSlash = cleaned.indexOf('/');
      final maybeBucket = cleaned.substring(0, firstSlash);
      if (maybeBucket == 'report-attachments' || maybeBucket == 'reports' || maybeBucket == 'attachments') {
        bucket = maybeBucket;
        objectPath = cleaned.substring(firstSlash + 1);
      }
    }

    try {
      final signed = await supabase.storage.from(bucket).createSignedUrl(objectPath, 3600);
      if (signed.isNotEmpty) return signed;
    } catch (_) {}

    return supabase.storage.from(bucket).getPublicUrl(objectPath);
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      List rows = [];
      try {
        rows = await supabase
            .from('reports')
            .select('*, profiles!reports_user_id_fkey(full_name, matric_number)')
            .order('created_at', ascending: false);
      } catch (_) {
        rows = await supabase
            .from('reports')
            .select()
            .order('created_at', ascending: false);
      }

      final userIds = <String>{};
      final bookingIds = <String>{};
      final reportIds = <String>[];

      for (final r in rows) {
        final rid = (r['id'] ?? '').toString().trim();
        if (rid.isNotEmpty) reportIds.add(rid);

        final uid = (r['user_id'] ?? '').toString().trim();
        if (uid.isNotEmpty) userIds.add(uid);

        final bid = (r['related_booking_id'] ?? '').toString().trim();
        if (bid.isNotEmpty) bookingIds.add(bid);
      }

      final profilesById = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        try {
          final profRows = await supabase
              .from('profiles')
              .select('id, full_name, matric_number')
              .inFilter('id', userIds.toList());
          for (final p in profRows) {
            final pid = (p['id'] ?? '').toString().trim();
            if (pid.isNotEmpty) {
              profilesById[pid] = Map<String, dynamic>.from(p as Map);
            }
          }
        } catch (_) {}
      }

      final bookingsById = <String, Map<String, dynamic>>{};
      if (bookingIds.isNotEmpty) {
        try {
          final bRows = await supabase
              .from('bookings')
              .select('id, facility_name, booking_date, start_time, checkout_payload')
              .inFilter('id', bookingIds.toList());
          for (final b in bRows) {
            final bid = (b['id'] ?? '').toString().trim();
            if (bid.isNotEmpty) {
              bookingsById[bid] = Map<String, dynamic>.from(b as Map);
            }
          }
        } catch (_) {}
      }

      final attachmentsByReportId = <String, List>{};
      if (reportIds.isNotEmpty) {
        try {
          final attRows = await supabase
              .from('report_attachments')
              .select()
              .inFilter('report_id', reportIds)
              .order('created_at', ascending: true);

          for (final a in attRows) {
            final rid = (a['report_id'] ?? '').toString().trim();
            final path = (a['storage_path'] ?? '').toString().trim();
            if (rid.isEmpty || path.isEmpty) continue;
            final url = await _resolveAttachmentUrl(path);
            if (url.isEmpty) continue;
            attachmentsByReportId.putIfAbsent(rid, () => []).add({
              'url': url,
              'name': (a['file_name'] ?? 'Attachment').toString(),
              'mime': (a['mime_type'] ?? '').toString(),
            });
          }
        } catch (_) {}
      }

      final mapped = rows.map((r) {
        final rawId = (r['id'] ?? '').toString().trim();
        final refCode = (r['report_reference'] ?? r['report_code'] ?? '').toString().trim();
        final displayRef = refCode.isNotEmpty
            ? refCode
            : (rawId.isNotEmpty ? 'RPT-$rawId' : 'RPT-UNKNOWN');

        final uid = (r['user_id'] ?? '').toString().trim();
        final joinedProfile = r['profiles'] is Map
            ? Map<String, dynamic>.from(r['profiles'] as Map)
            : <String, dynamic>{};
        final lookedUpProfile = uid.isNotEmpty
            ? (profilesById[uid] ?? <String, dynamic>{})
            : <String, dynamic>{};

        final userName = [
          joinedProfile['full_name'],
          lookedUpProfile['full_name'],
        ].map((v) => (v ?? '').toString().trim()).firstWhere((v) => v.isNotEmpty, orElse: () => '');

        final matric = [
          joinedProfile['matric_number'],
          lookedUpProfile['matric_number'],
        ].map((v) => (v ?? '').toString().trim()).firstWhere((v) => v.isNotEmpty, orElse: () => '');

        final bid = (r['related_booking_id'] ?? '').toString().trim();
        final booking = bid.isNotEmpty ? (bookingsById[bid] ?? <String, dynamic>{}) : <String, dynamic>{};
        String facility = (booking['facility_name'] ?? '').toString().trim();
        if (facility.isEmpty && booking['checkout_payload'] is List && (booking['checkout_payload'] as List).isNotEmpty) {
          final firstItem = (booking['checkout_payload'] as List).first;
          if (firstItem is Map) {
            facility = (firstItem['facility_name'] ?? '').toString().trim();
          }
        }

        final title = [
          r['subject'],
          r['title'],
          r['issue_type'],
        ].map((v) => (v ?? '').toString().trim()).firstWhere((v) => v.isNotEmpty, orElse: () => 'General Issue');

        final description = [
          r['description'],
          r['details'],
          r['message'],
        ].map((v) => (v ?? '').toString().trim()).firstWhere((v) => v.isNotEmpty, orElse: () => '');

        final category = (r['category'] ?? '').toString().trim();
        final rawStatus = (r['status'] ?? 'submitted').toString().trim();
        final normalizedStatus = _normalizeStatus(rawStatus);
        final dateIso = _extractDateOnly(r['created_at'] ?? r['submitted_at']);
        final adminResponse = (r['admin_response'] ?? r['admin_notes'] ?? '').toString();
        final photos = rawId.isNotEmpty ? (attachmentsByReportId[rawId] ?? []) : [];

        return {
          'id': r['id'],
          'ref': displayRef,
          'title': title,
          'description': description,
          'category': category,
          'relatedBookingId': bid,
          'facility': facility,
          'userName': userName,
          'matric': matric,
          'status': rawStatus.isEmpty ? 'submitted' : rawStatus,
          'normalizedStatus': normalizedStatus,
          'date': dateIso,
          'adminResponse': adminResponse,
          'photos': photos,
        };
      }).toList();

      if (mounted) {
        setState(() => _reports = mapped);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List get _filteredReports {
    final query = _searchController.text.trim().toLowerCase();
    final targetDateIso = _selectedDate != null ? _formatDateIso(_selectedDate!) : null;

    return _reports.where((report) {
      final matchesStatus = _selectedStatus == 'All' ||
          report['normalizedStatus'] == _selectedStatus ||
          report['status'].toString().toLowerCase() == _selectedStatus.toLowerCase();

      final reportDate = (report['date']?.toString() ?? '').trim();
      final matchesDate = targetDateIso == null || reportDate == targetDateIso;

      final searchable = [
        report['ref'],
        report['title'],
        report['description'],
        report['category'],
        report['userName'],
        report['matric'],
        report['facility'],
        report['date'],
      ].join(' ').toLowerCase();

      return matchesStatus && matchesDate && searchable.contains(query);
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = 'All';
      _selectedDate = null;
    });
  }

  Color _statusColor(String status) {
    final norm = _normalizeStatus(status);
    if (norm == 'Resolved') return const Color(0xFF237346);
    if (norm == 'Under Review') return const Color(0xFF1D5B96);
    if (norm == 'Rejected') return const Color(0xFFB13D35);
    return const Color(0xFF946000);
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showPhotoPreview(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(title, overflow: TextOverflow.ellipsis),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Unable to load photo.', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReviewDialog(Map report) async {
    String nextStatus = _normalizeStatus(report['status']);
    if (!_statusOptions.contains(nextStatus) || nextStatus == 'All') {
      nextStatus = 'Submitted';
    }
    final responseController = TextEditingController(text: (report['adminResponse'] ?? '').toString());
    final photos = (report['photos'] is List) ? (report['photos'] as List) : [];
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(report['ref'].toString()),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        report['title'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      if ((report['category'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Category: ${report['category']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                      if ((report['userName'] ?? '').toString().isNotEmpty ||
                          (report['matric'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          [
                            if ((report['userName'] ?? '').toString().isNotEmpty) report['userName'].toString(),
                            if ((report['matric'] ?? '').toString().isNotEmpty) report['matric'].toString(),
                          ].join(' · '),
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                      if ((report['facility'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Facility: ${report['facility']}', style: const TextStyle(fontSize: 13)),
                      ],
                      if ((report['relatedBookingId'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Related booking: ${report['relatedBookingId']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                      if ((report['date'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Submitted ${report['date']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                      const Divider(height: 20),
                      const Text('Problem description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9F7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          (report['description'] ?? '').toString().isNotEmpty
                              ? report['description'].toString()
                              : 'No description provided.',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (photos.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Attached photos (${photos.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: photos.map((p) {
                            final url = (p['url'] ?? '').toString();
                            final name = (p['name'] ?? 'Photo').toString();
                            return InkWell(
                              onTap: () => _showPhotoPreview(url, name),
                              borderRadius: BorderRadius.circular(10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  url,
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 110,
                                    height: 110,
                                    color: Colors.grey.shade200,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField(
                        value: nextStatus,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Update report status',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: _statusOptions
                            .where((s) => s != 'All')
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => nextStatus = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: responseController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Admin response (optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _green),
                  onPressed: saving || report['id'] == null
                      ? null
                      : () async {
                          setDialogState(() => saving = true);
                          try {
                            final dbStatus = nextStatus.toLowerCase().replaceAll(' ', '_');
                            final payload = <String, dynamic>{
                              'status': dbStatus,
                              'admin_response': responseController.text.trim(),
                              'reviewed_at': DateTime.now().toIso8601String(),
                            };
                            final currentUserId = supabase.auth.currentUser?.id;
                            if (currentUserId != null && currentUserId.isNotEmpty) {
                              payload['reviewed_by'] = currentUserId;
                            }

                            await supabase
                                .from('reports')
                                .update(payload)
                                .eq('id', report['id']);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            await _fetchReports();
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(content: Text('Report updated to $nextStatus.')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(content: Text('Failed to update report: $e')),
                              );
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => saving = false);
                            }
                          }
                        },
                  child: Text(saving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    responseController.dispose();
  }

  Widget _buildDateFilterButton() {
    final hasDate = _selectedDate != null;
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Submitted date',
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleReports = _filteredReports;

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
                  Text('User reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _green)),
                  SizedBox(height: 6),
                  Text(
                    'Review issues and update their resolution progress directly in the live database.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: _green),
                onPressed: _fetchReports,
                tooltip: 'Refresh reports',
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 820;
                final statusDropdown = DropdownButtonFormField(
                  value: _selectedStatus,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Report status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _statusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                );

                if (isCompact) {
                  return Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search reports',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: statusDropdown),
                          const SizedBox(width: 10),
                          Expanded(child: _buildDateFilterButton()),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.filter_alt_off_outlined, size: 18, color: _green),
                          label: const Text('Clear', style: TextStyle(color: _green)),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search reports',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: statusDropdown),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _buildDateFilterButton()),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.filter_alt_off_outlined, size: 18, color: _green),
                        label: const Text('Clear', style: TextStyle(color: _green)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          Text(
            '${visibleReports.length} report(s)',
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: _green),
              ),
            )
          else if (visibleReports.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.assignment_late_outlined, size: 42, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No reports match your search and filters.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            )
          else
            Column(
              children: visibleReports.map((report) {
                final photos = (report['photos'] is List) ? (report['photos'] as List) : [];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                report['ref'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _green,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _statusBadge(report['status'].toString()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report['title'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        if ((report['description'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            report['description'].toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                        ],
                        if ((report['userName'] ?? '').toString().isNotEmpty ||
                            (report['matric'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            [
                              if ((report['userName'] ?? '').toString().isNotEmpty) report['userName'].toString(),
                              if ((report['matric'] ?? '').toString().isNotEmpty) report['matric'].toString(),
                            ].join(' · '),
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                        ],
                        if ((report['facility'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Facility', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(report['facility'].toString(), style: const TextStyle(fontSize: 14)),
                        ],
                        if (photos.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.photo_library_outlined, size: 15, color: _green),
                              const SizedBox(width: 6),
                              Text(
                                '${photos.length} photo(s) attached',
                                style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                        if ((report['date'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Submitted ${report['date']}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openReviewDialog(report),
                            icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.black87),
                            label: const Text('View / Update', style: TextStyle(color: Colors.black87)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}