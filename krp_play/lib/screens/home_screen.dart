import 'package:flutter/material.dart';
import '../models/student_account.dart';
import '../services/booking_service.dart';
import 'facility_info_screen.dart';
import 'facilities_screen.dart';
import 'booking_records_screen.dart';

class HomeScreen extends StatefulWidget {
  final StudentAccount account;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.account,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final Color primaryGreen = const Color(0xFF103B2B);
  final Color accentLime = const Color(0xFFD2F865);
  final Color subtleBorder = const Color(0xFFE9EFEA);

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'GOOD MORNING';
    } else if (hour < 18) {
      return 'GOOD AFTERNOON';
    } else {
      return 'GOOD EVENING';
    }
  }

  String get _initials {
    final names = widget.account.fullName.trim().split(' ');
    if (names.isEmpty) return 'YX';
    if (names.length == 1) {
      return names[0].substring(0, names[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (names.first[0] + names.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9F7),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF103B2B)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'KRP PLAY  /  Home',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF708077),
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Color(0xFF103B2B), size: 26),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No new notifications. Booking slots for today are open.',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: Center(
              child: InkWell(
                onTap: () {
                  setState(() => _currentIndex = 2);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F6C8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryGreen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: accentLime,
                    child: Text(
                      _initials,
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.account.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    widget.account.category,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              selected: _currentIndex == 0,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_tennis),
              title: const Text('KRP Sports Complex Info'),
              onTap: () {
                Navigator.pop(context);
                _openFacilityInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Book a Facility'),
              onTap: () {
                Navigator.pop(context);
                _openFacilitiesScreen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Booking Records'),
              onTap: () {
                Navigator.pop(context);
                _openBookingRecords();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:
                  const Text('Log out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                widget.onLogout();
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildBookTabPlaceholder(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: subtleBorder)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                ),
                _navItem(
                  index: 1,
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  label: 'Book',
                ),
                _navItem(
                  index: 2,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final active = _currentIndex == index;
    return InkWell(
      onTap: () {
        if (index == 1) {
          _openFacilityInfo();
        } else {
          setState(() => _currentIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8F6C8) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? primaryGreen : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? primaryGreen : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HOME TAB (Image 2 design)
  Widget _buildHomeTab() {
    final userBookings =
        BookingService.instance.getBookingsByEmail(widget.account.email);
    final bookingCount = userBookings.length;
    final availableSlotsCount =
        BookingService.instance.getAvailableSlotsCount(DateTime.now());

    final formattedBookingCount =
        bookingCount < 10 ? '0$bookingCount' : '$bookingCount';
    final formattedSlotsCount = availableSlotsCount < 10
        ? '0$availableSlotsCount'
        : '$availableSlotsCount';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // HERO CARD (Dark forest green with lime accent)
        Container(
          height: 290,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Badminton Court & Smash Art Painting in Background
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BadmintonCourtSmashPainter(),
                  ),
                ),
                // Hero Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: accentLime,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$_greeting, ${widget.account.fullName.toUpperCase()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.15,
                                letterSpacing: -0.5,
                              ),
                              children: [
                                const TextSpan(text: 'Your next game\nstarts '),
                                TextSpan(
                                  text: 'here.',
                                  style: TextStyle(color: accentLime),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Text(
                              'Seven facilities. Management-controlled availability. One smooth booking.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Action Button (Lime Pill Button with Dark Text)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentLime,
                          foregroundColor: primaryGreen,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: _openFacilityInfo,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Find a slot',
                              style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                size: 18, color: primaryGreen),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // STATS CARDS CONTAINER (White rounded card with 2 items)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: subtleBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. BOOKING RECORDS ROW
              InkWell(
                onTap: _openBookingRecords,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF5E9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xFF103B2B),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedBookingCount,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF103B2B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Booking records',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade400,
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),

              Divider(height: 1, thickness: 1, color: subtleBorder),

              // 2. AVAILABLE SLOTS TODAY ROW
              InkWell(
                onTap: _openFacilitiesScreen,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFF1976D2),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedSlotsCount,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF103B2B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Available slots today',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade400,
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // QUICK HIGHLIGHT / REVENUE BANNER FOR KRP
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE5EFE9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  color: primaryGreen, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified ${widget.account.category}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.account.category == 'KRP Student'
                          ? 'Subsidized collegian rates applied automatically.'
                          : 'General student rates applied.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookTabPlaceholder() {
    return const SizedBox();
  }

  // PROFILE TAB
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6C8),
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryGreen, width: 2),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.account.fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF103B2B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.account.matric,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _profileDetailRow('Email', widget.account.email),
                const Divider(),
                _profileDetailRow('Contact', widget.account.contact),
                const Divider(),
                _profileDetailRow('Category', widget.account.category),
                const Divider(),
                _profileDetailRow('Matric No.', widget.account.matric),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            minimumSize: const Size.fromHeight(50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    );
  }

  Widget _profileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _openFacilityInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FacilityInfoScreen(
          category: widget.account.category,
          email: widget.account.email,
        ),
      ),
    );
  }

  void _openFacilitiesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FacilitiesScreen(
          category: widget.account.category,
          email: widget.account.email,
        ),
      ),
    );
  }

  void _openBookingRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BookingRecordsScreen(email: widget.account.email),
      ),
    );
  }
}

// Custom Painter for Hero Banner artistic court styling and smash motion lines
class _BadmintonCourtSmashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final courtLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final limeLinePaint = Paint()
      ..color = const Color(0xFFD2F865).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Court isometric / dynamic perspective lines on right side
    final path = Path();
    path.moveTo(size.width * 0.45, 0);
    path.lineTo(size.width, size.height * 0.7);
    path.lineTo(size.width * 0.7, size.height);
    path.lineTo(size.width * 0.25, size.height * 0.3);
    path.close();
    canvas.drawPath(path, courtLinePaint);

    // Shuttle smash arc
    final arcPath = Path();
    arcPath.moveTo(size.width * 0.9, size.height * 0.15);
    arcPath.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.45,
      size.width * 0.5,
      size.height * 0.9,
    );
    canvas.drawPath(arcPath, limeLinePaint);

    // Decorative circle
    final glowPaint = Paint()
      ..color = const Color(0xFF1B5E44).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.3),
      60,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

