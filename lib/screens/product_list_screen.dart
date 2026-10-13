import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/cart.dart';
import '../data/product_models.dart';
import '../data/product_repository.dart';
import '../theme/app_colors.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

/// One grocery aisle: search, filter chips, and a row per product.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({
    super.key,
    required this.title,
    required this.subcategorySlug,
  });

  final String title;
  final String subcategorySlug;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _repository = ProductRepository();
  final _searchController = TextEditingController();

  List<Product>? _products;
  List<ProductCollection> _collections = const [];
  String? _activeCollection;
  String _search = '';
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCollections();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    try {
      final rows = await _repository.collections(widget.subcategorySlug);
      if (mounted) setState(() => _collections = rows);
    } on ApiException {
      // Chips are an extra; the list still works without them.
    }
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final rows = await _repository.list(
        subcategorySlug: widget.subcategorySlug,
        collectionSlug: _activeCollection,
        search: _search,
      );
      if (mounted) setState(() => _products = rows);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _products = const [];
          _error = e.message;
        });
      }
    }
  }

  /// Typing fires a request per keystroke otherwise, and the search runs
  /// server-side.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _search = value.trim());
      _load();
    });
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.navy,
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
        actions: [_CartButton(cart: cart)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search ${widget.title.toLowerCase()}',
                hintStyle:
                    const TextStyle(fontSize: 14, color: Color(0xFF7D899B)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF7D899B)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
          ),
          if (_collections.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _Chip(
                    label: 'All',
                    selected: _activeCollection == null,
                    onTap: () {
                      setState(() => _activeCollection = null);
                      _load();
                    },
                  ),
                  for (final collection in _collections)
                    _Chip(
                      label: collection.name,
                      selected: _activeCollection == collection.slug,
                      onTap: () {
                        setState(() => _activeCollection = collection.slug);
                        _load();
                      },
                    ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Expanded(child: _body(cart)),
        ],
      ),
      bottomNavigationBar: cart.isEmpty ? null : _CartBar(cart: cart),
    );
  }

  Widget _body(Cart cart) {
    final products = _products;
    if (products == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 70),
          children: [
            const Icon(Icons.shopping_basket_outlined,
                size: 46, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              _error ??
                  (_search.isEmpty
                      ? 'Nothing stocked here yet.'
                      : 'Nothing matches "$_search".'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ProductRow(
          product: products[i],
          cart: cart,
          onTap: () => _openProduct(products[i]),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        backgroundColor: Colors.white,
        selectedColor: AppColors.green,
        side: const BorderSide(color: AppColors.cardBorder),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.navy,
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.cart, required this.onTap});

  final Product product;
  final Cart cart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quantity = cart.quantityOf(product);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              ProductImage(product: product, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formatNpr(product.price),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.green,
                          ),
                        ),
                        if (product.isDiscounted) ...[
                          const SizedBox(width: 8),
                          _OffBadge(percent: product.discountPercent!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFF5A623)),
                        const SizedBox(width: 2),
                        Text(
                          '${product.rating}  (${_compact(product.reviewCount)})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _AddControl(product: product, cart: cart, quantity: quantity),
            ],
          ),
        ),
      ),
    );
  }

  static String _compact(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k' : '$n';
}

/// A plus that becomes a stepper once the item is in the cart, so adding a
/// second one does not mean opening the cart.
class _AddControl extends StatelessWidget {
  const _AddControl({
    required this.product,
    required this.cart,
    required this.quantity,
  });

  final Product product;
  final Cart cart;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    if (!product.inStock) {
      return const Text(
        'Out of\nstock',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
      );
    }
    if (quantity == 0) {
      return Material(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => cart.add(product),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
        ),
      );
    }
    return QuantityStepper(
      quantity: quantity,
      onChanged: (q) => cart.setQuantity(product, q),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.compact = true,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.green),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
            onTap: () => onChanged(quantity - 1),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 12),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: () => onChanged(quantity + 1)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: AppColors.green),
      ),
    );
  }
}

class _OffBadge extends StatelessWidget {
  const _OffBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE23744),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$percent% OFF',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Server image when there is one, otherwise a tinted basket - products are
/// entered in the admin and a photo may not be uploaded yet.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.product,
    required this.size,
    this.fit = BoxFit.cover,
  });

  final Product product;
  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.tileGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.shopping_basket_rounded,
          size: size * 0.45, color: AppColors.green),
    );

    if (product.imageUrl == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        product.imageUrl!,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
        if (!cart.isEmpty)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFE23744),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${cart.totalQuantity}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Sits over the list once there is something in the cart, so the way to
/// checkout is always in reach.
class _CartBar extends StatelessWidget {
  const _CartBar({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${cart.totalQuantity} item${cart.totalQuantity == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Text(
                      formatNpr(cart.itemTotal),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
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
