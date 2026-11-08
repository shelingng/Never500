import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/student_account.dart';
import '../services/booking_service.dart';

const _profileGreen = Color(0xFF0F3F2F);
const _profilePaleGreen = Color(0xFFE5EFE9);
const _profileTextMuted = Color(0xFF65746B);

class ProfileScreen extends StatefulWidget {
  final StudentAccount account;

  const ProfileScreen({super.key, required this.account});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late String _name;
  late String _email;
  late String _contact;
  late String _matric;
  late String _category;
  late String _faculty;
  final List<_SubmittedReport> _reports = [];
  final List<_RefundRequest> _refundRequests = const [
    _RefundRequest(
      bookingId: 'BK-20261107-01',
      facility: 'Badminton Court 01',
      reason: 'Facility closed for maintenance',
      paymentMethod: 'FPX · Maybank',
      refundMethod: 'Bank Transfer',
      status: 'PROCESSING',
    ),
    _RefundRequest(
      bookingId: 'BK-20261022-04',
      facility: 'Ping Pong Table 01',
      reason: 'Court unavailable on booking date',
      paymentMethod: "Touch 'n Go eWallet",
      refundMethod: 'TNG eWallet',
      status: 'REFUNDED',
    ),
    _RefundRequest(
      bookingId: 'BK-20261015-02',
      facility: 'Snooker Table',
      reason: 'Duplicate refund request',
      paymentMethod: 'FPX · CIMB Bank',
      refundMethod: 'Manual (Admin)',
      status: 'REJECTED',
    ),
  ];

  List<Booking> get _bookings =>
      BookingService().getBookingsByEmail(widget.account.email);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _name = widget.account.fullName;
    _email = widget.account.email;
    _contact = widget.account.contact;
    _matric = widget.account.matric;
    _category = widget.account.category;
    _faculty = widget.account.faculty;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void openEditProfile() {
    _tabController.animateTo(0);
    setState(() {});
  }

  void showBookings() => _tabController.animateTo(1);

  void showReports() => _tabController.animateTo(3);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileHeaderCard(
          name: _name,
          email: _email,
          matric: _matric,
          faculty: _faculty,
          category: _category,
          onEdit: openEditProfile,
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: _profileGreen,
          unselectedLabelColor: _profileTextMuted,
          indicatorColor: _profileGreen,
          indicatorWeight: 3,
          tabs: [
            const Tab(text: 'Personal details 👤'),
            Tab(
              child: _TabLabel(
                text: 'My bookings 📅',
                badge: _bookings.length,
              ),
            ),
            Tab(
              child: _TabLabel(
                text: 'Refund requests 💸',
                badge: _refundRequests.length,
              ),
            ),
            const Tab(text: 'My reports 📝'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PersonalDetailsTab(
                name: _name,
                email: _email,
                contact: _contact,
                matric: _matric,
                category: _category,
                onSave: (details) {
                  setState(() {
                    _name = details.name;
                    _email = details.email;
                    _contact = details.contact;
                    _matric = details.matric;
                    _category = details.category;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile changes saved for this session.'),
                    ),
                  );
                },
              ),
              _MyBookingsTab(bookings: _bookings),
              _RefundRequestsTab(requests: _refundRequests),
              _MyReportsTab(
                bookings: _bookings,
                reports: _reports,
                onSubmit: (report) =>
                    setState(() => _reports.insert(0, report)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String matric;
  final String faculty;
  final String category;
  final VoidCallback onEdit;

  const _ProfileHeaderCard({
    required this.name,
    required this.email,
    required this.matric,
    required this.faculty,
    required this.category,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _profileGreen,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _profileGreen.withValues(alpha: .16),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFB7E28A),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    color: _profileGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Edit profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD4F048),
                  side: const BorderSide(color: Color(0x66D4F048)),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _HeaderPill(
                text: 'STUDENT ACCOUNT',
                background: const Color(0x332D7655),
                foreground: const Color(0xFFD4F048),
              ),
              _HeaderPill(
                text: category.toUpperCase(),
                background: const Color(0x22FFFFFF),
                foreground: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 11),
          _ProfileMetaLine(
            label: 'MATRIC',
            value: matric.isEmpty ? 'Not provided' : matric,
          ),
          const SizedBox(height: 7),
          _ProfileMetaLine(label: 'FACULTY', value: faculty),
          const SizedBox(height: 7),
          _ProfileMetaLine(label: 'EMAIL', value: email),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _HeaderPill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: foreground.withValues(alpha: .3)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: foreground,
        fontSize: 9,
        letterSpacing: .5,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _ProfileMetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileMetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 61,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB7C7BC),
            fontSize: 9,
            letterSpacing: .5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    ],
  );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  final words = parts.toList();
  if (words.isEmpty) return '?';
  final nameParts = words.length > 2 ? words.skip(words.length - 2) : words;
  return nameParts.map((part) => part[0].toUpperCase()).join();
}

class _TabLabel extends StatelessWidget {
  final String text;
  final int badge;

  const _TabLabel({required this.text, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (badge > 0) ...[
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _profilePaleGreen,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$badge',
              style: const TextStyle(
                color: _profileGreen,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PersonalDetailsTab extends StatefulWidget {
  final String name;
  final String email;
  final String contact;
  final String matric;
  final String category;
  final ValueChanged<_PersonalDetails> onSave;

  const _PersonalDetailsTab({
    required this.name,
    required this.email,
    required this.contact,
    required this.matric,
    required this.category,
    required this.onSave,
  });

  @override
  State<_PersonalDetailsTab> createState() => _PersonalDetailsTabState();
}

class _PersonalDetailsTabState extends State<_PersonalDetailsTab> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _contactController;
  late final TextEditingController _matricController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _category = 'KRP Student';
  bool _confirmed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _contactController = TextEditingController(text: widget.contact);
    _matricController = TextEditingController(text: widget.matric);
    _category = widget.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _matricController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_confirmed) {
      setState(() => _error = 'Please confirm your information is accurate.');
      return;
    }
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    widget.onSave(
      _PersonalDetails(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        contact: _contactController.text.trim(),
        matric: _matricController.text.trim(),
        category: _category,
      ),
    );
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const _SectionHeading(
          title: 'Personal details 👤',
          subtitle: 'Keep your student account information up to date.',
        ),
        const SizedBox(height: 16),
        _ProfileTextField(
          controller: _nameController,
          label: 'Full name',
          icon: Icons.person_outline_rounded,
        ),
        _ProfileTextField(
          controller: _contactController,
          label: 'Contact number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        _ProfileTextField(
          controller: _matricController,
          label: 'Matric number',
          icon: Icons.badge_outlined,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Student category',
              prefixIcon: Icon(Icons.school_outlined),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'KRP Student',
                child: Text('KRP Student'),
              ),
              DropdownMenuItem(
                value: 'Non-KRP Student / Other College',
                child: Text(
                  'Non-KRP Student / Other College',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
        ),
        _ProfileTextField(
          controller: _emailController,
          label: 'Email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        _ProfileTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          helperText: 'Leave blank to keep your current password.',
        ),
        _ProfileTextField(
          controller: _confirmPasswordController,
          label: 'Confirm password',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
        ),
        CheckboxListTile(
          value: _confirmed,
          onChanged: (value) => setState(() => _confirmed = value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: _profileGreen,
          title: const Text(
            'I confirm that the information provided is accurate.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Changes'),
          style: FilledButton.styleFrom(
            backgroundColor: _profileGreen,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonalDetails {
  final String name;
  final String email;
  final String contact;
  final String matric;
  final String category;

  const _PersonalDetails({
    required this.name,
    required this.email,
    required this.contact,
    required this.matric,
    required this.category,
  });
}

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? helperText;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDCE4DF)),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: _profileGreen, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: _profileTextMuted)),
      ],
    );
  }
}

class _BookingGroup {
  final String facilityName;
  final DateTime date;
  final List<String> times;
  final int totalPrice;
  final String status;
  final List<String> bookingIds;

  const _BookingGroup({
    required this.facilityName,
    required this.date,
    required this.times,
    required this.totalPrice,
    required this.status,
    required this.bookingIds,
  });
}

class _MyBookingsTab extends StatelessWidget {
  final List<Booking> bookings;

  const _MyBookingsTab({required this.bookings});

  List<_BookingGroup> _groupBookings() {
    final grouped = <String, List<Booking>>{};
    for (final booking in bookings) {
      final date = DateUtils.dateOnly(booking.date);
      final key =
          '${booking.facilityName}|${date.year}-${date.month}-${date.day}';
      grouped.putIfAbsent(key, () => []).add(booking);
    }

    final groups =
        grouped.values.map((items) {
          final allTimes =
              items.expand((booking) => booking.timeSlots).toSet().toList()
                ..sort((a, b) => _minutesFor(a).compareTo(_minutesFor(b)));
          return _BookingGroup(
            facilityName: items.first.facilityName,
            date: DateUtils.dateOnly(items.first.date),
            times: allTimes,
            totalPrice: items.fold(
              0,
              (total, booking) => total + booking.totalPrice,
            ),
            status: _groupStatus(items),
            bookingIds: items.map((booking) => booking.id).toList(),
          );
        }).toList()..sort((a, b) {
          final dateOrder = a.date.compareTo(b.date);
          if (dateOrder != 0) return dateOrder;
          final aMinutes = a.times.isEmpty ? 0 : _minutesFor(a.times.first);
          final bMinutes = b.times.isEmpty ? 0 : _minutesFor(b.times.first);
          return aMinutes.compareTo(bMinutes);
        });
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupBookings();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const _SectionHeading(
          title: 'My bookings 📅',
          subtitle: 'Your court reservations, ordered by date and time.',
        ),
        const SizedBox(height: 12),
        if (groups.isEmpty)
          const _EmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'No bookings yet',
            message: 'Your facility bookings will appear here.',
          )
        else
          ...groups.map(
            (group) => _BookingCard(
              group: group,
              onViewReceipt: () => _showReceipt(context, group),
            ),
          ),
      ],
    );
  }

  void _showReceipt(BuildContext context, _BookingGroup group) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: _profileGreen),
                  SizedBox(width: 9),
                  Text(
                    'Booking Receipt',
                    style: TextStyle(
                      color: _profileGreen,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 26),
              _ReceiptRow(label: 'Court name', value: group.facilityName),
              _ReceiptRow(
                label: 'Date & time',
                value: _bookingDateTime(group.date, group.times),
              ),
              _ReceiptRow(
                label: 'Booking ID',
                value: group.bookingIds.join(', '),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total paid',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'RM ${group.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: _profileGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: _profileGreen,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _profileTextMuted, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3),
        ),
      ],
    ),
  );
}

class _BookingCard extends StatelessWidget {
  final _BookingGroup group;
  final VoidCallback onViewReceipt;

  const _BookingCard({required this.group, required this.onViewReceipt});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE7ECE8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateBlock(date: group.date),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusPill(status: group.status),
                  const SizedBox(height: 7),
                  Text(
                    group.facilityName,
                    style: const TextStyle(
                      color: _profileGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _bookingDateTime(group.date, group.times),
                    style: const TextStyle(
                      color: _profileGreen,
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  TextButton(
                    onPressed: onViewReceipt,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(10, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('View receipt'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'RM ${group.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: _profileGreen,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  final DateTime date;

  const _DateBlock({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: _profilePaleGreen,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: _profileGreen,
            size: 15,
          ),
          Text(
            '${date.day}',
            style: const TextStyle(
              color: _profileGreen,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _month(date.month).toUpperCase(),
            style: const TextStyle(
              color: _profileGreen,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

String _groupStatus(List<Booking> bookings) {
  if (bookings.any((booking) => booking.status.toLowerCase() == 'confirmed')) {
    return 'CONFIRMED';
  }
  return bookings.isEmpty ? 'PENDING' : bookings.first.status.toUpperCase();
}

String _bookingDateTime(DateTime date, List<String> times) {
  final datePart = '${date.day} ${_month(date.month)} ${date.year}';
  if (times.isEmpty) return datePart;
  final start = times.first;
  final end = _timeAfterHour(times.last);
  return '$datePart • $start - $end';
}

String _timeAfterHour(String time) {
  final parts = time.split(' ');
  final clock = parts.first.split(':');
  var hour = int.parse(clock[0]);
  final minute = int.parse(clock[1]);
  var period = parts.last;
  if (hour == 11) {
    hour = 12;
    period = period == 'AM' ? 'PM' : 'AM';
  } else {
    hour = hour % 12 + 1;
  }
  return '${hour.toString()}:${minute.toString().padLeft(2, '0')} $period';
}

int _minutesFor(String time) {
  final parts = time.split(' ');
  final clock = parts.first.split(':');
  var hour = int.parse(clock[0]);
  final minute = int.parse(clock[1]);
  if (parts.last == 'PM' && hour != 12) hour += 12;
  if (parts.last == 'AM' && hour == 12) hour = 0;
  return hour * 60 + minute;
}

String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toUpperCase()) {
      'CONFIRMED' || 'REFUNDED' || 'RESOLVED' => const Color(0xFF2D7A4F),
      'PROCESSING' || 'UNDER REVIEW' => const Color(0xFFB36B16),
      'REJECTED' => const Color(0xFFB33A3A),
      _ => _profileGreen,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: .4,
        ),
      ),
    );
  }
}

class _RefundRequest {
  final String bookingId;
  final String facility;
  final String reason;
  final String paymentMethod;
  final String refundMethod;
  final String status;

  const _RefundRequest({
    required this.bookingId,
    required this.facility,
    required this.reason,
    required this.paymentMethod,
    required this.refundMethod,
    required this.status,
  });
}

class _RefundRequestsTab extends StatelessWidget {
  final List<_RefundRequest> requests;

  const _RefundRequestsTab({required this.requests});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const _SectionHeading(
          title: 'Refund requests 💸',
          subtitle: 'Sample requests shown as a UI preview.',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0DCAA)),
          ),
          child: const Text(
            'Refund eligibility: Bookings cannot be cancelled by users. '
            'Refunds can only be requested when the facility is closed, '
            'under maintenance, or made unavailable by an admin.',
            style: TextStyle(
              color: Color(0xFF624A1D),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final request in requests) _RefundCard(request: request),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Bank/TNG refunds may take a few business days to process.',
            style: TextStyle(
              color: _profileTextMuted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _RefundCard extends StatelessWidget {
  final _RefundRequest request;

  const _RefundCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE7ECE8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: _profileGreen,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.bookingId,
                    style: const TextStyle(
                      color: _profileGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusPill(status: request.status),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              request.facility,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _RefundDetail(label: 'Reason', value: request.reason),
            _RefundDetail(
              label: 'Payment method',
              value: request.paymentMethod,
            ),
            _RefundDetail(label: 'Refund method', value: request.refundMethod),
          ],
        ),
      ),
    );
  }
}

class _RefundDetail extends StatelessWidget {
  final String label;
  final String value;

  const _RefundDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(color: _profileTextMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedReport {
  final String category;
  final DateTime submittedAt;
  final Booking? booking;
  final String description;
  final String status;

  const _SubmittedReport({
    required this.category,
    required this.submittedAt,
    required this.booking,
    required this.description,
    this.status = 'Under Review',
  });
}

class _MyReportsTab extends StatelessWidget {
  final List<Booking> bookings;
  final List<_SubmittedReport> reports;
  final ValueChanged<_SubmittedReport> onSubmit;

  const _MyReportsTab({
    required this.bookings,
    required this.reports,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const _SectionHeading(
          title: 'My reports 📝',
          subtitle: 'Get help from the KRP PLAY support team.',
        ),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(
              child: _SupportInfoCard(
                icon: Icons.support_agent_rounded,
                title: 'Contact admin',
                detail: 'krp.support@example.com',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _SupportInfoCard(
                icon: Icons.location_on_outlined,
                title: 'Visit us',
                detail: 'KRP Sports Hall',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => _showReportForm(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Report'),
          style: FilledButton.styleFrom(
            backgroundColor: _profileGreen,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Submitted reports',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: _profileGreen, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (reports.isEmpty)
          const _EmptyState(
            icon: Icons.support_outlined,
            title: 'No reports submitted',
            message: 'Reports you submit will be listed here.',
          )
        else
          ...reports.map((report) => _ReportCard(report: report)),
      ],
    );
  }

  Future<void> _showReportForm(BuildContext context) async {
    final report = await showModalBottomSheet<_SubmittedReport>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportFormSheet(bookings: bookings),
    );
    if (report != null) onSubmit(report);
  }
}

class _SupportInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _SupportInfoCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _profileGreen, size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _profileTextMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ReportFormSheet extends StatefulWidget {
  final List<Booking> bookings;

  const _ReportFormSheet({required this.bookings});

  @override
  State<_ReportFormSheet> createState() => _ReportFormSheetState();
}

class _ReportFormSheetState extends State<_ReportFormSheet> {
  static const _categories = [
    'Booking Issue',
    'Payment Issue',
    'Facility Problem',
    'Account Issue',
    'Other',
  ];

  final _descriptionController = TextEditingController();
  String? _category;
  Booking? _booking;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F6F4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(18, 12, 18, 20 + bottomInset),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCCD5CF),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'How can we help?',
            style: TextStyle(
              color: _profileGreen,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Tell us what happened and our team will follow up.',
            style: TextStyle(color: _profileTextMuted),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _SupportInfoCard(
                  icon: Icons.support_agent_rounded,
                  title: 'Contact admin',
                  detail: 'krp.support@example.com',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _SupportInfoCard(
                  icon: Icons.location_on_outlined,
                  title: 'Visit us',
                  detail: 'KRP Sports Hall',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Report category',
              border: OutlineInputBorder(),
            ),
            items: _categories
                .map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
                )
                .toList(),
            onChanged: (value) => setState(() => _category = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Booking?>(
            initialValue: _booking,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Related booking (optional)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<Booking?>(
                value: null,
                child: Text('No related booking'),
              ),
              ...widget.bookings.map(
                (booking) => DropdownMenuItem<Booking?>(
                  value: booking,
                  child: Text(
                    _bookingOptionLabel(booking),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _booking = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Problem description',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _profileGreen,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_category == null) {
      setState(() => _error = 'Please select a report category.');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      setState(() => _error = 'Please describe the problem.');
      return;
    }
    Navigator.of(context).pop(
      _SubmittedReport(
        category: _category!,
        submittedAt: DateTime.now(),
        booking: _booking,
        description: _descriptionController.text.trim(),
        status: 'Under Review',
      ),
    );
  }
}

String _bookingOptionLabel(Booking booking) {
  final times = [...booking.timeSlots]
    ..sort((a, b) => _minutesFor(a).compareTo(_minutesFor(b)));
  final dateTime = _bookingDateTime(booking.date, times);
  final dateAndTime = dateTime.split(' • ');
  final display = dateAndTime.length == 2
      ? '${dateAndTime.first} ${dateAndTime.last}'
      : dateTime;
  return '${booking.id} - ${booking.facilityName} - $display';
}

class _ReportCard extends StatelessWidget {
  final _SubmittedReport report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final booking = report.booking;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE7ECE8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _Tag(text: report.category),
                  ),
                ),
                Text(
                  _shortDate(report.submittedAt),
                  style: const TextStyle(
                    color: _profileTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: _profilePaleGreen.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(11),
              ),
              child: booking == null
                  ? const Text(
                      'No related booking',
                      style: TextStyle(color: _profileTextMuted, fontSize: 12),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RELATED BOOKING',
                          style: TextStyle(
                            color: _profileTextMuted,
                            fontSize: 9,
                            letterSpacing: .5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 7),
                        _ReportBookingLine(label: 'Booking ID', value: booking.id),
                        _ReportBookingLine(
                          label: 'Court',
                          value: booking.facilityName,
                        ),
                        _ReportBookingLine(
                          label: 'Date / time',
                          value: _bookingDateTime(
                            booking.date,
                            booking.timeSlots,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            Text(report.description),
            const SizedBox(height: 10),
            _StatusPill(status: report.status.toUpperCase()),
          ],
        ),
      ),
    );
  }
}

class _ReportBookingLine extends StatelessWidget {
  final String label;
  final String value;

  const _ReportBookingLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(color: _profileTextMuted, fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _profileGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _profilePaleGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _profileGreen,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

String _shortDate(DateTime date) =>
    '${date.day} ${_month(date.month)} ${date.year}';

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8DA397), size: 38),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _profileGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _profileTextMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
