import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';
import '../theme/app_colors.dart';

/// A grouping of categories - Maintenance fanning out to the trades under it.
///
/// The trades it lists are a product decision and stay in the app; their
/// names and pictures come from the API, so a photo uploaded in admin shows up
/// without a release. Until one is, a row draws its fallback icon.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.items,
    required this.slugs,
    this.itemRoutes,
  });

  final String title;
  final String subtitle;

  /// Drawn on a row whose category has no picture yet.
  final IconData icon;
  final Color iconColor;

  /// Fallback labels, in the same order as [slugs]. Used until the API
  /// answers, and if it never does.
  final List<String> items;

  /// The backend slugs for those rows, which is what the pictures arrive by.
  final List<String> slugs;

  /// Per-item destinations, keyed by the item's label. Items with no matching
  /// entry show a "coming soon" message instead of navigating.
  final Map<String, WidgetBuilder>? itemRoutes;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _repository = CatalogRepository();

  /// Keyed by slug. Empty until the catalog answers, which is why the labels
  /// are passed in rather than waited for.
  Map<String, RemoteCategory> _remote = const {};

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
    try {
      final rows = await _repository.categories(CatalogRepository.serviceVertical);
      if (mounted) {
        setState(() => _remote = {for (final c in rows) c.slug: c});
      }
    } on ApiException {
      // Offline, or the catalog is not imported: the rows below still list
      // and still open. They just carry an icon instead of a photograph.
    }
  }

  void _open(String label) {
    final route = widget.itemRoutes?[label];
    if (route != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: route));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coming soon')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(widget.title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.green,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final slug =
                      index < widget.slugs.length ? widget.slugs[index] : null;
                  final remote = slug == null ? null : _remote[slug];
                  // The label is the app's until the catalog gives its own.
                  final label = widget.items[index];
                  return _CategoryRow(
                    label: remote?.name ?? label,
                    count: remote?.subcategoryCount ?? 0,
                    imageUrl: remote?.imageUrl,
                    icon: widget.icon,
                    iconColor: widget.iconColor,
                    onTap: () => _open(label),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.count,
    required this.imageUrl,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final int count;
  final String? imageUrl;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                // 1.25:1, which is roughly the shape the artwork is drawn at,
                // so cover trims a sliver rather than cutting the subject out.
                child: SizedBox(
                  width: 86,
                  height: 68,
                  child: _Art(url: imageUrl, icon: icon, iconColor: iconColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (count > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        '$count service${count == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({required this.url, required this.icon, required this.iconColor});

  final String? url;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: iconColor.withValues(alpha: 0.10),
      child: Center(child: Icon(icon, color: iconColor, size: 26)),
    );
    if (url == null || url!.isEmpty) return fallback;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : Container(color: const Color(0xFFF1F6FA)),
    );
  }
}
