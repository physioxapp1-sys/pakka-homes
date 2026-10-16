import 'package:flutter/material.dart';

import '../data/auth_scope.dart';
import '../data/catalog_repository.dart';
import '../data/local_catalog.dart';
import '../data/nepali_date.dart';
import '../theme/app_colors.dart';
import 'account_screen.dart';
import 'auth_screen.dart';
import 'category_screen.dart';
import 'maid_services_screen.dart';
import 'product_list_screen.dart';
import 'my_orders_screen.dart';
import 'rent_screen.dart';
import 'subcategory_screen.dart';

/// What the four service tiles offer.
///
/// All four tiles are live now.
class _Service {
  const _Service({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tileColor,
    required this.art,
    this.textOnRight = false,
    this.open,
  });

  final String title;
  final String subtitle;

  /// Drawn only where the artwork is missing, and on the dimmed card.
  final IconData icon;
  final Color color;
  final Color tileColor;

  /// The banner behind the card.
  final String art;

  /// Each banner leaves one end clear for the words. Grocery's vegetables sit
  /// on the left, so its title goes right; the other three are the other way
  /// round. Measured off the artwork rather than guessed.
  final bool textOnRight;

  /// Null means not built yet.
  final void Function(BuildContext context)? open;

  bool get isActive => open != null;
}

LocalCategory _category(String slug) =>
    kServiceCategories.firstWhere((c) => c.slug == slug);

void _openCategory(BuildContext context, String slug) {
  final category = _category(slug);
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SubcategoryScreen(
        title: category.name,
        vertical: CatalogRepository.serviceVertical,
        categorySlug: category.slug,
        sellsProducts: category.sellsProducts,
      ),
    ),
  );
}

/// Maintenance is a grouping, not a catalog category - it fans out to the
/// three trades underneath it.
const _maintenanceSlugs = [
  'plumbing',
  'electrical',
  'cleaning',
  'appliance-repair',
  'waterproofing',
];

/// Maid is the one category you pick several of, so it has its own screen
/// rather than the usual grid of tiles that each open something.
void _openRent(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const RentScreen()),
  );
}

void _openMaid(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const MaidServicesScreen()),
  );
}

void _openMaintenance(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CategoryScreen(
        title: 'Maintenance',
        subtitle: 'Repairs and upkeep for your home',
        icon: Icons.build_rounded,
        iconColor: AppColors.blue,
        items: [for (final s in _maintenanceSlugs) _category(s).name],
        slugs: _maintenanceSlugs,
        itemRoutes: {
          for (final s in _maintenanceSlugs)
            _category(s).name: (_) => SubcategoryScreen(
                  title: _category(s).name,
                  vertical: CatalogRepository.serviceVertical,
                  categorySlug: _category(s).slug,
                  sellsProducts: _category(s).sellsProducts,
                ),
        },
      ),
    ),
  );
}

const _services = <_Service>[
  _Service(
    title: 'Grocery',
    art: 'assets/home/tiles/grocery.webp',
    textOnRight: true,
    subtitle: 'Fresh groceries &\ndaily essentials',
    icon: Icons.shopping_basket_rounded,
    color: Color(0xFF138653),
    tileColor: AppColors.tileGreen,
    open: _openGrocery,
  ),
  _Service(
    title: 'Rent',
    art: 'assets/home/tiles/rent.webp',
    subtitle: 'Homes, rooms &\nproperties for rent',
    icon: Icons.key_rounded,
    color: AppColors.orange,
    tileColor: AppColors.tileOrange,
    open: _openRent,
  ),
  _Service(
    title: 'Househelp',
    art: 'assets/home/tiles/househelp.webp',
    subtitle: 'Cooking, cleaning &\ntrusted daily help',
    icon: Icons.cleaning_services_rounded,
    color: AppColors.purple,
    tileColor: AppColors.tilePurple,
    open: _openMaid,
  ),
  _Service(
    title: 'Maintenance',
    art: 'assets/home/tiles/maintenance.webp',
    subtitle: 'Plumbing, electrical,\nrepair & more',
    icon: Icons.build_rounded,
    color: AppColors.blue,
    tileColor: AppColors.tileBlue,
    open: _openMaintenance,
  ),
];

/// Straight to what is for sale. Grocery used to open on four aisle tiles -
/// Vegetables, Rice, Dairy, Gas - which was a tap and a screen between
/// someone and a tomato, for a shop with thirteen things in it.
void _openGrocery(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const ProductListScreen(
        title: 'Grocery',
        categorySlug: 'grocery',
      ),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  void _goToTab(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            _HomeTab(onViewAll: () => _goToTab(1)),
            const _CategoriesTab(),
            const MyOrdersScreen(),
            const _AccountTab(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _tab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE4F3EB),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: _goToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded, color: Color(0xFF69778B)),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.green),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded, color: Color(0xFF69778B)),
            selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.green),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined, color: Color(0xFF69778B)),
            selectedIcon: Icon(Icons.assignment_outlined, color: AppColors.green),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: Color(0xFF69778B)),
            selectedIcon: Icon(Icons.person_outline_rounded, color: AppColors.green),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: 18),
          const _Banner(),
          const SizedBox(height: 30),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Our Services',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text(
                  'View All  ›',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _ServiceGrid(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    // The mark and the way in to an account. The name and the tagline used to
    // sit between them, saying what the four tiles below already show.
    return Row(
      children: [
        Image.asset(
          'assets/home/logo.png',
          width: 54,
          height: 54,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.house_siding_rounded,
                size: 36, color: Color(0xFF603719)),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => auth.isSignedIn
                  ? AccountScreen(auth: auth)
                  : AuthScreen(auth: auth),
            ),
          ),
          borderRadius: BorderRadius.circular(30),
          child: CircleAvatar(
            radius: 23,
            backgroundColor: const Color(0xFFE4F0FF),
            child: Icon(
              auth.isSignedIn
                  ? Icons.person_rounded
                  : Icons.person_outline_rounded,
              color: AppColors.navy,
              size: 29,
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    // Null outside the calendar table, which is 2000-2090 BS. Then the banner
    // simply carries no date rather than a wrong one.
    final today = NepaliDate.today();

    return ClipRRect(
      borderRadius: BorderRadius.circular(27),
      // The mock's 205pt works now. The banner is 1.63:1 against the slot's
      // ~1.71:1, so cover trims a sliver of height and nothing else - the
      // previous photo was 2.83:1 and lost 39% of its width here.
      child: SizedBox(
        width: double.infinity,
        height: 205,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/home/hero.webp',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFBFE3F4),
                        Color(0xFF8DC5A1),
                        Color(0xFF447D55)
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.house_rounded,
                        size: 110, color: Color(0xFFFFE0A4)),
                  ),
                ),
              ),
            ),
            // Top right: the sky is palest there, so the pill stays legible
            // without covering the peak or the house.
            if (today != null)
              Positioned(top: 14, right: 14, child: _DatePill(date: today)),
          ],
        ),
      ),
    );
  }
}

/// Today in Bikram Sambat, which is the calendar the date is actually read in
/// here. The Gregorian date is left to the phone's own status bar.
class _DatePill extends StatelessWidget {
  const _DatePill({required this.date});

  final NepaliDate date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 7, 14, 7),
      decoration: BoxDecoration(
        // Translucent rather than solid: the sky still shows through, so the
        // pill sits on the photo instead of punching a hole in it.
        color: AppColors.navy.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date.formatted,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              Text(
                date.weekdayName,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid();

  @override
  Widget build(BuildContext context) {
    // One wide card per row rather than a two-column grid: the artwork is
    // 2.7:1 and squaring it into a grid cell would crop away most of what it
    // is a picture of.
    return Column(
      children: [
        for (final service in _services)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AspectRatio(
              aspectRatio: 2.65,
              child: _ServiceCard(service: service),
            ),
          ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final _Service service;

  @override
  Widget build(BuildContext context) {
    final active = service.isActive;

    return Material(
      color: active ? service.tileColor : const Color(0xFFF1F4F8),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (active) {
            service.open!(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${service.title} is coming soon')),
            );
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              service.art,
              fit: BoxFit.cover,
              // Dimmed rather than hidden on what is not built yet, so the
              // range on offer stays legible while it is clear what can be
              // used today.
              color: active ? null : const Color(0xFFF1F4F8),
              colorBlendMode: active ? null : BlendMode.saturation,
              errorBuilder: (_, __, ___) => _ArtFallback(service: service),
            ),
            // The words need to hold their own over a photograph, so the end
            // they sit on is washed towards the card colour.
            Align(
              alignment: service.textOnRight
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.62,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: service.textOnRight
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      end: service.textOnRight
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.92),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: service.textOnRight
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    textAlign:
                        service.textOnRight ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: active ? AppColors.navy : const Color(0xFF6B7889),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    service.subtitle,
                    textAlign:
                        service.textOnRight ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (!active) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Coming soon',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7889),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drawn if a banner ever fails to load, so a tile is still a tile.
class _ArtFallback extends StatelessWidget {
  const _ArtFallback({required this.service});

  final _Service service;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: service.tileColor,
      alignment: Alignment.center,
      child: Icon(service.icon, size: 40, color: service.color),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.navy,
        title: const Text('Categories'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: const _ServiceGrid(),
      ),
    );
  }
}

/// Signed out this offers sign-in; signed in it opens the account screen.
///
/// Both of those pop themselves when they finish - AuthScreen on success,
/// AccountScreen on sign-out - so they are pushed from here rather than
/// embedded in the tab, where popping would tear down the whole app route.
class _AccountTab extends StatelessWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.navy,
        title: const Text('Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFE4F0FF),
                  child: Icon(
                    auth.isSignedIn ? Icons.person_rounded : Icons.person_outline_rounded,
                    size: 38,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.isSignedIn
                      ? (user?.fullName.isNotEmpty == true ? user!.fullName : user?.phone ?? '')
                      : 'Not signed in',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.isSignedIn
                      ? 'Your bookings are saved to this number.'
                      : 'Sign in to keep track of your bookings.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => auth.isSignedIn
                            ? AccountScreen(auth: auth)
                            : AuthScreen(auth: auth),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      auth.isSignedIn ? 'Account settings' : 'Sign in',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
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
