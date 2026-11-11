import 'package:flutter/material.dart';
import 'facilities_screen.dart';

class FacilityInfoScreen extends StatefulWidget {
  final String category;
  final String email;

  const FacilityInfoScreen({
    super.key,
    required this.category,
    required this.email,
  });

  @override
  State<FacilityInfoScreen> createState() => _FacilityInfoScreenState();
}

class _FacilityInfoScreenState extends State<FacilityInfoScreen> {
  final Color primaryGreen = const Color(0xFF103B2B);
  final Color accentLime = const Color(0xFFD2F865);
  final Color subtleBorder = const Color(0xFFE9EFEA);

  int _currentCarouselIndex = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> carouselItems = [
    {
      'title': 'KRP Badminton Arena',
      'subtitle': 'Courts 01 & 02 · Tournament-grade synthetic flooring',
      'icon': Icons.sports_tennis,
      'gradient': [const Color(0xFF103B2B), const Color(0xFF1B5E44)],
    },
    {
      'title': 'Table Tennis Hall',
      'subtitle': 'Tables 01 & 02 · High-rebound standard tables',
      'icon': Icons.sports_tennis_rounded,
      'gradient': [const Color(0xFF144533), const Color(0xFF226E51)],
    },
    {
      'title': 'KRP Fitness Centre & Gym',
      'subtitle': 'Free weights, cardio equipment & resistance machines',
      'icon': Icons.fitness_center,
      'gradient': [const Color(0xFF0F3626), const Color(0xFF18553D)],
    },
    {
      'title': 'Snooker & Dart Lounge',
      'subtitle': 'Regulation snooker table & electronic dartboards',
      'icon': Icons.sports_baseball_outlined,
      'gradient': [const Color(0xFF0B2B1E), const Color(0xFF154834)],
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'KRP Sports Complex',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF103B2B),
          ),
        ),
        actions: [
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
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 100),
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
                          horizontal: 24, vertical: 14),
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

              // PHOTO / FACILITY SHOWCASE CAROUSEL
              SizedBox(
                height: 190,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: carouselItems.length,
                  onPageChanged: (index) {
                    setState(() => _currentCarouselIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final item = carouselItems[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: item['gradient'] as List<Color>,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGreen.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Subtle background pattern
                            Positioned(
                              right: -20,
                              bottom: -20,
                              child: Icon(
                                item['icon'] as IconData,
                                size: 140,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: accentLime.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          item['icon'] as IconData,
                                          color: accentLime,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        item['title'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['subtitle'] as String,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // CAROUSEL DOT INDICATORS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  carouselItems.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentCarouselIndex == index ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentCarouselIndex == index
                          ? primaryGreen
                          : const Color(0xFFD6DFD8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

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
                                  'Jalan Pontian Lama, Universiti Teknologi Malaysia, 81310 Skudai, Johor',
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
                                  horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Opening Google Maps: Kolej Rahman Putra UTM',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map_outlined, size: 16),
                            label: const Text('Open Maps',
                                style: TextStyle(fontSize: 12)),
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

          // STICKY BOTTOM "BOOK NOW" BAR (Green theme)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FacilitiesScreen(
                            category: widget.category,
                            email: widget.email,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            size: 18, color: accentLime),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                _priceItem('🏸 Badminton Court (01 & 02)', 'RM 6/hour',
                    'RM 8/hour', 'Rubber court mat · high ceiling'),
                _priceItem('🏓 Ping Pong Table (01 & 02)', 'RM 4/hour',
                    'RM 6/hour', 'Tournament standard table'),
                _priceItem('🎱 Snooker Table', 'RM 10/hour', 'RM 12/hour',
                    'Full size regulation slate table'),
                _priceItem('🎯 Dart Board', 'RM 3/hour', 'RM 5/hour',
                    'Professional electronic dartboard'),
                _priceItem('🏋️ KRP Fitness Gym', 'RM 2/session', 'RM 4/session',
                    'Cardio & free-weights zone'),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Non-Peak: Weekdays, 5 PM – 7 PM',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        size: 14, color: Colors.deepOrange),
                    const SizedBox(width: 6),
                    Text(
                      'Peak: Weekdays 8 PM – 11 PM, Weekends & Public Holidays',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
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
      String title, String krpRate, String nonKrpRate, String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
          Text(note,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    const Text('Monday – Friday (Weekdays)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '5:00 PM – 11:00 PM',
                      style: TextStyle(
                          color: primaryGreen, fontWeight: FontWeight.bold),
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
                    const Text('Saturday & Sunday (Weekends)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '10:00 AM – 11:00 PM',
                      style: TextStyle(
                          color: primaryGreen, fontWeight: FontWeight.bold),
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
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                const Text('Amenities',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                          child: Icon(a['icon'] as IconData,
                              size: 20, color: primaryGreen),
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
                const Text('Facilities Available',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
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
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: subtleBorder),
                      ),
                      child: Text(
                        f,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
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
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                    'Badminton 01', const Color(0xFF1E6347)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _courtDiagramBox(
                                    'Badminton 02', const Color(0xFF1E6347)),
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
                                    'Ping Pong Area', const Color(0xFF2B7858)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _courtDiagramBox(
                                    'Snooker & Dart', const Color(0xFF235C43)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _courtDiagramBox(
                                    'Gym Room', const Color(0xFF3B8A68)),
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
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  '4. Cancellation & Rescheduling: Cancellations made more than 24 hours prior are eligible for full credit refund.',
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
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
      ),
    );
  }
}

