part of 'profile_screen.dart';

abstract class _ProfileSectionsState extends State<ProfileScreen> {
  bool _showReport = false;
  String _reportCategory = 'Booking Issue';
  String? _bookingId;
  final _description = TextEditingController();
  final _reports = <Map<String, String>>[];

  static const _categories = [
    'Booking Issue',
    'Payment Issue',
    'Facility Problem',
    'Account Issue',
    'Other',
  ];

  List<Booking> get _bookings;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Widget _refundRequests() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _card(
        color: const Color(0xFFEFF4EF),
        child: const Text(
          'Refund eligibility: Bookings cannot be cancelled by users. Refunds can only be requested when the facility is closed, under maintenance, or made unavailable by an admin.',
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
        'Insufficient closure evidence',
        'FPX Online Banking · CIMB Bank',
        'Manual (Admin)',
        'REJECTED',
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          'Bank/TNG refunds may take a few business days to process.',
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
        : status == 'REJECTED'
        ? const Color(0xFFB3261E)
        : const Color(0xFFB36B00);
    final background = status == 'REFUNDED'
        ? _pale
        : status == 'REJECTED'
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
      if (_reports.isEmpty)
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
    final bookingValue = bookings.any((item) => item.id == _bookingId)
        ? _bookingId
        : null;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create a report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _reportCategory,
            decoration: const InputDecoration(
              labelText: 'Report category',
              border: OutlineInputBorder(),
            ),
            items: _ProfileSectionsState._categories
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _reportCategory = value ?? _reportCategory),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: bookingValue,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Related booking (optional)',
              border: OutlineInputBorder(),
            ),
            items: bookings
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(
                      '${item.id} - ${item.facilityName} - ${item.date.day} ${_month(item.date.month)} ${_bookingTime(item)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: bookings.isEmpty
                ? null
                : (value) => setState(() => _bookingId = value),
          ),
          if (bookings.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'No past bookings available.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
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
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitReport,
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _submitReport() {
    final description = _description.text.trim();
    if (description.isEmpty) {
      _message('Please describe the problem.');
      return;
    }
    final related = _bookings.where((item) => item.id == _bookingId);
    final booking = related.isEmpty ? null : related.first;
    setState(() {
      _reports.insert(0, {
        'category': _reportCategory,
        'date': _shortDate(DateTime.now()),
        'booking': booking == null
            ? 'No related booking'
            : '${booking.id} - ${booking.facilityName} - ${booking.date.day} ${_month(booking.date.month)} ${_bookingTime(booking)}',
        'description': description,
        'status': 'Under Review',
      });
      _description.clear();
      _showReport = false;
    });
  }

  Widget _reportCard(Map<String, String> report) => _card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _badge(report['category']!, _pale, _green),
            Text(
              report['status']!,
              style: const TextStyle(
                color: _green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Submitted ${report['date']}',
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          report['booking']!,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(report['description']!),
      ],
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

  Widget _info(IconData icon, String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, color: _green),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
  }) => Card(
    color: color,
    margin: margin,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  int _start(Booking booking) =>
      booking.timeSlots.map(_minutes).reduce((a, b) => a < b ? a : b);

  String _bookingTime(Booking booking) {
    final slots = booking.timeSlots.map(_minutes).toList()..sort();
    return '${_timeLabel(slots.first)} - ${_timeLabel(slots.last + 60)}';
  }

  int _minutes(String time) {
    final parts = time.split(' ');
    final clock = parts.first.split(':');
    var hour = int.parse(clock[0]);
    if (parts.last.toUpperCase() == 'PM' && hour != 12) hour += 12;
    if (parts.last.toUpperCase() == 'AM' && hour == 12) hour = 0;
    return hour * 60 + int.parse(clock[1]);
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
}
