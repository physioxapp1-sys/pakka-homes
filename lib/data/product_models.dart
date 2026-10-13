/// Mirrors products/serializers.py on the backend.

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.displayName,
    required this.price,
    this.unit = '',
    this.mrp,
    this.discountPercent,
    this.imageUrl,
    this.description = '',
    this.badge = '',
    this.origin = '',
    this.shelfLife = '',
    this.returnPolicy = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.inStock = true,
    this.subcategorySlug = '',
    this.collectionSlugs = const [],
  });

  final int id;
  final String name;
  final String slug;

  /// 'Tomato (1 kg)' - name and pack size, as the listing shows it.
  final String displayName;
  final String unit;
  final double price;

  /// Original price, struck through. Null when not discounted.
  final double? mrp;

  /// Whole percent off, derived server-side. Null when there is none.
  final int? discountPercent;
  final String? imageUrl;
  final String description;
  final String badge;
  final String origin;
  final String shelfLife;
  final String returnPolicy;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final String subcategorySlug;
  final List<String> collectionSlugs;

  bool get isDiscounted => discountPercent != null;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        displayName: json['display_name'] as String? ?? json['name'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        price: _toDouble(json['price']) ?? 0,
        mrp: _toDouble(json['mrp']),
        discountPercent: json['discount_percent'] as int?,
        imageUrl: json['image'] as String?,
        description: json['description'] as String? ?? '',
        badge: json['badge'] as String? ?? '',
        origin: json['origin'] as String? ?? '',
        shelfLife: json['shelf_life'] as String? ?? '',
        returnPolicy: json['return_policy'] as String? ?? '',
        rating: _toDouble(json['rating']) ?? 0,
        reviewCount: json['review_count'] as int? ?? 0,
        inStock: json['in_stock'] as bool? ?? true,
        subcategorySlug: json['subcategory_slug'] as String? ?? '',
        collectionSlugs:
            (json['collection_slugs'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      );

  // DRF renders DecimalField as a string.
  static double? _toDouble(dynamic value) => switch (value) {
        null => null,
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
}

class ProductCollection {
  const ProductCollection({required this.name, required this.slug});

  final String name;
  final String slug;

  factory ProductCollection.fromJson(Map<String, dynamic> json) => ProductCollection(
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
      );
}

/// Formats an amount the way the designs do: NPR 60, never NPR 60.00.
String formatNpr(double amount) {
  final whole = amount.round();
  final digits = whole.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return 'NPR $buffer';
}
