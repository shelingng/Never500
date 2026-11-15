import 'dart:async';

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
  static const Color primaryGreen = Color(0xFF1A332C);
  static const Color cardGreen = Colors.white;
  static const Color accentLime = Color(0xFFC5F84B);
  static const Color mutedText = Color(0xFF66756D);
  static const Color subtleBorder = Color(0xFFE2E9E4);
  static const Color paleGreen = Color(0xFFEDF4EF);
  static const Color pageBackground = Color(0xFFF4F6F4);
  static const Color sidebarMuted = Color(0xFFA0B0A8);

  int _selectedTab = 0;
  int _currentCarouselIndex = 0;
  final PageController _pageController = PageController();
  Timer? _hoursRefreshTimer;

  final List<Map<String, dynamic>> carouselItems = [
    {
      'title': 'Welcome to Kolej Rahman Putra',
      'subtitle': 'Your home for sports, fitness and recreation',
      'icon': Icons.location_on_outlined,
      'photo': 'assets/facilities/krp_entrance.jpg',
    },
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
  ];

  @override
  void initState() {
    super.initState();
    _hoursRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

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
                        ? accentLime
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
    _hoursRefreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      drawer: Drawer(
        backgroundColor: primaryGreen,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF23433A)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: accentLime,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.sports_tennis,
                            color: primaryGreen,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'KRP PLAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CircleAvatar(
                      radius: 20,
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
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _drawerItem(
                      icon: Icons.home_outlined,
                      title: 'Home',
                      selected: _selectedTab == 0,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedTab = 0);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.calendar_month_outlined,
                      title: 'Book a Facility',
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
                    _drawerItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'My Bookings',
                      selected: _selectedTab == 1,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedTab = 1);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.chat_bubble_outline,
                      title: 'Reports',
                      selected: _selectedTab == 2,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedTab = 2);
                      },
                    ),
                    _drawerItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      selected: _selectedTab == 3,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedTab = 3);
                      },
                    ),
                  ],
                ),
              ),
              if (widget.onLogout != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: subtleBorder),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
                    title: const Text(
                      'Log out',
                      style: TextStyle(color: Color(0xFFFF6B6B)),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onLogout!();
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
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
            color: Colors.white,
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
      body: Theme(
        data: Theme.of(context).copyWith(
          brightness: Brightness.light,
          colorScheme: Theme.of(context).colorScheme.copyWith(
            brightness: Brightness.light,
            primary: primaryGreen,
            secondary: accentLime,
            surface: Colors.white,
            onSurface: primaryGreen,
          ),
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: primaryGreen,
            displayColor: primaryGreen,
          ),
          dividerColor: subtleBorder,
          scaffoldBackgroundColor: pageBackground,
        ),
        child: IndexedStack(
          index: _selectedTab,
          children: [
            Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _buildFacilityPhotos(),
                    const SizedBox(height: 16),

                    // VENUE LOCATION & DETAILS CARD
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardGreen,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Kolej Rahman Putra (KRP) Sports Complex',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "G09 (RF), 601, Jalan Meranti 1, 80990 Johor Bahru, Johor Darul Ta’zim",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: mutedText,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tel: +60 7-553 3333 · KRP Office',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: accentLime,
                                    foregroundColor: primaryGreen,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: _openMaps,
                                  icon: const Icon(
                                    Icons.map_outlined,
                                    size: 16,
                                  ),
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
    final profile = ProfileScreen(
      key: ValueKey(sectionKey),
      email: widget.email,
      fullName: widget.studentName,
      contact: widget.contact,
      matric: widget.matric,
      category: widget.category,
      initialTab: initialTab,
      navigationSection: true,
    );
    return profile;
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final foreground = selected ? primaryGreen : sidebarMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? accentLime : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          selected: selected,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: Icon(icon, color: foreground),
          title: Text(
            title,
            style: TextStyle(
              color: foreground,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          onTap: onTap,
        ),
      ),
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
                    color: active ? accentLime : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    active ? activeIcon : icon,
                    color: active ? primaryGreen : mutedText,
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
                    color: active ? primaryGreen : mutedText,
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
            color: primaryGreen,
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: [
          _priceItem(
            Icons.sports_tennis,
            'Badminton Court (01 & 02)',
            'RM 6/hour',
            'RM 8/hour',
          ),
          _priceItem(
            Icons.sports_tennis_outlined,
            'Ping Pong Table (01 & 02)',
            'RM 4/hour',
            'RM 6/hour',
          ),
          _priceItem(Icons.sports, 'Snooker Table', 'RM 10/hour', 'RM 12/hour'),
          _priceItem(
            Icons.track_changes_outlined,
            'Dart Board',
            'RM 3/hour',
            'RM 5/hour',
          ),
          _priceItem(
            Icons.fitness_center,
            'KRP Fitness Gym',
            'RM 2/session',
            'RM 4/session',
          ),
        ],
      ),
    );
  }

  Widget _priceItem(
    IconData icon,
    String title,
    String krpRate,
    String nonKrpRate,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: subtleBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C173F32),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: paleGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primaryGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: primaryGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: subtleBorder),
            ),
            Row(
              children: [
                Expanded(child: _rateBlock('KRP Student', krpRate, true)),
                const SizedBox(width: 12),
                Expanded(child: _rateBlock('Non-KRP', nonKrpRate, false)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateBlock(String label, String rate, bool highlighted) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlighted ? accentLime : pageBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: primaryGreen.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rate,
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 2. OPENING HOURS ACCORDION
  Widget _buildOpeningHoursSection() {
    final isOpen = _isFacilityOpen(DateTime.now());
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
            color: primaryGreen,
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
              color: cardGreen,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: isOpen ? accentLime : const Color(0xFFD64545),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOpen ? 'Open now' : 'Closed',
                      style: TextStyle(
                        color: isOpen ? primaryGreen : const Color(0xFFD64545),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _hoursRow(
                  'Monday - Friday (Weekdays)',
                  '05:00 PM - 07:00 PM',
                  '09:00 PM - 11:00 PM',
                ),
                const Divider(height: 24),
                _hoursRow(
                  'Saturday - Sunday (Weekends)',
                  '10:00 AM - 01:00 PM',
                  '03:00 PM - 07:00 PM',
                  '09:00 PM - 11:00 PM',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isFacilityOpen(DateTime now) {
    final minuteOfDay = now.hour * 60 + now.minute;
    final sessions =
        now.weekday >= DateTime.monday && now.weekday <= DateTime.friday
        ? const [(17 * 60, 19 * 60), (21 * 60, 23 * 60)]
        : const [(10 * 60, 13 * 60), (15 * 60, 19 * 60), (21 * 60, 23 * 60)];
    return sessions.any(
      (session) => minuteOfDay >= session.$1 && minuteOfDay < session.$2,
    );
  }

  Widget _hoursRow(String days, String first, String second, [String? third]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(days, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [first, second, ?third].map((hours) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: paleGreen,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                hours,
                style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
      {'icon': Icons.mosque_outlined, 'label': 'Prayer Room'},
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
            color: primaryGreen,
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
              color: cardGreen,
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
                            color: paleGreen,
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
                          style: const TextStyle(
                            fontSize: 10,
                            color: mutedText,
                          ),
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
                            color: paleGreen,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: subtleBorder),
                          ),
                          child: Text(
                            f,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: primaryGreen,
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
        leading: Icon(Icons.map_outlined, color: primaryGreen),
        title: const Text(
          'Centre Layout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/facilities/krp_complex_layout.png',
                    width: double.infinity,
                    fit: BoxFit.contain,
                    semanticLabel:
                        'Kolej Rahman Putra sports complex layout map',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Both badminton courts are equipped with professional tournament-level LED lighting and rubber surfaces.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: primaryGreen,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            color: primaryGreen,
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
              color: cardGreen,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sports Complex Policy & Booking Guidelines',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: primaryGreen,
                  ),
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
        style: TextStyle(fontSize: 12, color: mutedText, height: 1.4),
      ),
    );
  }
}
