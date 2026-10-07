import 'package:flutter/material.dart';

import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';
import '../theme/app_colors.dart';
import 'booking_screen.dart';

class SubcategoryScreen extends StatefulWidget {
  const SubcategoryScreen({
    super.key,
    required this.title,
    required this.imagePathPrefix,
    required this.itemCount,
    required this.vertical,
    required this.categorySlug,
    this.itemLabels,
  });

  final String title;

  /// Base asset path for this category's images, e.g. 'assets/services/mason'.
  /// Images are expected at '$imagePathPrefix/1.png', '.../2.png', etc.
  final String imagePathPrefix;
  final int itemCount;

  /// Captions drawn under each tile, in the same order as the images.
  ///
  /// Most categories leave this null because their artwork has the name
  /// printed into it. Grocery's photos are plain product shots with no text,
  /// so those need a caption or the tile says nothing.
  final List<String>? itemLabels;

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

  /// Straight to booking - the customer books Pakka Homes and we assign
  /// someone. Picking an individual is deliberately not part of the flow.
  void _book(int index) {
    final remote = index < _remote.length ? _remote[index] : null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          title: remote?.name ?? widget.title,
          categorySlug: widget.categorySlug,
          subcategorySlug: remote?.slug,
          priceLabel: remote?.displayRate,
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
          final labels = widget.itemLabels;
          final label = (labels != null && index < labels.length) ? labels[index] : null;

          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Material(
              color: Colors.white,
              child: InkWell(
                onTap: () => _book(index),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(imagePath, fit: BoxFit.contain),
                      ),
                    ),
                    if (label != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(8, 0, 8, rate == null ? 10 : 2),
                        child: Text(
                          label,
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
