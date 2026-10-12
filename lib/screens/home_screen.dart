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

/// What the four service tiles offer.
///
/// Grocery and Maintenance are live. Rent and Maid are deliberately inactive:
/// they are drawn dimmed and say so, rather than looking tappable and then
/// doing nothing.
class _Service {
  const _Service({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tileColor,
    this.open,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color tileColor;

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
        imagePathPrefix: category.assetPathPrefix('services'),
        itemCount: category.imageCount,
        vertical: CatalogRepository.serviceVertical,
        categorySlug: category.slug,
        itemLabels: category.itemLabels,
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

void _openMaintenance(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CategoryScreen(
        title: 'Maintenance',
        subtitle: 'Repairs and upkeep for your home',
        icon: Icons.build_rounded,
        iconColor: AppColors.blue,
        items: [for (final s in _maintenanceSlugs) _category(s).name],
        itemRoutes: {
          for (final s in _maintenanceSlugs)
            _category(s).name: (_) => SubcategoryScreen(
                  title: _category(s).name,
                  imagePathPrefix: _category(s).assetPathPrefix('services'),
                  itemCount: _category(s).imageCount,
                  vertical: CatalogRepository.serviceVertical,
                  categorySlug: _category(s).slug,
                  itemLabels: _category(s).itemLabels,
                ),
        },
      ),
    ),
  );
}

const _services = <_Service>[
  _Service(
    title: 'Grocery',
    subtitle: 'Fresh groceries &\ndaily essentials',
    icon: Icons.shopping_basket_rounded,
    color: Color(0xFF138653),
    tileColor: AppColors.tileGreen,
    open: _openGrocery,
  ),
  _Service(
    title: 'Rent',
    subtitle: 'Homes, rooms &\nproperties for rent',
    icon: Icons.key_rounded,
    color: AppColors.orange,
    tileColor: AppColors.tileOrange,
  ),
  _Service(
    title: 'Maid',
    subtitle: 'Trusted help for\nyour home',
    icon: Icons.cleaning_services_rounded,
    color: AppColors.purple,
    tileColor: AppColors.tilePurple,
  ),
  _Service(
    title: 'Maintenance',
    subtitle: 'Plumbing, electrical,\nrepair & more',
    icon: Icons.build_rounded,
    color: AppColors.blue,
    tileColor: AppColors.tileBlue,
    open: _openMaintenance,
  ),
];

void _openGrocery(BuildContext context) => _openCategory(context, 'grocery');

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
            const MyBookingsScreen(),
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
          const SizedBox(height: 25),
          const _SearchBar(),
          const SizedBox(height: 25),
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
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Pakka ',
                      style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: 'Homes',
                      style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                maxLines: 1,
                style: TextStyle(fontSize: 23),
              ),
              SizedBox(height: 3),
              Text(
                'All in One Home Solution',
                style: TextStyle(fontSize: 12, color: Color(0xFF525C69)),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  auth.isSignedIn ? AccountScreen(auth: auth) : AuthScreen(auth: auth),
            ),
          ),
          borderRadius: BorderRadius.circular(30),
          child: CircleAvatar(
            radius: 23,
            backgroundColor: const Color(0xFFE4F0FF),
            child: Icon(
              auth.isSignedIn ? Icons.person_rounded : Icons.person_outline_rounded,
              color: AppColors.navy,
              size: 29,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    void soon(String what) => ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$what is coming soon')));

    return Container(
      height: 62,
      padding: const EdgeInsets.only(left: 15, right: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 31, color: AppColors.navy),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              textInputAction: TextInputAction.search,
              // The backend supports /subcategories/?search=, but there is no
              // results screen yet, so this says so rather than pretending.
              onSubmitted: (_) => soon('Search'),
              decoration: const InputDecoration(
                hintText: 'Search services, products...',
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF7D899B)),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          Material(
            color: const Color(0xFFE4F2FF),
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => soon('Scan'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded, color: AppColors.blue, size: 21),
                    Text('Scan', style: TextStyle(fontSize: 11, color: AppColors.blue)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(27),
      // The mock's 205pt works now. The banner is 1.63:1 against the slot's
      // ~1.71:1, so cover trims a sliver of height and nothing else - the
      // previous photo was 2.83:1 and lost 39% of its width here.
      child: SizedBox(
        width: double.infinity,
        height: 205,
        child: Image.asset(
          'assets/home/hero.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFBFE3F4), Color(0xFF8DC5A1), Color(0xFF447D55)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.house_rounded, size: 110, color: Color(0xFFFFE0A4)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final service in _services)
              SizedBox(
                width: cardWidth,
                height: cardWidth * 0.92,
                child: _ServiceCard(service: service),
              ),
          ],
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final _Service service;

  @override
  Widget build(BuildContext context) {
    final active = service.isActive;
    // Greyed rather than hidden, so the range on offer is still legible while
    // it is clear which parts can be used today.
    final tile = active ? service.tileColor : const Color(0xFFF1F4F8);
    final accent = active ? service.color : const Color(0xFF93A0B0);

    return Material(
      color: tile,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          if (active) {
            service.open!(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${service.title} is coming soon')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 57,
                    height: 57,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(service.icon, size: 31, color: accent),
                  ),
                  const Spacer(),
                  if (!active)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Coming soon',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7A879A),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (active)
                    Icon(Icons.chevron_right_rounded, color: accent, size: 25),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                service.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Other tabs
// ---------------------------------------------------------------------------

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
