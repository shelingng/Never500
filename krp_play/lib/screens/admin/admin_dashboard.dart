import 'package:flutter/material.dart';

import 'admin_overview_tab.dart';
import 'manage_slots.dart';
import 'reservations.dart';
import 'user_reports.dart';
import 'refunds.dart';
import 'admin_profile.dart';

class AdminHomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminHomeScreen({super.key, required this.onLogout});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const _green = Color(0xFF173F32);
  static const _lime = Color(0xFFD2F865);
  static const _muted = Color(0xFFA6BBB1);

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;

  final List<String> _titles = const [
    'Overview',
    'Manage Slots',
    'Reservations',
    'User Reports',
    'Refund Management',
    'Admin Profile',
  ];

  final List<IconData> _icons = const [
    Icons.home_outlined,
    Icons.calendar_today_outlined,
    Icons.receipt_long_outlined,
    Icons.info_outline,
    Icons.payments_outlined,
    Icons.settings_outlined,
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      AdminOverviewTab(onViewAllBookings: () => _selectPage(2)),
      const AdminSlotsTab(),
      const AdminBookingsTab(),
      const AdminReportsTab(),
      const AdminRefundsTab(),
      const AdminProfileTab(),
    ];
  }

  void _selectPage(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  void _selectFromDrawer(int index) {
    _selectPage(index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  void _signOut() {
    _scaffoldKey.currentState?.closeDrawer();
    widget.onLogout();
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 42, 24, 32),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _lime,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.sports_tennis, color: _green, size: 31),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KRP PLAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'SPORTS HUB',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index) {
    final selected = _currentIndex == index;
    final foreground = selected ? _green : _muted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? _lime : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          selected: selected,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Icon(_icons[index], color: foreground, size: 26),
          title: Text(
            _titles[index],
            style: TextStyle(
              color: foreground,
              fontSize: 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          onTap: () => _selectFromDrawer(index),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = screenWidth < 400 ? screenWidth * 0.88 : 340.0;

    return Drawer(
      width: drawerWidth,
      backgroundColor: _green,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLogo(),
            const Divider(height: 1, color: Color(0xFF315648)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 0, 22),
                    child: Text(
                      'ADMIN CONSOLE',
                      style: TextStyle(
                        color: Color(0xFF78968A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                  ...List.generate(_titles.length, _buildDrawerItem),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const Icon(Icons.logout, color: _muted, size: 25),
                title: const Text(
                  'Sign out',
                  style: TextStyle(color: _muted, fontSize: 16),
                ),
                onTap: _signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F9F7),
      drawer: _buildDrawer(),
      drawerScrimColor: Colors.black.withAlpha(105),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _green,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Open admin navigation',
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          'ADMIN / ${_titles[_currentIndex]}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Admin profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _selectPage(5),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // Retains each tab's local state when navigating between sections.
      body: IndexedStack(index: _currentIndex, children: _pages),

      // Retained to match the bottom navigation in your prototype.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _green,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        onTap: _selectPage,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Slots',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Refunds',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
