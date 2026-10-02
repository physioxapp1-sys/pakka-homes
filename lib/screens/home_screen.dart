import 'package:flutter/material.dart';

import '../data/auth_scope.dart';
import '../data/catalog_repository.dart';
import '../data/local_catalog.dart';
import '../theme/app_colors.dart';
import 'account_screen.dart';
import 'auth_screen.dart';
import 'category_screen.dart';
import 'my_bookings_screen.dart';
import 'subcategory_screen.dart';

/// Icon per catalog slug. Anything unmapped still renders - it falls back to a
/// generic icon - so a new row in the spreadsheet never leaves a blank tile.
const _categoryIcons = <String, IconData>{
  // services
  'construction': Icons.engineering,
  'electrical': Icons.electric_bolt,
  'cleaning': Icons.cleaning_services,
  'mason': Icons.foundation,
  'appliance-repair': Icons.home_repair_service,
  'plumbing': Icons.plumbing,
  'painting': Icons.format_paint,
  'carpenter': Icons.handyman,
  'waterproofing': Icons.water_drop,
  'interior': Icons.weekend,
  // shop
  'cement': Icons.inventory_2,
  'sanitary-ware': Icons.bathtub,
  'tools': Icons.build,
  'steel': Icons.straighten,
  'paint': Icons.imagesearch_roller,
  'hardware': Icons.hardware,
  'water-tanks': Icons.water,
  'plumbing-materials': Icons.plumbing,
  'tiles': Icons.grid_view,
  'roofing': Icons.roofing,
  'construction-chemicals': Icons.science,
  'safety': Icons.health_and_safety,
};

IconData _iconFor(String slug) => _categoryIcons[slug] ?? Icons.category_outlined;

Map<String, WidgetBuilder> _routesFor(
  List<LocalCategory> categories,
  String vertical,
  String assetRoot,
) {
  return {
    for (final category in categories)
      category.name: (_) => SubcategoryScreen(
            title: category.name,
            imagePathPrefix: category.assetPathPrefix(assetRoot),
            itemCount: category.imageCount,
            vertical: vertical,
            categorySlug: category.slug,
          ),
  };
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCategory(
      BuildContext context, LocalCategory category, String vertical, String root) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubcategoryScreen(
          title: category.name,
          imagePathPrefix: category.assetPathPrefix(root),
          itemCount: category.imageCount,
          vertical: vertical,
          categorySlug: category.slug,
        ),
      ),
    );
  }

  void _openServices(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryScreen(
          title: 'Services',
          subtitle: 'Skilled professionals for your home needs',
          icon: Icons.engineering,
          iconColor: AppColors.green,
          items: [for (final c in kServiceCategories) c.name],
          itemRoutes:
              _routesFor(kServiceCategories, CatalogRepository.serviceVertical, 'services'),
        ),
      ),
    );
  }

  void _openShop(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryScreen(
          title: 'Shop',
          subtitle: 'Quality materials at the best price',
          icon: Icons.shopping_cart_rounded,
          iconColor: AppColors.green,
          items: [for (final c in kShopCategories) c.name],
          itemRoutes: _routesFor(kShopCategories, CatalogRepository.shopVertical, 'shop'),
        ),
      ),
    );
  }

  void _openRentals(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _ComingSoonScreen(
          icon: Icons.precision_manufacturing,
          title: 'Rentals',
          message: 'Tools and equipment hire is on the way.',
        ),
      ),
    );
  }

  void _openBookings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            const SliverToBoxAdapter(child: _Hero()),
            const SliverToBoxAdapter(child: _SearchBar()),
            const SliverToBoxAdapter(child: SizedBox(height: 25)),

            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.engineering,
                title: 'Services',
                subtitle: 'Skilled professionals for your home needs',
                onViewAll: () => _openServices(context),
              ),
            ),
            // Breathing room between the section header and its row.
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 112,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  scrollDirection: Axis.horizontal,
                  itemCount: kServiceCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final category = kServiceCategories[i];
                    return _IconTile(
                      title: category.name,
                      icon: _iconFor(category.slug),
                      onTap: () => _openCategory(
                          context, category, CatalogRepository.serviceVertical, 'services'),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            SliverToBoxAdapter(
              child: _CategorySection(
                title: 'Shop',
                subtitle: 'Quality materials at the best price',
                icon: Icons.shopping_cart_rounded,
                background: AppColors.lightGreen,
                onHeaderTap: () => _openShop(context),
                items: [
                  for (final category in kShopCategories)
                    _SectionItem(
                      title: category.name,
                      icon: _iconFor(category.slug),
                      onTap: () => _openCategory(
                          context, category, CatalogRepository.shopVertical, 'shop'),
                    ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
              child: _CategorySection(
                title: 'Rentals',
                subtitle: 'Tools & equipment for your projects',
                icon: Icons.precision_manufacturing,
                background: AppColors.lightPurple,
                onHeaderTap: () => _openRentals(context),
                items: [
                  for (final (title, icon) in const [
                    ('Scaffolding', Icons.grid_view_rounded),
                    ('Generator', Icons.bolt),
                    ('Water Tank', Icons.water_drop),
                    ('Jackhammer', Icons.hardware),
                    ('Excavator', Icons.agriculture),
                  ])
                    _SectionItem(
                      title: title,
                      icon: icon,
                      onTap: () => _openRentals(context),
                    ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
              child: _CategorySection(
                title: 'Booking',
                subtitle: 'Easy booking. Save time.',
                icon: Icons.calendar_month,
                background: AppColors.lightOrange,
                onHeaderTap: () => _openBookings(context),
                items: [
                  for (final (title, icon) in const [
                    ('My Bookings', Icons.event_available),
                    ('Track Booking', Icons.local_shipping),
                  ])
                    _SectionItem(
                      title: title,
                      icon: icon,
                      onTap: () => _openBookings(context),
                    ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.orange, AppColors.darkOrange],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.home_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(text: 'Pakka ', style: TextStyle(color: AppColors.navy)),
                  TextSpan(text: 'Homes', style: TextStyle(color: AppColors.orange)),
                ],
              ),
            ),
          ),
          const _AccountButton(),
        ],
      ),
    );
  }
}

/// Icon only. Signed out it opens sign-in, signed in the account screen - the
/// only permanent way in, since nothing else in the app demands an account.
class _AccountButton extends StatelessWidget {
  const _AccountButton();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return IconButton(
      tooltip: auth.isSignedIn ? 'Account' : 'Sign in',
      iconSize: 30,
      color: AppColors.navy,
      icon: Icon(
        auth.isSignedIn ? Icons.account_circle : Icons.account_circle_outlined,
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              auth.isSignedIn ? AccountScreen(auth: auth) : AuthScreen(auth: auth),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Container(
        // The headline and subtitle are part of the artwork, and with no
        // button over it the banner can keep the image's own 2.83:1 aspect
        // instead of a fixed height that would crop it.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.20),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: AspectRatio(
            aspectRatio: 1280 / 452,
            child: Image.asset(
              'assets/home/hero.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        // The backend already supports /subcategories/?search=, but there is
        // no results screen yet, so this says so rather than pretending.
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search is coming soon')),
        ),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            children: [
              SizedBox(width: 18),
              Icon(Icons.search, size: 28, color: AppColors.navy),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search services, products, rentals...',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
              Icon(Icons.qr_code_scanner_rounded, color: AppColors.blue),
              SizedBox(width: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onViewAll,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _IconBadge(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.navy,
              visualDensity: VisualDensity.compact,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View All',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// White square, green glyph - the one icon treatment used everywhere.
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, this.size = 42, this.iconSize = 24});

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Icon(icon, color: AppColors.green, size: iconSize),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.green, size: 34),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionItem {
  const _SectionItem({required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.items,
    required this.onHeaderTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final List<_SectionItem> items;
  final VoidCallback onHeaderTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 15),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onHeaderTap,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  _IconBadge(icon: icon, iconSize: 25),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 15, color: AppColors.navy),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _IconTile(
                    title: item.title,
                    icon: item.icon,
                    onTap: item.onTap,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: AppColors.textSecondary),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
