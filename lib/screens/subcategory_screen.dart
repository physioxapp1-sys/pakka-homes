import 'package:flutter/material.dart';

import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';
import '../theme/app_colors.dart';
import 'providers_screen.dart';

class SubcategoryScreen extends StatefulWidget {
  const SubcategoryScreen({
    super.key,
    required this.title,
    required this.imagePathPrefix,
    required this.itemCount,
    required this.vertical,
    required this.categorySlug,
  });

  final String title;

  /// Base asset path for this category's images, e.g. 'assets/services/mason'.
  /// Images are expected at '$imagePathPrefix/1.png', '.../2.png', etc.
  final String imagePathPrefix;
  final int itemCount;

  /// Backend vertical ('service' / 'shop') and category slug used to look up
  /// live rates. The bundled images render regardless.
  final String vertical;
  final String categorySlug;

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  final _repository = CatalogRepository();

  /// Server rows, positionally aligned with the bundled images. Empty until
  /// (and unless) the catalog has been imported on the backend.
  List<RemoteSubcategory> _remote = const [];

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    try {
      final rows = await _repository.subcategories(
        vertical: widget.vertical,
        categorySlug: widget.categorySlug,
      );
      if (mounted) setState(() => _remote = rows);
    } catch (_) {
      // Offline or catalog not imported yet - the bundled grid still works.
    }
  }

  void _openProviders(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProvidersScreen(
          categoryName: widget.title,
          categorySlug: widget.categorySlug,
          vertical: widget.vertical,
          subcategoryName: index < _remote.length ? _remote[index].name : null,
          subcategorySlug: index < _remote.length ? _remote[index].slug : null,
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
        title: Text(widget.title),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.95,
        ),
        itemCount: widget.itemCount,
        itemBuilder: (context, index) {
          final imagePath = '${widget.imagePathPrefix}/${index + 1}.png';
          final rate = index < _remote.length ? _remote[index].displayRate : null;

          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Material(
              color: Colors.white,
              child: InkWell(
                onTap: () => _openProviders(index),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(imagePath, fit: BoxFit.contain),
                      ),
                    ),
                    if (rate != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: Text(
                          rate,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
