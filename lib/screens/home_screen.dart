import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'category_screen.dart';
import 'subcategory_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _HomeTab()),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: const [
        _HomeHeader(),
        SizedBox(height: 16),
        _SearchBar(),
        SizedBox(height: 12),
        _ProblemBanner(),
        SizedBox(height: 16),
        _ServiceCardGrid(),
        SizedBox(height: 16),
        _EmergencyBanner(),
        SizedBox(height: 20),
        _SectionHeader(title: 'Popular Services'),
        SizedBox(height: 12),
        _PopularServicesRow(),
        SizedBox(height: 20),
        _SectionHeader(title: 'Nearby Professionals'),
        SizedBox(height: 12),
        _ProfessionalCard(
          name: 'Ramesh Construction',
          category: 'General Construction',
          distanceKm: 2.3,
          rating: 4.8,
          reviewCount: 124,
        ),
        SizedBox(height: 12),
        _ProfessionalCard(
          name: 'Shiva Plumber',
          category: 'Plumbing Services',
          distanceKm: 1.7,
          rating: 4.7,
          reviewCount: 89,
        ),
        SizedBox(height: 12),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.home_rounded, color: AppColors.primary, size: 36),
            Positioned(
              right: 2,
              bottom: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accentOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'PAKKA',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Build · Maintain · Live Better',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 2),
            const Text(
              'Kathmandu',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
        const SizedBox(width: 12),
        const CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'What do you need?',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tell us your problem',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Share a photo or video, and we'll help you find the right solution.",
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ServiceCardGrid extends StatelessWidget {
  const _ServiceCardGrid();

  static final Map<String, WidgetBuilder> _servicesItemRoutes = {
    'Construction': (_) => const SubcategoryScreen(
          title: 'Construction',
          imagePathPrefix: 'assets/services/construction',
          itemCount: 12,
        ),
    'Electrical': (_) => const SubcategoryScreen(
          title: 'Electrical',
          imagePathPrefix: 'assets/services/electrical',
          itemCount: 12,
        ),
    'Cleaning': (_) => const SubcategoryScreen(
          title: 'Cleaning',
          imagePathPrefix: 'assets/services/cleaning',
          itemCount: 11,
        ),
    'Mason': (_) => const SubcategoryScreen(
          title: 'Mason',
          imagePathPrefix: 'assets/services/mason',
          itemCount: 11,
        ),
    'Appliance repair': (_) => const SubcategoryScreen(
          title: 'Appliance Repair',
          imagePathPrefix: 'assets/services/appliance-repair',
          itemCount: 12,
        ),
    'Plumbing': (_) => const SubcategoryScreen(
          title: 'Plumbing',
          imagePathPrefix: 'assets/services/plumbing',
          itemCount: 12,
        ),
    'Painting': (_) => const SubcategoryScreen(
          title: 'Painting',
          imagePathPrefix: 'assets/services/painting',
          itemCount: 10,
        ),
    'Carpenter': (_) => const SubcategoryScreen(
          title: 'Carpenter',
          imagePathPrefix: 'assets/services/carpenter',
          itemCount: 11,
        ),
    'Waterproofing': (_) => const SubcategoryScreen(
          title: 'Waterproofing',
          imagePathPrefix: 'assets/services/waterproofing',
          itemCount: 10,
        ),
    'Interior': (_) => const SubcategoryScreen(
          title: 'Interior',
          imagePathPrefix: 'assets/services/interior',
          itemCount: 16,
        ),
  };

  static final Map<String, WidgetBuilder> _shopItemRoutes = {
    'Cement': (_) => const SubcategoryScreen(
          title: 'Cement',
          imagePathPrefix: 'assets/shop/cement',
          itemCount: 6,
        ),
    'Electrical': (_) => const SubcategoryScreen(
          title: 'Electrical',
          imagePathPrefix: 'assets/shop/electricals',
          itemCount: 12,
        ),
    'Sanitaryware': (_) => const SubcategoryScreen(
          title: 'Sanitaryware',
          imagePathPrefix: 'assets/shop/sanitaryware',
          itemCount: 15,
        ),
    'Tools': (_) => const SubcategoryScreen(
          title: 'Tools',
          imagePathPrefix: 'assets/shop/tools',
          itemCount: 12,
        ),
    'Steel': (_) => const SubcategoryScreen(
          title: 'Steel',
          imagePathPrefix: 'assets/shop/steel',
          itemCount: 13,
        ),
    'Paint': (_) => const SubcategoryScreen(
          title: 'Paint',
          imagePathPrefix: 'assets/shop/paint',
          itemCount: 12,
        ),
    'Hardware': (_) => const SubcategoryScreen(
          title: 'Hardware',
          imagePathPrefix: 'assets/shop/hardware',
          itemCount: 18,
        ),
    'Water tanks': (_) => const SubcategoryScreen(
          title: 'Water Tanks',
          imagePathPrefix: 'assets/shop/watertanks',
          itemCount: 10,
        ),
    'Plumbing Materials': (_) => const SubcategoryScreen(
          title: 'Plumbing Materials',
          imagePathPrefix: 'assets/shop/plumbing',
          itemCount: 10,
        ),
    'Tiles': (_) => const SubcategoryScreen(
          title: 'Tiles',
          imagePathPrefix: 'assets/shop/tiles',
          itemCount: 9,
        ),
    'Roofing': (_) => const SubcategoryScreen(
          title: 'Roofing',
          imagePathPrefix: 'assets/shop/roofing',
          itemCount: 8,
        ),
    'Construction Chemicals': (_) => const SubcategoryScreen(
          title: 'Construction Chemicals',
          imagePathPrefix: 'assets/shop/construction-chemicals',
          itemCount: 8,
        ),
    'Safety': (_) => const SubcategoryScreen(
          title: 'Safety',
          imagePathPrefix: 'assets/shop/safety',
          itemCount: 7,
        ),
  };

  static final Map<String, Map<String, WidgetBuilder>> _cardItemRoutes = {
    'Services': _servicesItemRoutes,
    'Shop': _shopItemRoutes,
  };

  void _open(BuildContext context, _DashboardCard card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryScreen(
          title: card.title,
          subtitle: card.subtitle,
          icon: card.icon,
          iconColor: card.iconColor,
          items: card.allItems ?? [...card.columnA, ...card.columnB],
          itemRoutes: _cardItemRoutes[card.title],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const services = _DashboardCard(
      icon: Icons.engineering_rounded,
      iconColor: AppColors.accentOrange,
      title: 'Services',
      subtitle: 'Find a professional',
      gradient: AppColors.servicesGradient,
      columnA: ['Construction', 'Electrical', 'Cleaning', 'Mason', 'Appliance repair'],
      columnB: ['Plumbing', 'Painting', 'Carpenter', 'Waterproofing', 'Interior'],
    );
    const shop = _DashboardCard(
      icon: Icons.shopping_cart_rounded,
      iconColor: Color(0xFF3E9142),
      title: 'Shop',
      subtitle: 'Materials & hardware',
      gradient: AppColors.shopGradient,
      columnA: ['Cement', 'Electrical', 'Sanitaryware', 'Tools'],
      columnB: ['Steel', 'Paint', 'Hardware', 'Water tanks'],
      allItems: [
        'Cement',
        'Electrical',
        'Sanitaryware',
        'Tools',
        'Steel',
        'Paint',
        'Hardware',
        'Water tanks',
        'Plumbing Materials',
        'Tiles',
        'Roofing',
        'Construction Chemicals',
        'Safety',
      ],
    );
    const rentals = _DashboardCard(
      icon: Icons.precision_manufacturing_rounded,
      iconColor: Color(0xFF2E7BC4),
      title: 'Rentals',
      subtitle: 'Tools & equipment',
      gradient: AppColors.rentalsGradient,
      columnA: ['Scaffolding', 'Drilling machines', 'Concrete mixers', 'Construction equipment'],
      columnB: ['Ladders', 'Cutting machines', 'Generators'],
    );
    const bookings = _DashboardCard(
      icon: Icons.assignment_rounded,
      iconColor: Color(0xFF7A5FC7),
      title: 'Bookings',
      subtitle: 'Track your work',
      gradient: AppColors.bookingsGradient,
      columnA: ['Upcoming services', 'Previous services', 'Invoices'],
      columnB: ['Active jobs', 'Orders', 'Warranty'],
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _open(context, services),
                child: services,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _open(context, shop),
                child: shop,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _open(context, rentals),
                child: rentals,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _open(context, bookings),
                child: bookings,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.columnA,
    required this.columnB,
    this.allItems,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final List<String> columnA;
  final List<String> columnB;

  /// Full category list for the detail screen, when the card's two bullet
  /// columns only show a preview. Falls back to columnA + columnB.
  final List<String>? allItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 26),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textPrimary),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _BulletColumn(items: columnA)),
              Expanded(child: _BulletColumn(items: columnB)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulletColumn extends StatelessWidget {
  const _BulletColumn({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $item',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary, height: 1.3),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.emergencyGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.emergencyRed, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need urgent help?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.emergencyRed,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Find nearby emergency home services',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.call_rounded, size: 16),
            label: const Text('Call Now', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        Row(
          children: const [
            Text('See all', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ],
    );
  }
}

class _PopularServicesRow extends StatelessWidget {
  const _PopularServicesRow();

  static const _items = [
    ('Plumbing', 'assets/plumbing.png'),
    ('Electrical', 'assets/electrical.png'),
    ('Cleaning', 'assets/cleaning.png'),
    ('Painting', 'assets/painting.png'),
    ('AC Repair', 'assets/repair.png'),
    ('Waterproofing', 'assets/waterproofing.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _items
          .map(
            (item) => Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    height: 78,
                    child: Image.asset(item.$2, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({
    required this.name,
    required this.category,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
  });

  final String name;
  final String category;
  final double distanceKm;
  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFFE9EEF3),
            child: Icon(Icons.person, color: AppColors.textSecondary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(category, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                    Text('$distanceKm km', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF5A623)),
                    Text(
                      '$rating ($reviewCount)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Available today',
                    style: TextStyle(fontSize: 11, color: Color(0xFF3E9142), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Book Now', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
