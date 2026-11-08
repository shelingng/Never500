import 'package:flutter/material.dart';

import '../models/student_account.dart';
import 'facilities_screen.dart';
import 'profile_screen.dart';

const _primaryGreen = Color(0xFF173F32);
const _softGreen = Color(0xFFE5EFE9);
const _pageBackground = Color(0xFFF4F6F4);

class HomeScreen extends StatefulWidget {
  final StudentAccount account;
  final VoidCallback onLogout;

  const HomeScreen({super.key, required this.account, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _profileKey = GlobalKey<ProfileScreenState>();
  int _selectedTab = 0;

  void _openTab(int index) {
    setState(() => _selectedTab = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _openReports() {
    _profileKey.currentState?.showReports();
    _openTab(2);
  }

  void _onBookingPaid() {
    _profileKey.currentState?.showBookings();
    setState(() => _selectedTab = 2);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeDashboard(account: widget.account, onFindSlot: () => _openTab(1)),
      FacilitiesScreen(
        category: widget.account.category,
        email: widget.account.email,
        onBookingPaid: _onBookingPaid,
      ),
      ProfileScreen(key: _profileKey, account: widget.account),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Open menu',
        ),
        title: Text(
          _selectedTab == 2 ? 'KRP PLAY / My Profile' : 'KRP PLAY',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _primaryGreen,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("You're all caught up.")),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () => setState(() => _selectedTab = 2),
            tooltip: 'Profile',
            padding: const EdgeInsets.only(right: 16),
            icon: CircleAvatar(
              radius: 17,
              backgroundColor: _softGreen,
              child: Text(
                widget.account.fullName.isEmpty
                    ? '?'
                    : widget.account.fullName[0].toUpperCase(),
                style: const TextStyle(
                  color: _primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: _primaryGreen,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
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
                      child: const Icon(
                        Icons.sports_tennis_rounded,
                        color: _primaryGreen,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KRP PLAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'SPORTS HUB',
                          style: TextStyle(
                            color: Color(0xFFB7C7BC),
                            fontSize: 10,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                const Padding(
                  padding: EdgeInsets.only(left: 12, bottom: 10),
                  child: Text(
                    'STUDENT PORTAL',
                    style: TextStyle(
                      color: Color(0xFFB7C7BC),
                      fontSize: 10,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _drawerItem(Icons.home_rounded, 'Home', 0),
                _drawerItem(Icons.calendar_month_rounded, 'Facilities', 1),
                _drawerItem(Icons.person_rounded, 'My Profile', 2),
                const Spacer(),
                _SupportCard(onReportProblem: _openReports),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Sign out'),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _selectedTab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        backgroundColor: Colors.white,
        indicatorColor: _softGreen,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_tennis_outlined),
            selectedIcon: Icon(Icons.sports_tennis_rounded),
            label: 'Book',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    final selected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? _primaryGreen : Colors.white,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? _primaryGreen : Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        selected: selected,
        selectedTileColor: const Color(0xFFD4F048),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onTap: () => _openTab(index),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final VoidCallback onReportProblem;

  const _SupportCard({required this.onReportProblem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF245541),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF376A54),
            child: Icon(Icons.info_outline_rounded, color: Colors.white, size: 19),
          ),
          const SizedBox(height: 11),
          const Text(
            'Need assistance?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'KRP Sports Unit\n+60 7-553 5000 • Block L50',
            style: TextStyle(color: Color(0xFFD4E0D7), fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onReportProblem,
            child: const Text(
              'Report a problem →',
              style: TextStyle(
                color: Color(0xFFD4F048),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  final StudentAccount account;
  final VoidCallback onFindSlot;

  const _HomeDashboard({required this.account, required this.onFindSlot});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _HeroBanner(name: account.fullName, onFindSlot: onFindSlot),
        const SizedBox(height: 22),
        SizedBox(
          height: 126,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _StatCard(
                icon: Icons.calendar_month_rounded,
                value: '01',
                label: 'Booking records',
              ),
              _StatCard(
                icon: Icons.schedule_rounded,
                value: '75',
                label: 'Available slots today',
              ),
              _StatCard(
                icon: Icons.confirmation_number_outlined,
                value: '1',
                label: 'Confirmed reservations',
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(
              child: Text(
                'Latest Updates',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _NoticeCard(
          day: '17',
          month: 'MAR',
          category: 'IMPORTANT',
          title: 'Updated facility booking guidelines',
          timestamp: 'Today · 9:30 AM',
        ),
        const _NoticeCard(
          day: '12',
          month: 'MAR',
          category: 'FACILITIES',
          title: 'Weekend court hours are now available',
          timestamp: '12 Mar · 2:15 PM',
        ),
        const _NoticeCard(
          day: '08',
          month: 'MAR',
          category: 'ANNOUNCEMENT',
          title: 'Welcome to the KRP PLAY sports hub',
          timestamp: '8 Mar · 10:00 AM',
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final String name;
  final VoidCallback onFindSlot;

  const _HeroBanner({required this.name, required this.onFindSlot});

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'PLAYER' : name.toUpperCase();
    return Container(
      constraints: const BoxConstraints(minHeight: 224),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF173F32), Color(0xFF28664C)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: -24,
            top: 10,
            child: Icon(
              Icons.sports_basketball_rounded,
              size: 190,
              color: Color(0x22FFFFFF),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOOD AFTERNOON, $displayName',
                  style: const TextStyle(
                    color: Color(0xFFB7E28A),
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                const SizedBox(
                  width: 260,
                  child: Text(
                    'Your next game starts here.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onFindSlot,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB7E28A),
                    foregroundColor: _primaryGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                  ),
                  child: const Text(
                    'Find a slot  →',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 174,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EBE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primaryGreen, size: 22),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: _primaryGreen,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final String day;
  final String month;
  final String category;
  final String title;
  final String timestamp;

  const _NoticeCard({
    required this.day,
    required this.month,
    required this.category,
    required this.title,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: _softGreen,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      color: _primaryGreen,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    month,
                    style: const TextStyle(
                      color: _primaryGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5EF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: _primaryGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    timestamp,
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
