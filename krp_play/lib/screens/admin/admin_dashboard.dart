import 'package:flutter/material.dart';

import 'admin_overview_tab.dart';
import 'manage_slots.dart';       // Replace with your actual filename if different
import 'reservations.dart';       // Replace with your actual filename if different
import 'user_reports.dart';       // Replace with your actual filename if different
import 'refunds.dart';            // Replace with your actual filename if different
import 'admin_profile.dart';      // Replace with your actual filename if different

class AdminHomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminHomeScreen({super.key, required this.onLogout});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<String> _pageTitles = [
    'Overview', 'Slots', 'Bookings', 'User Reports', 'Refunds', 'Admin Profile'
  ];

  // Dynamically load the page so we can pass navigation callbacks
  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return AdminOverviewTab(
          onViewAllBookings: () {
            setState(() {
              _currentIndex = 2; // Jump to Bookings Tab
            });
          },
        );
      case 1:
        return const AdminSlotsTab();
      case 2:
        return const AdminBookingsTab();
      case 3:
        return const AdminReportsTab();
      case 4:
        return const AdminRefundsTab();
      case 5:
        return const AdminProfileTab();
      default:
        return const AdminOverviewTab(onViewAllBookings: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu, color: Colors.black87), onPressed: () {}),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            children: [
              const TextSpan(text: 'ADMIN / ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              TextSpan(text: _pageTitles[_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black87), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: widget.onLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF173F32),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Slots'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), activeIcon: Icon(Icons.info), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.money_outlined), activeIcon: Icon(Icons.money), label: 'Refunds'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Profile'),
        ],
      ),
    );
  }
}