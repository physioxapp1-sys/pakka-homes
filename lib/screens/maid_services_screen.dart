import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';
import '../theme/app_colors.dart';
import 'booking_screen.dart';

/// Picking what the help is for.
///
/// Unlike every other category, this one takes more than one: a household
/// hires a person, not a task, and that person cooks and does the dishes and
/// the laundry. So the tiles tick rather than open, and the booking that
/// follows names all of them.
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
  final _picked = <String>[];

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

  void _toggle(RemoteSubcategory service) {
    setState(() {
      // A list, not a set: the order they were picked in is the order they
      // are sent, and the first becomes the headline service on the booking.
      if (!_picked.remove(service.slug)) _picked.add(service.slug);
    });
  }

  void _continue() {
    final bySlug = {for (final s in _services ?? const []) s.slug: s};
    final chosen = [
      for (final slug in _picked)
        if (bySlug.containsKey(slug)) bySlug[slug]!,
    ];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          title: chosen.length == 1 ? chosen.first.name : 'Maid service',
          categorySlug: MaidServicesScreen.categorySlug,
          subcategorySlugs: [for (final s in chosen) s.slug],
          serviceNames: [for (final s in chosen) s.name],
          asksEngagement: true,
          priceLabel: chosen.length == 1 ? chosen.first.displayRate : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Maid service'),
      ),
      body: _body(),
      bottomNavigationBar: _picked.isEmpty ? null : _ContinueBar(
        count: _picked.length,
        onPressed: _continue,
      ),
    );
  }

  Widget _body() {
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
                  picked: _picked.contains(services[i].slug),
                  onTap: () => _toggle(services[i]),
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
          Text('Pick as many as you like - one person can cover several.',
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
  });

  final RemoteSubcategory service;
  final bool picked;
  final VoidCallback onTap;

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
                      top: 8,
                      right: 8,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: picked ? AppColors.green : Colors.white,
                          border: Border.all(
                            color: picked ? AppColors.green : AppColors.cardBorder,
                            width: 1.5,
                          ),
                        ),
                        child: picked
                            ? const Icon(Icons.check, size: 15, color: Colors.white)
                            : null,
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
                Text('$count selected',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Row(
                  children: [
                    Text('Continue',
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
