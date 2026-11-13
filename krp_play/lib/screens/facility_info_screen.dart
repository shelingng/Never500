import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'facilities_screen.dart';
import 'profile_screen.dart';

class FacilityInfoScreen extends StatefulWidget {
  final String category;
  final String email;
  final String studentName;
  final String contact;
  final String matric;
  final VoidCallback? onLogout;

  const FacilityInfoScreen({
    super.key,
    required this.category,
    required this.email,
    this.studentName = 'Yu Xiang',
    this.contact = '',
    this.matric = '',
    this.onLogout,
  });

  @override
  State<FacilityInfoScreen> createState() => _FacilityInfoScreenState();
}

class _FacilityInfoScreenState extends State<FacilityInfoScreen> {
  final Color primaryGreen = const Color(0xFF103B2B);
  final Color accentLime = const Color(0xFFD2F865);
  final Color subtleBorder = const Color(0xFFE9EFEA);

  int _selectedTab = 0;
  int _currentCarouselIndex = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> carouselItems = [
    {
      'title': 'Badminton Courts 01 & 02',
      'subtitle': 'Indoor badminton facilities at KRP',
      'icon': Icons.sports_tennis,
      'photo': 'assets/facilities/badminton_courts.jpg',
    },
    {
      'title': 'Snooker & Darts',
      'subtitle': 'Snooker table and dart area',
      'icon': Icons.sports_baseball_outlined,
      'photo': 'assets/facilities/snooker_darts.jpg',
    },
    {
      'title': 'Table Tennis',
      'subtitle': 'Indoor table tennis facilities',
      'icon': Icons.sports_tennis_rounded,
      'photo': 'assets/facilities/table_tennis.jpg',
    },
    {
      'title': 'KRP Gym',
      'subtitle': 'A look inside the fitness facilities',
      'icon': Icons.fitness_center,
      'photo': 'assets/facilities/gym.jpg',
    },
    {
      'title': 'Welcome to Kolej Rahman Putra',
      'subtitle': 'KRP entrance landmark',
      'icon': Icons.location_on_outlined,
      'photo': 'assets/facilities/krp_entrance.jpg',
    },
  ];

  static const _mapsUrl =
      'https://maps.google.com/maps?udm&fvr=1&pvq=CgwvZy8xMTl0eXAzcnMiDQoHa3JwIGcwMRACGAM&lqi=CgdrcnAgZzAxSPid6p6ngYCACFoNEAAQASIHa3JwIGcwMZIBFnN0dWRlbnRfaG91c2luZ19jZW50ZXI&vet=10CAAQoqAOahcKEwigk5uS9IOYAxUAAAAAHQAAAAAQBg..i&cs=0&um=1&ie=UTF-8&fb=1&gl=my&sa=X&ftid=0x31da76ac90393b45:0xca01a207fd92c603';

  Future<void> _openMaps() async {
    try {
      // Launch directly from the click; do not await a permission check first.
      final opened = await launchUrl(
        Uri.parse(_mapsUrl),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (opened) return;
    } catch (_) {
      // Offer the link when the device cannot open it.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Could not open Maps. You can copy the link.'),
        action: SnackBarAction(
          label: 'Copy link',
          onPressed: () {
            Clipboard.setData(const ClipboardData(text: _mapsUrl));
          },
        ),
      ),
    );
  }

  void _showFacilityPhoto(Map<String, dynamic> item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item['title'] as String),
        content: SizedBox(
          width: 900,
          height: MediaQuery.sizeOf(dialogContext).height * 0.6,
          child: InteractiveViewer(
            child: Center(
              child: Image.asset(
                item['photo'] as String,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stackTrace) =>
                    const Text('Photo unavailable. Check the image assets.'),
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

  void _changePhoto(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _photoArrow({required bool next}) {
    final enabled = next
        ? _currentCarouselIndex < carouselItems.length - 1
        : _currentCarouselIndex > 0;
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.black.withValues(alpha: enabled ? 0.55 : 0.2),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: next ? 'Next facility photo' : 'Previous facility photo',
          onPressed: enabled
              ? () => _changePhoto(_currentCarouselIndex + (next ? 1 : -1))
              : null,
          icon: Icon(next ? Icons.chevron_right : Icons.chevron_left),
          color: Colors.white,
          disabledColor: Colors.white38,
        ),
      ),
    );
  }

  Widget _buildFacilityPhotos() {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final height = (constraints.maxWidth * 0.48)
                .clamp(250.0, 420.0)
                .toDouble();
            return SizedBox(
              height: height,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: carouselItems.length,
                    onPageChanged: (index) =>
                        setState(() => _currentCarouselIndex = index),
                    itemBuilder: (context, index) {
                      final item = carouselItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Material(
                            color: primaryGreen,
                            child: InkWell(
                              onTap: () => _showFacilityPhoto(item),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    item['photo'] as String,
                                    fit: BoxFit.cover,
                                    semanticLabel: item['title'] as String,
                                    errorBuilder: (_, error, stackTrace) =>
                                        Center(
                                          child: Icon(
                                            item['icon'] as IconData,
                                            color: accentLime,
                                            size: 64,
                                          ),
                                        ),
                                  ),
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Color(0xE6103B2B),
                                        ],
                                        stops: [0.25, 1],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 20,
                                    right: 20,
                                    bottom: 22,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 23,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item['subtitle'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Tap to view full photo',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 24,
                    top: 12,
                    child: _photoArrow(next: false),
                  ),
                  Positioned(
                    right: 24,
                    top: 12,
                    child: _photoArrow(next: true),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...List.generate(
              carouselItems.length,
              (index) => SizedBox(
                width: 40,
                height: 44,
                child: IconButton(
                  tooltip: 'View ${carouselItems[index]['title']}',
                  onPressed: () => _changePhoto(index),
                  icon: Icon(
                    _currentCarouselIndex == index
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 12,
                    color: _currentCarouselIndex == index
                        ? primaryGreen
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      widget.studentName.isNotEmpty
                          ? widget.studentName
                                .trim()
                                .split(' ')
                                .map((w) => w.isNotEmpty ? w[0] : '')
                                .take(2)
                                .join()
                                .toUpperCase()
                          : 'YX',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.studentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    widget.category,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('KRP Sports Complex Info'),
              selected: _selectedTab == 0,
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedTab = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Book a Facility'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FacilitiesScreen(
                      category: widget.category,
                      email: widget.email,
                      studentName: widget.studentName,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Booking Records'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedTab = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              selected: _selectedTab == 3,
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedTab = 3);
              },
            ),
            if (widget.onLogout != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Log out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onLogout!();
                },
              ),
            ],
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            final canPop = Navigator.canPop(context);
            if (canPop) {
              return IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              );
            }
            return IconButton(
              icon: const Icon(Icons.menu, size: 24),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Text(
          const [
            'KRP Sports Complex',
            'My Bookings',
            'Reports',
            'Profile',
          ][_selectedTab],
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF103B2B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, size: 22),
            tooltip: 'Booking Records',
            onPressed: () {
              setState(() => _selectedTab = 1);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied to clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          Stack(
            children: [
              ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // INFO TAB HEADER (Matching orange layout with green underline)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: subtleBorder)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: primaryGreen, width: 3),
                            ),
                          ),
                          child: Text(
                            'Info',
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildFacilityPhotos(),
                  const SizedBox(height: 16),

                  // VENUE LOCATION & DETAILS CARD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAF9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: subtleBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Kolej Rahman Putra (KRP) Sports Complex',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF103B2B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "G09 (RF), 601, Jalan Meranti 1, 80990 Johor Bahru, Johor Darul Ta’zim",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Tel: +60 7-553 3333 · KRP Office',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryGreen,
                                  side: BorderSide(color: primaryGreen),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: _openMaps,
                                icon: const Icon(Icons.map_outlined, size: 16),
                                label: const Text(
                                  'Open Maps',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // EXPANDABLE SECTIONS (Accordion Layout like Orange Reference)
                  _buildPricingSection(),
                  _buildOpeningHoursSection(),
                  _buildAmenitiesSection(),
                  _buildCentreLayoutSection(),
                  _buildCentrePolicySection(),
                ],
              ),
            ],
          ),
          _studentSection('student-bookings', 1),
          _studentSection('student-reports', 3),
          _studentSection('student-profile', 0),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: subtleBorder)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _bottomNavItem(
                  index: 0,
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                ),
                _bottomNavItem(
                  index: 1,
                  label: 'My Bookings',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                ),
                _createNavItem(),
                _bottomNavItem(
                  index: 2,
                  label: 'Reports',
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                ),
                _bottomNavItem(
                  index: 3,
                  label: 'Profile',
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _studentSection(String sectionKey, int initialTab) {
    return ProfileScreen(
      key: ValueKey(sectionKey),
      email: widget.email,
      fullName: widget.studentName,
      contact: widget.contact,
      matric: widget.matric,
      category: widget.category,
      initialTab: initialTab,
      navigationSection: true,
    );
  }

  Future<void> _openCreateBooking() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => FacilitiesScreen(
          category: widget.category,
          email: widget.email,
          studentName: widget.studentName,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  Widget _bottomNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final active = _selectedTab == index;
    return Expanded(
      child: Semantics(
        selected: active,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFE8F6C8)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    active ? activeIcon : icon,
                    color: active ? primaryGreen : Colors.grey.shade600,
                    size: 23,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    color: active ? primaryGreen : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _createNavItem() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Material(
                color: accentLime,
                elevation: 4,
                shadowColor: Colors.black26,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  tooltip: 'Create a booking',
                  onPressed: _openCreateBooking,
                  icon: Icon(Icons.add_rounded, color: primaryGreen, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. PRICING ACCORDION
  Widget _buildPricingSection() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.monetization_on_outlined, color: primaryGreen),
        title: const Text(
          'Pricing',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF103B2B),
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAF9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KRP SPORTS & COURT RATES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Color(0xFF103B2B),
                  ),
                ),
                const SizedBox(height: 12),
                _priceItem(
                  '🏸 Badminton Court (01 & 02)',
                  'RM 6/hour',
                  'RM 8/hour',
                  'Rubber court mat · high ceiling',
                ),
                _priceItem(
                  '🏓 Ping Pong Table (01 & 02)',
                  'RM 4/hour',
                  'RM 6/hour',
                  'Tournament standard table',
                ),
                _priceItem(
                  '🎱 Snooker Table',
                  'RM 10/hour',
                  'RM 12/hour',
                  'Full size regulation slate table',
                ),
                _priceItem(
                  '🎯 Dart Board',
                  'RM 3/hour',
                  'RM 5/hour',
                  'Professional electronic dartboard',
                ),
                _priceItem(
                  '🏋️ KRP Fitness Gym',
                  'RM 2/session',
                  'RM 4/session',
                  'Cardio & free-weights zone',
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Non-Peak: Weekdays, 5 PM – 7 PM',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Peak: Weekdays 8 PM – 11 PM, Weekends & Public Holidays',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceItem(
    String title,
    String krpRate,
    String nonKrpRate,
    String note,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                '• KRP Student: $krpRate',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF103B2B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '• Non-KRP: $nonKrpRate',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
          Text(
            note,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // 2. OPENING HOURS ACCORDION
  Widget _buildOpeningHoursSection() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.schedule_outlined, color: primaryGreen),
        title: const Text(
          'Opening Hours',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF103B2B),
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAF9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monday – Friday (Weekdays)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '5:00 PM – 11:00 PM',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Closed 7:00 PM – 8:00 PM for Maghrib prayer break',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Saturday & Sunday (Weekends)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '10:00 AM – 11:00 PM',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Sessions: 10 AM – 1 PM, 2 PM – 7 PM, 8 PM – 11 PM',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. AMENITIES & FACILITIES ACCORDION
  Widget _buildAmenitiesSection() {
    final amenities = [
      {'icon': Icons.wifi, 'label': 'WiFi'},
      {'icon': Icons.wc, 'label': 'Toilet'},
      {'icon': Icons.local_parking, 'label': 'Free Parking'},
      {'icon': Icons.local_drink, 'label': 'Water Dispenser'},
      {'icon': Icons.shower, 'label': 'Shower'},
      {'icon': Icons.mosque_outlined, 'label': 'Surau'},
    ];

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.sports_soccer_outlined, color: primaryGreen),
        title: const Text(
          'Amenities & Facilities',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF103B2B),
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAF9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Amenities',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: amenities.map((a) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF5E9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            a['icon'] as IconData,
                            size: 20,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a['label'] as String,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Facilities Available',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                        'Badminton Court 01',
                        'Badminton Court 02',
                        'Ping Pong Table 01',
                        'Ping Pong Table 02',
                        'Snooker Lounge',
                        'Dart Board',
                        'KRP Fitness Gym',
                      ].map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: subtleBorder),
                          ),
                          child: Text(
                            f,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. CENTRE LAYOUT ACCORDION
  Widget _buildCentreLayoutSection() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(Icons.grid_view_outlined, color: primaryGreen),
        title: const Text(
          'Centre Layout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF103B2B),
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAF9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KRP Sports Complex Floor Plan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    color: const Color(0xFF103B2B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _courtDiagramBox(
                                  'Badminton 01',
                                  const Color(0xFF1E6347),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _courtDiagramBox(
                                  'Badminton 02',
                                  const Color(0xFF1E6347),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _courtDiagramBox(
                                  'Ping Pong Area',
                                  const Color(0xFF2B7858),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _courtDiagramBox(
                                  'Snooker & Dart',
                                  const Color(0xFF235C43),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _courtDiagramBox(
                                  'Gym Room',
                                  const Color(0xFF3B8A68),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Both badminton courts are equipped with professional tournament-level LED lighting and rubber surfaces.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _courtDiagramBox(String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // 5. CENTRE POLICY ACCORDION
  Widget _buildCentrePolicySection() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(Icons.policy_outlined, color: primaryGreen),
        title: const Text(
          'Centre Policy',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF103B2B),
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAF9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sports Complex Policy & Booking Guidelines',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                _bulletPoint(
                  '1. Maximum Booking Duration: Each student is limited to a maximum of 2 consecutive hours per day to allow fair court access for all collegiates.',
                ),
                _bulletPoint(
                  '2. Verification: UTM student matric card or digital matric proof is required upon arrival at the sports facility.',
                ),
                _bulletPoint(
                  '3. Proper Attire: Non-marking sports shoes and appropriate sportswear are strictly required on all badminton courts and gym areas.',
                ),
                _bulletPoint(
                  '4. Cancellation & Refunds: Students cannot cancel bookings or submit refund requests. KRP Management handles eligible refunds when a booked facility is closed, under maintenance, or otherwise unavailable. Students can view refund progress under My Bookings.',
                ),
                _bulletPoint(
                  '5. Non-transferable: Reservations cannot be transferred or sublet to third parties without KRP management consent.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade700,
          height: 1.4,
        ),
      ),
    );
  }
}
