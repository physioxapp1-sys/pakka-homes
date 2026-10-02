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

// ---------------------------------------------------------------------------
// Presentation for catalog entries.
//
// The catalog itself carries no artwork for a category tile, so the icon and
// tile colour live here. Anything unmapped still renders - it falls back to a
// generic icon and takes a colour from the rotation, so adding a category to
// the spreadsheet never leaves a blank tile.
// ---------------------------------------------------------------------------

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

/// Artwork for a category tile, keyed '<root>/<slug>' because 'electrical' and
/// 'paint' exist under both services and shop with different pictures.
///
/// Each image carries its own label and its own pale background, so the colour
/// here is that background sampled from the file's border. The tile paints it
/// behind a BoxFit.contain image: letterboxing becomes invisible, and nothing
/// crops the baked-in label the way BoxFit.cover would.
///
/// Partial by design - a slug with no entry falls back to the icon tile.
const _tileArt = <String, (Color, String)>{
  'services/carpenter': (Color(0xFFF2DEC5), 'assets/home/services/carpenter.png'),
  'services/cleaning': (Color(0xFFC2EDE3), 'assets/home/services/cleaning.png'),
  'services/construction': (Color(0xFFD5D1C6), 'assets/home/services/construction.png'),
  'services/electrical': (Color(0xFFDFEED7), 'assets/home/services/electrical.png'),
  'services/painting': (Color(0xFFC6E5E7), 'assets/home/services/painting.png'),
  'services/plumbing': (Color(0xFFE3F0F9), 'assets/home/services/plumbing.png'),
  'shop/cement': (Color(0xFFEBE0CE), 'assets/home/shop/cement.png'),
  'shop/electrical': (Color(0xFFC8E5C7), 'assets/home/shop/electrical.png'),
  'shop/hardware': (Color(0xFFE4BF95), 'assets/home/shop/hardware.png'),
  'shop/paint': (Color(0xFFC3DFEB), 'assets/home/shop/paint.png'),
  'rentals/concrete-mixer': (Color(0xFFCFE1F9), 'assets/home/rentals/concrete-mixer.png'),
  'rentals/excavator': (Color(0xFFD0E2FA), 'assets/home/rentals/excavator.png'),
  'rentals/generator': (Color(0xFFD0E2FA), 'assets/home/rentals/generator.png'),
  'rentals/jackhammer': (Color(0xFFCFE1F9), 'assets/home/rentals/jackhammer.png'),
  'rentals/scaffolding': (Color(0xFFCFE1F9), 'assets/home/rentals/scaffolding.png'),
};

const _tilePalette = <(Color, Color)>[
  (Color(0xFFE4F0FF), Color(0xFF1976D2)),
  (Color(0xFFFFF1D2), Color(0xFFF59E0B)),
  (Color(0xFFE2F7EC), Color(0xFF159570)),
  (Color(0xFFEDEAFF), Color(0xFF635BCE)),
  (Color(0xFFFFE5E2), Color(0xFFE53935)),
  (Color(0xFFE0F5FA), Color(0xFF0088A8)),
];

IconData _iconFor(String slug) => _categoryIcons[slug] ?? Icons.category_outlined;

(Color, Color) _coloursFor(int index) => _tilePalette[index % _tilePalette.length];

// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  /// Real tabs over an IndexedStack rather than pushing routes, so the bar
  /// keeps a truthful selected state and each tab holds its scroll position.
  late final List<Widget> _tabs = [
    _HomeTab(onSeeAll: (index) => setState(() => _tab = index)),
    CategoryScreen(
      title: 'Services',
      subtitle: 'Skilled professionals for your home needs',
      icon: Icons.engineering,
      iconColor: AppColors.orange,
      items: [for (final c in kServiceCategories) c.name],
      itemRoutes: routesFor(kServiceCategories, CatalogRepository.serviceVertical, 'services'),
    ),
    CategoryScreen(
      title: 'Shop',
      subtitle: 'Quality materials at the best price',
      icon: Icons.shopping_cart_rounded,
      iconColor: AppColors.green,
      items: [for (final c in kShopCategories) c.name],
      itemRoutes: routesFor(kShopCategories, CatalogRepository.shopVertical, 'shop'),
    ),
    const _ComingSoonTab(
      icon: Icons.precision_manufacturing,
      title: 'Rentals',
      message: 'Tools and equipment hire is on the way.',
    ),
    const MyBookingsScreen(),
  ];

  static Map<String, WidgetBuilder> routesFor(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        height: 70,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFE9B5),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.darkOrange),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build, color: AppColors.darkOrange),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart, color: AppColors.darkOrange),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.construction_outlined),
            selectedIcon: Icon(Icons.construction, color: AppColors.darkOrange),
            label: 'Rentals',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.darkOrange),
            label: 'Bookings',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onSeeAll});

  /// Switches the bottom-nav tab, so "View All" lands on the same screen the
  /// bar would reach rather than a parallel copy of it.
  final void Function(int tabIndex) onSeeAll;

  void _openCategory(BuildContext context, LocalCategory category, String vertical, String root) {
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _Header()),
          SliverToBoxAdapter(child: _Hero(onGetStarted: () => onSeeAll(1))),
          const SliverToBoxAdapter(child: _SearchBar()),
          const SliverToBoxAdapter(child: SizedBox(height: 25)),

          SliverToBoxAdapter(
            child: _SectionHeader(
              icon: Icons.engineering,
              title: 'Services',
              subtitle: 'Skilled professionals for your home needs',
              color: AppColors.orange,
              onViewAll: () => onSeeAll(1),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 135,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: kServiceCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final category = kServiceCategories[i];
                  final (bg, fg) = _coloursFor(i);
                  return _CategoryTile(
                    artKey: 'services/${category.slug}',
                    title: category.name,
                    icon: _iconFor(category.slug),
                    background: bg,
                    iconColor: fg,
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
              iconColor: AppColors.green,
              onHeaderTap: () => onSeeAll(2),
              items: [
                for (final category in kShopCategories)
                  _SectionItem(
                    artKey: 'shop/${category.slug}',
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
              iconColor: AppColors.indigo,
              onHeaderTap: () => onSeeAll(3),
              // These five are exactly the rental artwork that exists, so the
              // row is all pictures and no fallbacks.
              items: [
                for (final (slug, title, icon) in const [
                  ('scaffolding', 'Scaffolding', Icons.grid_view_rounded),
                  ('generator', 'Generator', Icons.bolt),
                  ('concrete-mixer', 'Concrete Mixer', Icons.rotate_right),
                  ('jackhammer', 'Jackhammer', Icons.hardware),
                  ('excavator', 'Excavator', Icons.agriculture),
                ])
                  _SectionItem(
                    artKey: 'rentals/$slug',
                    title: title,
                    icon: icon,
                    onTap: () => onSeeAll(3),
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
              iconColor: const Color(0xFFE64A19),
              onHeaderTap: () => onSeeAll(4),
              items: [
                for (final (title, icon) in const [
                  ('My Bookings', Icons.event_available),
                  ('Track Booking', Icons.local_shipping),
                ])
                  _SectionItem(
                    artKey: 'bookings/${title.toLowerCase()}',
                    title: title,
                    icon: icon,
                    onTap: () => onSeeAll(4),
                  ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 25)),
          const SliverToBoxAdapter(child: _TrustRow()),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Pakka ', style: TextStyle(color: AppColors.navy)),
                      TextSpan(text: 'Homes', style: TextStyle(color: AppColors.orange)),
                    ],
                  ),
                ),
                Text(
                  'Build • Fix • Improve',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.blue, size: 20),
                  SizedBox(width: 3),
                  Text(
                    'Kathmandu',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                  Icon(Icons.keyboard_arrow_down, size: 18),
                ],
              ),
              SizedBox(height: 6),
              _AccountButton(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Signed out it opens sign-in; signed in it opens the account screen. This is
/// the only permanent way in - nothing else in the app demands an account.
class _AccountButton extends StatelessWidget {
  const _AccountButton();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              auth.isSignedIn ? AccountScreen(auth: auth) : AuthScreen(auth: auth),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            auth.isSignedIn ? Icons.account_circle : Icons.account_circle_outlined,
            size: 27,
            color: AppColors.navy,
          ),
          const SizedBox(width: 3),
          Text(
            auth.isSignedIn ? 'Account' : 'Sign in',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.20),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -25,
              bottom: -15,
              child: Icon(
                Icons.home_work_rounded,
                size: 190,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Home\nOur Priority',
                    style: TextStyle(
                      fontSize: 29,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 260,
                    child: Text(
                      'Trusted services, quality materials and everything you '
                      'need — all in one place.',
                      style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.navy),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onGetStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Get Started', style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
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
    required this.color,
    required this.onViewAll,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 23),
          ),
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

/// A category tile. Renders the supplied artwork when there is some for this
/// slug, and an icon with a text label when there is not.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.artKey,
    required this.title,
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
    this.width = 108,
    this.radius = 18,
  });

  final String artKey;
  final String title;
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final art = _tileArt[artKey];

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: art == null
              ? Container(
                  color: background,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: iconColor, size: 35),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  color: art.$1,
                  // The label is part of the picture, so nothing is drawn over
                  // it and contain keeps it from being cropped.
                  child: Image.asset(
                    art.$2,
                    fit: BoxFit.contain,
                    // A missing file should cost one tile, not the whole row.
                    errorBuilder: (_, __, ___) =>
                        Icon(icon, color: iconColor, size: 35),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SectionItem {
  const _SectionItem({
    required this.artKey,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String artKey;
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
    required this.iconColor,
    required this.items,
    required this.onHeaderTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color iconColor;
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
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: iconColor, size: 25),
                  ),
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
            const SizedBox(height: 15),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final art = _tileArt[item.artKey];

                  // With artwork the picture is the whole card. Without it,
                  // the white card with a circled icon from the design.
                  if (art != null) {
                    return _CategoryTile(
                      artKey: item.artKey,
                      title: item.title,
                      icon: item.icon,
                      background: background,
                      iconColor: iconColor,
                      onTap: item.onTap,
                      width: 120,
                      radius: 15,
                    );
                  }

                  return GestureDetector(
                    onTap: item.onTap,
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: background,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, color: iconColor, size: 28),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
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

// ---------------------------------------------------------------------------
// Trust strip
// ---------------------------------------------------------------------------

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TrustItem(
                icon: Icons.verified_user, title: 'Verified', subtitle: 'Professionals'),
            _TrustItem(icon: Icons.verified, title: 'Quality', subtitle: 'Products'),
            _TrustItem(icon: Icons.local_shipping, title: 'Fast &', subtitle: 'Reliable'),
            _TrustItem(icon: Icons.support_agent, title: '24/7', subtitle: 'Support'),
          ],
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.blue, size: 27),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({
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
