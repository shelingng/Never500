import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';

part 'profile_sections.dart';

const _green = Color(0xFF173F32);
const _pale = Color(0xFFE7F0E8);

class ProfileScreen extends StatefulWidget {
  final String email;
  final int initialTab;

  const ProfileScreen({super.key, required this.email, this.initialTab = 0});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends _ProfileSectionsState {
  late int _tab = widget.initialTab;
  bool _editing = false, _verified = false;
  String _category = 'KRP Student';
  final _name = TextEditingController(text: 'Ng She Ling');
  final _contact = TextEditingController();
  final _matric = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  List<Booking> get _bookings {
    final result = BookingService.instance.getBookingsByEmail(widget.email);
    result.sort((a, b) {
      final date = a.date.compareTo(b.date);
      return date == 0 ? _start(a).compareTo(_start(b)) : date;
    });
    return result;
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
  Widget build(BuildContext context) => ListView(
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
              _tabButton('My bookings', 1, '3'),
              _tabButton('Refund requests', 2, '1'),
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
  );

  Widget _header() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _green,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFDCEADF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'SL',
                style: TextStyle(
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
        Text(
          'KRP Student · ${_matric.text.isEmpty ? 'Matric details on file' : _matric.text}',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );

  Widget _tabButton(String title, int index, [String? badge]) => InkWell(
    onTap: () => setState(() {
      _tab = index;
      _editing = false;
    }),
    child: Container(
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _tab == index ? _green : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _tab == index ? _green : Colors.black54,
              fontWeight: _tab == index ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 5),
            CircleAvatar(
              radius: 9,
              backgroundColor: _pale,
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
              DropdownButtonFormField<String>(
                initialValue: _category,
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
                    value: 'Non-KRP Student',
                    child: Text('Non-KRP Student'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _category = value ?? _category),
              ),
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
                  backgroundColor: _green,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          )
        : Column(
            children: [
              _info(Icons.person_outline, 'Full name', _name.text),
              _info(
                Icons.phone_outlined,
                'Contact number',
                _contact.text.isEmpty ? 'Not provided' : _contact.text,
              ),
              _info(
                Icons.badge_outlined,
                'Matric number',
                _matric.text.isEmpty ? 'Not provided' : _matric.text,
              ),
              _info(Icons.school_outlined, 'Student category', _category),
              _info(Icons.email_outlined, 'Email address', widget.email),
            ],
          ),
  );

  void _saveProfile() {
    if (!_verified) {
      _message('Please confirm your information first.');
    } else if (_password.text.isNotEmpty && _password.text != _confirm.text) {
      _message('Passwords do not match.');
    } else {
      setState(() => _editing = false);
      _message('Profile changes saved.');
    }
  }

  Widget _input(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _myBookings() {
    final bookings = _bookings;
    if (bookings.isEmpty) {
      return _empty(
        Icons.calendar_month_outlined,
        'No bookings yet',
        'Your facility bookings will appear here.',
      );
    }
    return Column(children: bookings.map(_bookingCard).toList());
  }

  Widget _bookingCard(Booking booking) => _card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _pale,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            children: [
              Text(
                '${booking.date.day}',
                style: const TextStyle(
                  color: _green,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _month(booking.date.month),
                style: const TextStyle(
                  color: _green,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _badge(booking.status.toUpperCase(), _pale, _green),
              const SizedBox(height: 8),
              Text(
                booking.facilityName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${booking.date.day} ${_month(booking.date.month)} ${booking.date.year} • ${_bookingTime(booking)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Booking ID: ${booking.id}',
                style: const TextStyle(color: Colors.black54, fontSize: 11),
              ),
              const SizedBox(height: 7),
              Text(
                'RM ${booking.totalPrice}.00',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Booking receipt'),
                    content: Text(
                      '${booking.facilityName}\\n${booking.date.day} ${_month(booking.date.month)} ${booking.date.year}\\n${_bookingTime(booking)}\\nBooking ID: ${booking.id}\\nPayment status: ${booking.status}\\nTotal: RM ${booking.totalPrice}.00',
                    ),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  alignment: Alignment.centerLeft,
                ),
                child: const Text('View receipt'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
