import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/booking_service.dart';
import 'facilities_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

const _green = Color(0xFF173F32);
const _pale = Color(0xFFF2F6F2);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _profileTab = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _email =>
      Supabase.instance.client.auth.currentUser?.email ?? 'Unknown User';

  void _selectTab(int index) {
    setState(() {
      _tab = index;
      if (index == 2) _profileTab = 0;
    });
  }

  void _openBookings() {
    setState(() {
      _tab = 2;
      _profileTab = 1;
    });
  }

  void _navigateFromDrawer(int tab, {int profileTab = 0}) {
    Navigator.pop(context);
    setState(() {
      _tab = tab;
      _profileTab = profileTab;
    });
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['KRP PLAY', 'Book a Facility', 'KRP PLAY / My Profile'];
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: 304,
        backgroundColor: _green,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4F048),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.sports_tennis, color: _green),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KRP PLAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'SPORTS HUB',
                          style: TextStyle(
                            color: Color(0xFFB7C7B9),
                            fontSize: 10,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 38),
                const Padding(
                  padding: EdgeInsets.only(left: 12, bottom: 10),
                  child: Text(
                    'STUDENT PORTAL',
                    style: TextStyle(
                      color: Color(0xFFB7C7B9),
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _drawerItem('Home', Icons.home_outlined, 0),
                _drawerItem('Facilities', Icons.calendar_month_outlined, 1),
                _drawerItem('My Profile', Icons.person_outline, 2),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF245343),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF386754),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Need assistance?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'KRP Sports Unit\n+60 7-553 5000 • Block L50',
                        style: TextStyle(
                          color: Color(0xFFD0DED2),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _navigateFromDrawer(2, profileTab: 3),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(top: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: const Color(0xFFD4F048),
                        ),
                        child: const Text('Report a problem →'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sign out',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: _tab == 1
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                titles[_tab],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              actions: [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text('Notifications'),
                      content: Text('You are all caught up.'),
                    ),
                  ),
                  icon: const Icon(Icons.notifications_none),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xFFDCEADF),
                    child: Text(
                      'SL',
                      style: TextStyle(
                        color: _green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      body: IndexedStack(
        index: _tab,
        children: [
          _HomeContent(onBook: () => _selectTab(1), onBookings: _openBookings),
          FacilitiesScreen(
            category: 'KRP Student',
            email: _email,
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          ProfileScreen(
            key: ValueKey(_profileTab),
            email: _email,
            initialTab: _profileTab,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_tennis_outlined),
            selectedIcon: Icon(Icons.sports_tennis),
            label: 'Book',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(String title, IconData icon, int tab) {
    final selected = _tab == tab;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFFD4F048) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _navigateFromDrawer(tab),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: selected ? _green : Colors.white, size: 21),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? _green : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final VoidCallback onBook;
  final VoidCallback onBookings;

  const _HomeContent({required this.onBook, required this.onBookings});

  @override
  Widget build(BuildContext context) {
    final bookings = BookingService.instance.bookings;
    final confirmed = bookings
        .where((booking) => booking.status == 'Confirmed')
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Container(
          height: 224,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?auto=format&fit=crop&w=1200&q=80',
              ),
              fit: BoxFit.cover,
              opacity: 0.28,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GOOD AFTERNOON, SHE LING',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              const Text(
                'Your next game\nstarts here.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onBook,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB8E986),
                  foregroundColor: _green,
                ),
                child: const Text(
                  'Find a slot  →',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_month_outlined,
                count: bookings.length.toString().padLeft(2, '0'),
                label: 'Booking records',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.confirmation_number_outlined,
                count: '$confirmed',
                label: 'Confirmed reservations',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Latest Updates',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: onBookings, child: const Text('My bookings')),
          ],
        ),
        const SizedBox(height: 8),
        const _NoticeCard(
          date: '17 MAR',
          tag: 'IMPORTANT',
          title: 'Facility booking is now open',
          time: '09:30 AM',
        ),
        const _NoticeCard(
          date: '12 MAR',
          tag: 'UPDATE',
          title: 'Please check in before your session',
          time: '02:15 PM',
        ),
        const _NoticeCard(
          date: '08 MAR',
          tag: 'NOTICE',
          title: 'Keep our courts clean and ready',
          time: '11:00 AM',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;

  const _StatCard({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 112),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _green),
        const SizedBox(height: 10),
        Text(
          count,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _green,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    ),
  );
}

class _NoticeCard extends StatelessWidget {
  final String date;
  final String tag;
  final String title;
  final String time;

  const _NoticeCard({
    required this.date,
    required this.tag,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _pale,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              date,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: _green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  style: const TextStyle(
                    color: _green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
