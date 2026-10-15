import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';
import '../data/service_cart.dart';
import '../theme/app_colors.dart';
import 'service_cart_screen.dart';
import 'service_detail_screen.dart';

/// Picking what the help is for.
///
/// Unlike every other category, this one takes more than one: a household
/// hires a person, not a task, and that person cooks and does the dishes and
/// the laundry. So services collect in a cart the way groceries do - tap one
/// to read what it is and what it costs, or add it straight from the tile -
/// and the booking at the end names all of them.
class MaidServicesScreen extends StatefulWidget {
  const MaidServicesScreen({super.key});

  static const categorySlug = 'maid';

  @override
  State<MaidServicesScreen> createState() => _MaidServicesScreenState();
}

class _MaidServicesScreenState extends State<MaidServicesScreen> {
  final _repository = CatalogRepository();

  List<RemoteSubcategory>? _services;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final rows = await _repository.subcategories(
        vertical: CatalogRepository.serviceVertical,
        categorySlug: MaidServicesScreen.categorySlug,
      );
      if (mounted) setState(() => _services = rows);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _services = const [];
          _error = e.message;
        });
      }
    }
  }

  void _open(RemoteSubcategory service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          service: service,
          categorySlug: MaidServicesScreen.categorySlug,
          categoryName: 'Maid service',
        ),
      ),
    );
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ServiceCartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ServiceCartScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Maid service'),
        actions: [
          IconButton(
            onPressed: _openCart,
            icon: Badge(
              isLabelVisible: !cart.isEmpty,
              label: Text('${cart.count}'),
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
      ),
      body: _body(cart),
      bottomNavigationBar: cart.isEmpty
          ? null
          : _ContinueBar(count: cart.count, onPressed: _openCart),
    );
  }

  Widget _body(ServiceCart cart) {
    final services = _services;
    if (services == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_error == null ? Icons.inbox_outlined : Icons.wifi_off_rounded,
                  size: 46, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                _error ?? 'No maid services listed yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _load,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _Intro()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.92,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ServiceTile(
                  service: services[i],
                  picked: cart.contains(
                      MaidServicesScreen.categorySlug, services[i].slug),
                  onTap: () => _open(services[i]),
                  onAdd: () => cart.toggle(services[i],
                      categorySlug: MaidServicesScreen.categorySlug),
                ),
                childCount: services.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What do you need help with?',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy)),
          SizedBox(height: 4),
          Text('Tap one to read what it covers, or add it straight away.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.picked,
    required this.onTap,
    required this.onAdd,
  });

  final RemoteSubcategory service;
  final bool picked;

  /// Opens the service. Adding is the corner button, the way a grocery row
  /// opens the product and its plus button adds it.
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: picked ? AppColors.green : AppColors.cardBorder,
              width: picked ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(13)),
                        child: _Photo(url: service.imageUrl),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onAdd,
                          customBorder: const CircleBorder(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: picked ? AppColors.green : Colors.white,
                              border: Border.all(
                                color:
                                    picked ? AppColors.green : AppColors.cardBorder,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              picked ? Icons.check : Icons.add,
                              size: 17,
                              color: picked ? Colors.white : AppColors.green,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 9),
                child: Text(
                  service.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.tilePurple,
      child: const Center(
        child: Icon(Icons.cleaning_services_rounded,
            size: 30, color: AppColors.purple),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : Container(color: const Color(0xFFF1F6FA)),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$count in cart',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Row(
                  children: [
                    Text('View cart',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
