part of 'profile_screen.dart';

final Map<String, List<_ReportPhoto>> prototypePhotoCache = {};

class _ReportPhoto {
  final String name;
  final Uint8List bytes;

  const _ReportPhoto({required this.name, required this.bytes});
}

class _LocalReport {
  final String id;
  final String category;
  final String title;
  final String facility;
  final String dateTime;
  final String description;
  final List<_ReportPhoto> photos;
  final String? samplePhotoAsset;
  final String status;

  const _LocalReport({
    required this.id,
    required this.category,
    required this.title,
    required this.facility,
    required this.dateTime,
    required this.description,
    required this.photos,
    this.samplePhotoAsset,
    this.status = 'Submitted',
  });
}

abstract class _ProfileSectionsState extends State<ProfileScreen> {
  bool _showReport = false;
  String _reportCategory = 'Booking Issue';
  String? _bookingId;
  final _reportTitle = TextEditingController();
  final _description = TextEditingController();

  final List<_LocalReport> _reports = [];
  bool _isLoadingReports = true;
  bool _isSubmittingReport = false;

  final _draftPhotos = <_ReportPhoto>[];
  final Map<String, List<_ReportPhoto>> _photoCache = {};
  bool _pickingPhoto = false;

  static const _maxPhotos = 3;
  static const _maxPhotoBytes = 5 * 1024 * 1024;

  static const _categories = [
    'Booking Issue',
    'Payment Issue',
    'Facility Problem',
    'Account Issue',
    'Other',
  ];

  List<Booking> get _bookings;

  @override
  void initState() {
    super.initState();
    _fetchLiveReports();
  }

  Future<void> _fetchLiveReports() async {
    try {
      final results = await BookingService().getUserReports();
      if (mounted) {
        setState(() {
          _reports.clear();
          for (var row in results) {
            String facilityName = 'General inquiry';
            if (row['related_booking_id'] != null) {
              try {
                facilityName = _bookings
                    .firstWhere((b) => b.id == row['related_booking_id'])
                    .facilityName;
              } catch (_) {
                facilityName = 'Linked Booking';
              }
            }

            String uiCategory = 'Other';
            if (row['category'] == 'booking_issue') uiCategory = 'Booking Issue';
            if (row['category'] == 'payment_issue') uiCategory = 'Payment Issue';
            if (row['category'] == 'facility_problem') {
              uiCategory = 'Facility Problem';
            }
            if (row['category'] == 'account_issue') uiCategory = 'Account Issue';

            final createdAt = row['created_at'] != null
                ? DateTime.parse(row['created_at'].toString()).toLocal()
                : DateTime.now();

            final desc = (row['description'] ?? '').toString();
            final subj = (row['subject'] ?? '').toString().trim();

            _reports.add(_LocalReport(
              id: row['report_reference'] ??
                  row['id'].toString().substring(0, 8),
              category: uiCategory,
              title: subj.isNotEmpty ? subj : 'Facility report',
              facility: facilityName,
              dateTime: '${_shortDate(createdAt)} · ${_clockTime(createdAt)}',
              description: desc,
              photos: prototypePhotoCache[desc] ?? const [],
              status: row['status'] == 'submitted'
                  ? 'Submitted'
                  : row['status'] == 'under_review'
                      ? 'Under Review'
                      : row['status'] == 'resolved'
                          ? 'Resolved'
                          : 'Rejected',
            ));
          }
          _isLoadingReports = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReports = false);
    }
  }

  @override
  void dispose() {
    _reportTitle.dispose();
    _description.dispose();
    super.dispose();
  }

  Widget _refundRequests() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(
            color: const Color(0xFFEFF4EF),
            child: const Text(
              'Students cannot cancel bookings or submit refund requests. KRP Management handles eligible refunds when a booked facility is closed, under maintenance, or otherwise unavailable. Students can view refund progress here.',
              style: TextStyle(height: 1.4),
            ),
          ),
          const SizedBox(height: 8),
          _refundCard(
            'BK-2026-0317',
            'Badminton Court 01',
            'Facility closed for maintenance',
            'FPX Online Banking · Maybank',
            'Bank Transfer',
            'PROCESSING',
          ),
          _refundCard(
            'BK-2026-0302',
            'Badminton Court 02',
            'Court unavailable by admin',
            'Touch \'n Go eWallet',
            'TNG eWallet',
            'REFUNDED',
          ),
          _refundCard(
            'BK-2026-0224',
            'Ping Pong Table 01',
            'Refund processing failed; management will retry',
            'FPX Online Banking · CIMB Bank',
            'Manual (Admin)',
            'FAILED',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'Demo refund status only. Processing times depend on the payment provider; no transaction is performed in this prototype.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );

  Widget _refundCard(
    String id,
    String court,
    String reason,
    String payment,
    String method,
    String status,
  ) {
    final color = status == 'REFUNDED'
        ? _green
        : status == 'FAILED'
            ? const Color(0xFFB3261E)
            : const Color(0xFFB36B00);
    final background = status == 'REFUNDED'
        ? _pale
        : status == 'FAILED'
            ? const Color(0xFFFCE8E6)
            : const Color(0xFFFFF0D8);
    return _card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
              _badge(status, background, color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            court,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _labelValue('Reason', reason),
          _labelValue('Payment method', payment),
          _labelValue('Refund method', method),
        ],
      ),
    );
  }

  Widget _myReports() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _card(
            color: const Color(0xFFEFF4EF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How can we help?',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _contactBox(
                        Icons.support_agent,
                        'Admin contact',
                        'krp@university.edu',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _contactBox(
                        Icons.location_on_outlined,
                        'Visit us',
                        'KRP Sports Centre',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Reports and photo attachments sync to the live database so admins can review details and photos.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          if (!_showReport)
            FilledButton.icon(
              onPressed: () => setState(() => _showReport = true),
              icon: const Icon(Icons.add),
              label: const Text('Create Report'),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                minimumSize: const Size.fromHeight(48),
              ),
            )
          else
            _reportForm(),
          const SizedBox(height: 18),
          const Text(
            'Submitted reports',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          if (_isLoadingReports)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: _green)),
            )
          else if (_reports.isEmpty)
            _empty(
              Icons.description_outlined,
              'No reports submitted',
              'Reports you submit will be listed here.',
            )
          else
            ..._reports.map(_reportCard),
        ],
      );

  Widget _reportForm() {
    final bookings = _bookings;
    final bookingValue =
        bookings.any((item) => item.id == _bookingId) ? _bookingId : null;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create a report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField(
            value: _reportCategory,
            decoration: const InputDecoration(
              labelText: 'Report category',
              border: OutlineInputBorder(),
            ),
            items: _ProfileSectionsState._categories
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(
              () => _reportCategory = value?.toString() ?? _reportCategory,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: bookingValue,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Related booking (optional)',
              border: OutlineInputBorder(),
            ),
            items: bookings
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id.toString(),
                    child: Text(
                      '${item.id} - ${item.facilityName} - ${item.date.day} ${_month(item.date.month)} ${_bookingTime(item)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: bookings.isEmpty
                ? null
                : (value) => setState(() => _bookingId = value?.toString()),
          ),
          if (bookings.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'No bookings available to link.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _reportTitle,
            decoration: const InputDecoration(
              labelText: 'Report title',
              hintText: 'e.g., Broken badminton net on Court 01',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Problem description',
              hintText: 'Tell us what happened...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Photos (optional)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Up to 3 JPG or PNG photos, 5 MB each. '
            'Tap a photo to enlarge it.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          if (_draftPhotos.isNotEmpty) ...[
            _photoGrid(_draftPhotos, editable: true),
            const SizedBox(height: 10),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _pickingPhoto || _draftPhotos.length >= _maxPhotos
                  ? null
                  : _pickReportPhoto,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _pickingPhoto
                    ? 'Reading photo...'
                    : 'Add photo (${_draftPhotos.length}/$_maxPhotos)',
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _pickingPhoto || _isSubmittingReport ? null : _submitReport,
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _isSubmittingReport
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Submit report'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReportPhoto() async {
    if (_pickingPhoto || _draftPhotos.length >= _maxPhotos) return;
    setState(() => _pickingPhoto = true);

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      if (!mounted || file == null) return;

      final extension = file.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        _message('Choose a JPG or PNG photo.');
        return;
      }

      final size = await file.length();
      if (!mounted) return;
      if (size == null || size <= 0 || size > _maxPhotoBytes) {
        _message('Choose a non-empty photo no larger than 5 MB.');
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > _maxPhotoBytes) {
        _message('Choose a non-empty photo no larger than 5 MB.');
        return;
      }

      final jpeg = bytes.length >= 3 &&
          bytes[0] == 0xFF &&
          bytes[1] == 0xD8 &&
          bytes[2] == 0xFF;
      final png = bytes.length >= 8 &&
          listEquals(bytes.sublist(0, 8), [
            0x89,
            0x50,
            0x4E,
            0x47,
            0x0D,
            0x0A,
            0x1A,
            0x0A,
          ]);
      if (!jpeg && !png) {
        _message('This file is not a valid JPG or PNG photo.');
        return;
      }

      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 1,
        targetHeight: 1,
      );
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      if (!mounted) return;
      if (_draftPhotos.any((photo) => listEquals(photo.bytes, bytes))) {
        _message('That photo is already attached.');
        return;
      }
      setState(() {
        _draftPhotos.add(_ReportPhoto(name: file.name, bytes: bytes));
      });
    } catch (_) {
      if (mounted) {
        _message('Could not open this photo. Try another JPG or PNG.');
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  void _openPhoto(_ReportPhoto photo) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(photo.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: SizedBox(
          width: 640,
          height: MediaQuery.sizeOf(dialogContext).height * 0.55,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.memory(
                photo.bytes,
                fit: BoxFit.contain,
                cacheWidth: 1600,
                errorBuilder: (_, error, stackTrace) =>
                    const Text('Unable to display this photo.'),
              ),
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

  Widget _photoGrid(List<_ReportPhoto> photos, {bool editable = false}) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: photos
          .map(
            (photo) => SizedBox(
              width: 128,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Material(
                      color: _pale,
                      child: InkWell(
                        onTap: () => _openPhoto(photo),
                        child: SizedBox(
                          width: 128,
                          height: 96,
                          child: Image.memory(
                            photo.bytes,
                            fit: BoxFit.cover,
                            cacheWidth: 384,
                            semanticLabel: 'Report photo: ${photo.name}',
                            errorBuilder: (_, error, stackTrace) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    photo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  if (editable)
                    TextButton.icon(
                      onPressed: _pickingPhoto
                          ? null
                          : () {
                              setState(() => _draftPhotos.remove(photo));
                            },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Remove'),
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  void _submitReport() async {
    if (_pickingPhoto || _isSubmittingReport) return;

    final title = _reportTitle.text.trim();
    final description = _description.text.trim();

    if (title.isEmpty) {
      _message('Please enter a report title.');
      return;
    }
    if (description.isEmpty) {
      _message('Please describe the problem.');
      return;
    }

    setState(() => _isSubmittingReport = true);
    _photoCache[description] = List.from(_draftPhotos);

    try {
      prototypePhotoCache[description] = List.from(_draftPhotos);

      await BookingService().createReport(
        category: _reportCategory,
        bookingId: _bookingId,
        subject: title,
        description: description,
        photos: _draftPhotos
            .map((p) => ReportPhotoUpload(name: p.name, bytes: p.bytes))
            .toList(),
      );

      _message('Report submitted successfully!');

      await _fetchLiveReports();

      setState(() {
        _reportTitle.clear();
        _description.clear();
        _draftPhotos.clear();
        _bookingId = null;
        _reportCategory = _ProfileSectionsState._categories.first;
        _showReport = false;
      });
    } catch (e) {
      _message('Error submitting report: $e');
    } finally {
      if (mounted) setState(() => _isSubmittingReport = false);
    }
  }

  Widget _reportCard(_LocalReport report) {
    final cachedPhotos = prototypePhotoCache[report.description] ?? report.photos;
    final hasPhoto = cachedPhotos.isNotEmpty || report.samplePhotoAsset != null;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shadowColor: const Color(0x221A332C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _green,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            if (report.description.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF66756D),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _reportTag(
                  report.category,
                  const Color(0xFFEAF0EC),
                  const Color(0xFF52645A),
                ),
                _reportStatusTag(report.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.event_note_outlined,
                  size: 17,
                  color: Color(0xFF66756D),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '${report.facility} · ${report.dateTime}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (hasPhoto) ...[
              const SizedBox(height: 12),
              _reportThumbnails(_LocalReport(
                id: report.id,
                category: report.category,
                title: report.title,
                facility: report.facility,
                dateTime: report.dateTime,
                description: report.description,
                photos: cachedPhotos,
                samplePhotoAsset: report.samplePhotoAsset,
                status: report.status,
              )),
            ],
            const SizedBox(height: 12),
            Text(
              'REPORT ID  ${report.id}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9AA59E),
                fontSize: 9,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportThumbnails(_LocalReport report) {
    if (report.photos.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 96,
          height: 72,
          child: Image.asset(report.samplePhotoAsset!, fit: BoxFit.cover),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: report.photos.map((photo) {
        return GestureDetector(
          onTap: () => _openPhoto(photo),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 96,
              height: 72,
              child: Image.memory(
                photo.bytes,
                fit: BoxFit.cover,
                cacheWidth: 288,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _reportStatusTag(String status) {
    final color = switch (status) {
      'Submitted' => const Color(0xFF946000),
      'Under Review' => const Color(0xFF2665A6),
      'Resolved' => const Color(0xFF237346),
      'Rejected' => const Color(0xFFB13D35),
      _ => const Color(0xFF66756D),
    };
    return _reportTag(status, color.withValues(alpha: 0.12), color);
  }

  Widget _reportTag(String label, Color background, Color foreground) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _contactBox(IconData icon, String title, String value) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: _green),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

  Widget _info(IconData icon, String title, String value) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFC5F84B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF45635A)),
        ],
      );

  Widget _labelValue(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

  Widget _badge(String text, Color background, Color foreground) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _empty(IconData icon, String title, String subtitle) => _card(
        child: Column(
          children: [
            Icon(icon, color: _green, size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _card({
    required Widget child,
    Color color = Colors.white,
    EdgeInsets margin = EdgeInsets.zero,
  }) =>
      Card(
        color: color,
        margin: margin,
        elevation: 2,
        shadowColor: const Color(0x221A332C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  int _start(Booking booking) =>
      booking.timeSlots.map(_minutes).reduce((a, b) => a < b ? a : b);

  String _bookingTime(Booking booking) {
    if (booking.timeSlots.isEmpty) return 'Time TBD';
    final slots = booking.timeSlots.map((e) => _minutes(e.toString())).toList()
      ..sort();
    return '${_timeLabel(slots.first)} - ${_timeLabel(slots.last + 60)}';
  }

  int _minutes(String time) {
    try {
      final parts = time.split(' ');
      final clock = parts.first.split(':');
      var hour = int.parse(clock[0]);
      if (parts.last.toUpperCase() == 'PM' && hour != 12) hour += 12;
      if (parts.last.toUpperCase() == 'AM' && hour == 12) hour = 0;
      return hour * 60 + int.parse(clock[1]);
    } catch (_) {
      return 0;
    }
  }

  String _timeLabel(int minutes) {
    final hour24 = (minutes % 1440) ~/ 60;
    final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour:${(minutes % 60).toString().padLeft(2, '0')} ${hour24 < 12 ? 'AM' : 'PM'}';
  }

  String _month(int month) => const [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ][month - 1];

  String _shortDate(DateTime date) =>
      '${date.day} ${_month(date.month)} ${date.year}';

  String _clockTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
  }
}