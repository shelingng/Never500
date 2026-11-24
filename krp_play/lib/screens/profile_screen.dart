import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';
import '../models/student_category.dart';
import '../services/booking_service.dart';
import '../widgets/booking_history.dart';

part 'profile_sections.dart';

const _green = Color(0xFF1A332C);
const _lime = Color(0xFFC5F84B);
const _pale = _lime;
const _muted = Color(0xFF66756D);
const _divider = Color(0xFFE2E9E4);

class ProfileScreen extends StatefulWidget {
  final String email;
  final String? fullName;
  final String? contact;
  final String? matric;
  final String? category;
  final int initialTab;
  final bool navigationSection;

  const ProfileScreen({
    super.key,
    required this.email,
    this.fullName,
    this.contact,
    this.matric,
    this.category,
    this.initialTab = 0,
    this.navigationSection = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends _ProfileSectionsState {
  late int _tab = widget.initialTab;
  bool _editing = false, _verified = false;
  bool _loadingBookings = true;
  @override
  bool get _isLoadingBookings => _loadingBookings;
  
  String _category = StudentCategory.notSetLabel;
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _matric = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  List<Booking> _cachedBookings = [];

  @override
  void initState() {
    super.initState();
    _name.text = widget.fullName ?? 'Ng She Ling';
    _contact.text = widget.contact ?? '';
    _matric.text = widget.matric ?? '';
    // SCRUM-38: show the label for the stored value; never assume KRP.
    _category = StudentCategory.labelFor(widget.category);

    _loadLiveBookings();
    _loadLiveReports();
  }

  _loadLiveBookings() async {
    final results = await BookingService().getUserBookings();
    if (mounted) {
      setState(() {
        _cachedBookings = List<Booking>.from(results);
        _cachedBookings.sort((a, b) {
          final date = a.date.compareTo(b.date);
          return date == 0 ? _start(a).compareTo(_start(b)) : date;
        });
        _loadingBookings = false;
      });
    }
  }

  void _loadLiveReports() async {
    try {
      final results = await BookingService().getUserReports();
      if (mounted) {
        setState(() {
          _reports.clear();

          _reports.addAll(results.map((row) {
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

            return _LocalReport(
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
            );
          }).toList().cast<_LocalReport>());

          _isLoadingReports = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReports = false);
    }
  }

  @override
  List<Booking> get _bookings {
    return _cachedBookings;
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _matric.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.navigationSection) {
      return ColoredBox(
        color: const Color(0xFFF4F6F4),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            if (widget.initialTab == 0) ...[
              _header(),
              const SizedBox(height: 20),
              _personalDetails(),
            ],
            if (widget.initialTab == 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _tabButton('Bookings', 1),
                    _tabButton('Refund status', 2),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_tab == 1) _myBookings(),
              if (_tab == 2) _refundRequests(),
            ],
            if (widget.initialTab == 3) _myReports(),
          ],
        ),
      );
    }
    return ColoredBox(
      color: const Color(0xFFF4F6F4),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          _header(),
          const SizedBox(height: 18),
          SizedBox(
            height: 44,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tabButton('Personal details', 0),
                  _tabButton('My bookings', 1),
                  _tabButton('Refund status', 2),
                  _tabButton('My reports', 3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_tab == 0) _personalDetails(),
          if (_tab == 1) _myBookings(),
          if (_tab == 2) _refundRequests(),
          if (_tab == 3) _myReports(),
        ],
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF23433A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _lime,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _name.text
                        .trim()
                        .split(RegExp(r'\s+'))
                        .where((part) => part.isNotEmpty)
                        .take(2)
                        .map((part) => part[0].toUpperCase())
                        .join(),
                    style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => setState(() {
                    _tab = 0;
                    _editing = true;
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  child: const Text('Edit profile'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'STUDENT ACCOUNT',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _name.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(_category, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      );

  Widget _tabButton(String title, int index, [String? badge]) => InkWell(
        onTap: () {
          setState(() {
            _tab = index;
            _editing = false;
            if (index == 1) {
              _loadingBookings = true;
              _loadLiveBookings();
            }
            if (index == 3) {
              _isLoadingReports = true;
              _loadLiveReports();
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: _tab == index ? _lime : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _tab == index ? _green : _muted,
                  fontWeight: _tab == index ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 5),
                CircleAvatar(
                  radius: 9,
                  backgroundColor: const Color(0xFFE8F1EB),
                  child: Text(
                    badge,
                    style: const TextStyle(fontSize: 10, color: _green),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _personalDetails() => _card(
        color: _editing ? Colors.white : const Color(0xFF23433A),
        child: _editing
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Personal details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _input(_name, 'Full name', Icons.person_outline),
                  _input(
                    _contact,
                    'Contact number',
                    Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                  _input(_matric, 'Matric number', Icons.badge_outlined),
                  TextFormField(
                    initialValue: _category,
                    readOnly: true,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Student category (Managed by Admin)',
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: widget.email,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _input(_password, 'Password', Icons.lock_outline, obscure: true),
                  _input(
                    _confirm,
                    'Confirm password',
                    Icons.lock_outline,
                    obscure: true,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _verified,
                    onChanged: (value) =>
                        setState(() => _verified = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'I confirm that the information provided is accurate.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  FilledButton(
                    onPressed: _saveProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: _lime,
                      foregroundColor: _green,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Save profile'),
                  ),
                ],
              )
            : Column(
                children: [
                  _info(Icons.person_outline, 'Full Name', _name.text),
                  _info(
                    Icons.phone_outlined,
                    'Contact',
                    _contact.text.isEmpty ? 'Not provided' : _contact.text,
                  ),
                  _info(
                    Icons.badge_outlined,
                    'Matric',
                    _matric.text.isEmpty ? 'Not provided' : _matric.text,
                  ),
                  _info(Icons.school_outlined, 'Category', _category),
                  _info(Icons.email_outlined, 'Email', widget.email),
                ],
              ),
      );

  void _saveProfile() async {
    if (!_verified) {
      _message('Please confirm your information first.');
      return;
    } else if (_password.text.isNotEmpty && _password.text != _confirm.text) {
      _message('Passwords do not match.');
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        _message('No active user found. Please log in again.');
        return;
      }

      await supabase.from('profiles').update({
        'full_name': _name.text.trim(),
        'phone_number': _contact.text.trim(),
        'matric_number': _matric.text.trim(),
      }).eq('id', user.id);

      setState(() => _editing = false);
      _message('Profile updated successfully in database!');
    } catch (e) {
      _message('Error updating profile: $e');
    }
  }

  Widget _input(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboard,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: _muted),
            prefixIconColor: _lime,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: _divider),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: _lime, width: 2),
            ),
            hintStyle: const TextStyle(color: _muted),
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: _divider),
            ),
          ),
          style: const TextStyle(color: _green),
        ),
      );

  // SCRUM-48: saved orders with every session and payment, grouped into
  // upcoming / pending / past / cancelled (lib/widgets/booking_history.dart).
  Widget _myBookings() => const BookingHistoryView();
}