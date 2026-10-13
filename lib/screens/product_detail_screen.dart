import 'package:flutter/material.dart';

import '../data/cart.dart';
import '../data/product_models.dart';
import '../theme/app_colors.dart';
import 'cart_screen.dart';
import 'product_list_screen.dart' show ProductImage, QuantityStepper;

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = CartScope.of(context);
    final inCart = cart.quantityOf(product);

    // Product shots are square. A 1.5:1 banner either left bars down both
    // sides of a photo or cropped a third off it, so the banner is the shape
    // of the picture instead. Capped so a tablet does not open on a hero and
    // nothing else.
    final width = MediaQuery.sizeOf(context).width;
    final heroHeight = width > 420 ? 420.0 : width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: heroHeight,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.navy,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    // The backdrop a cut-out sits on. A photo covers it
                    // entirely; a PNG with transparency shows it around the
                    // product.
                    color: AppColors.tileGreen,
                    child: ProductImage(
                      product: product,
                      size: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: 0,
                    ),
                  ),
                  if (product.isDiscounted)
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE23744),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.discountPercent}% OFF',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.displayName,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatNpr(product.price),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green,
                        ),
                      ),
                      if (product.mrp != null) ...[
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            formatNpr(product.mrp!),
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 17, color: Color(0xFFF5A623)),
                      const SizedBox(width: 3),
                      Text(
                        '${product.rating} (${_compact(product.reviewCount)} reviews)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (product.badge.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tileGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.badge,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!product.inStock) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Out of stock',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emergencyRed,
                      ),
                    ),
                  ],
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const Text(
                      'Product Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  // Only the rows that have something to say.
                  for (final (label, value) in [
                    ('Origin', product.origin),
                    ('Shelf Life', product.shelfLife),
                    ('Return Policy', product.returnPolicy),
                  ])
                    if (value.isNotEmpty) _DetailRow(label: label, value: value),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: product.inStock
          ? _AddToCartBar(
              quantity: _quantity,
              inCart: inCart,
              onQuantity: (q) => setState(() => _quantity = q.clamp(1, 99)),
              onAdd: () {
                cart.add(product, quantity: _quantity);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.displayName} added to cart'),
                    action: SnackBarAction(
                      label: 'View cart',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      ),
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  static String _compact(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k' : '$n';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEFF3F7))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({
    required this.quantity,
    required this.inCart,
    required this.onQuantity,
    required this.onAdd,
  });

  final int quantity;
  final int inCart;
  final ValueChanged<int> onQuantity;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEFF3F7))),
        ),
        child: Row(
          children: [
            QuantityStepper(
              quantity: quantity,
              compact: false,
              onChanged: (q) => onQuantity(q),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    inCart > 0 ? 'Add more ($inCart in cart)' : 'Add to Cart',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
