import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/catalog_models.dart';
import '../data/catalog_repository.dart';
import '../widgets/remote_image.dart';
import '../theme/app_colors.dart';
import 'booking_screen.dart';
import 'product_list_screen.dart';

/// What sits under a category: the trades you can book, or the aisles you can
/// shop.
///
/// Everything here comes from the API - the tiles, their pictures, their names
/// and their rates, as one row each. It used to draw a fixed number of tiles
/// from images shipped in the app and then pair tile N with the Nth row from
/// the server. That pairing broke the moment anyone added or reordered a
/// subcategory in admin, and it had: grocery was showing Rice's rate under
/// Vegetables & Fruits. A row carries its own picture now, so there is nothing
/// left to line up.
class SubcategoryScreen extends StatefulWidget {
  const SubcategoryScreen({
    super.key,
    required this.title,
    required this.vertical,
    required this.categorySlug,
    this.sellsProducts = false,
  });

  final String title;

  /// Backend vertical ('service' / 'shop' / 'rental') and category slug.
  final String vertical;
  final String categorySlug;

  /// Grocery aisles hold products to buy, not services to book.
  final bool sellsProducts;

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  final _repository = CatalogRepository();

  List<RemoteSubcategory>? _rows;
  String? _error;

  /// Whether this category's pictures already carry the service name. Until
  /// the categories load it stays false, which only risks a caption that is
  /// briefly doubled rather than a tile with no name at all.
  bool _artworkHasLabel = false;

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
        vertical: widget.vertical,
        categorySlug: widget.categorySlug,
      );
      if (mounted) setState(() => _rows = rows);
      await _loadCategoryFlags();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _rows = const [];
          _error = e.message;
        });
      }
    }
  }

  /// The artwork for most service categories has the name printed into the
  /// picture, so the tile would otherwise say it twice.
  Future<void> _loadCategoryFlags() async {
    try {
      final categories = await _repository.categories(widget.vertical);
      final mine = categories.where((c) => c.slug == widget.categorySlug);
      if (mounted && mine.isNotEmpty) {
        setState(() => _artworkHasLabel = mine.first.artworkHasLabel);
      }
    } on ApiException {
      // Caption it, which is the safer of the two mistakes.
    }
  }

  /// Aisles open a product list; everything else is a service and goes to
  /// booking, where Pakka Homes assigns someone.
  void _open(RemoteSubcategory row) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => widget.sellsProducts
            ? ProductListScreen(title: row.name, subcategorySlug: row.slug)
            : BookingScreen(
                title: row.name,
                categorySlug: widget.categorySlug,
                subcategorySlug: row.slug,
                priceLabel: row.displayRate,
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
      body: _body(),
    );
  }

  Widget _body() {
    final rows = _rows;
    if (rows == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (rows.isEmpty) {
      return _Empty(message: _error, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.95,
        ),
        itemCount: rows.length,
        itemBuilder: (_, i) => _Tile(
          row: rows[i],
          showName: !_artworkHasLabel,
          onTap: () => _open(rows[i]),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.row,
    required this.showName,
    required this.onTap,
  });

  final RemoteSubcategory row;

  /// False where the picture already says the name.
  final bool showName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _TileImage(url: row.imageUrl),
                ),
              ),
              if (showName)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
                  child: Text(
                    row.name,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  row.displayRate,
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
  }
}

class _TileImage extends StatelessWidget {
  const _TileImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    // A row with no picture uploaded yet, and anything that fails to load,
    // land on the same placeholder rather than an empty box or a broken icon.
    final placeholder = Container(
      decoration: BoxDecoration(
        color: AppColors.tileGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.handyman_rounded, size: 34, color: AppColors.green),
      ),
    );

    return RemoteImage(url: url, fit: BoxFit.contain, fallback: placeholder);
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, required this.onRetry});

  /// Null means the request worked and the category genuinely has nothing in
  /// it - worth saying differently from a failed request.
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              message == null ? Icons.inbox_outlined : Icons.wifi_off_rounded,
              size: 46,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'Nothing listed here yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
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
}
