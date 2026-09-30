/// Mirrors catalog/serializers.py on the backend.

class RemoteCategory {
  const RemoteCategory({
    required this.id,
    required this.vertical,
    required this.name,
    required this.slug,
    required this.imageKey,
    required this.subcategoryCount,
    this.description = '',
    this.imageUrl,
    this.icon = '',
    this.subcategories = const [],
  });

  final int id;
  final String vertical;
  final String name;
  final String slug;

  /// Bundled asset folder this category maps to; empty when unset server-side.
  final String imageKey;
  final int subcategoryCount;
  final String description;
  final String? imageUrl;
  final String icon;

  /// Only populated by the detail and `tree` endpoints.
  final List<RemoteSubcategory> subcategories;

  factory RemoteCategory.fromJson(Map<String, dynamic> json) => RemoteCategory(
        id: json['id'] as int,
        vertical: json['vertical'] as String? ?? '',
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        imageKey: json['image_key'] as String? ?? '',
        subcategoryCount: json['subcategory_count'] as int? ?? 0,
        description: json['description'] as String? ?? '',
        imageUrl: json['image'] as String?,
        icon: json['icon'] as String? ?? '',
        subcategories: (json['subcategories'] as List<dynamic>? ?? [])
            .map((e) => RemoteSubcategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RemoteSubcategory {
  const RemoteSubcategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.displayRate,
    this.description = '',
    this.rate,
    this.rateUnit = 'quote',
    this.imageUrl,
    this.isPopular = false,
  });

  final int id;
  final String name;
  final String slug;

  /// Server-formatted price, e.g. "NPR 2,500 per visit" or "On request".
  final String displayRate;
  final String description;

  /// Null when the price is quoted on request.
  final double? rate;
  final String rateUnit;
  final String? imageUrl;
  final bool isPopular;

  bool get isQuoteOnly => rate == null;

  factory RemoteSubcategory.fromJson(Map<String, dynamic> json) => RemoteSubcategory(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        displayRate: json['display_rate'] as String? ?? 'On request',
        description: json['description'] as String? ?? '',
        rate: _toDouble(json['rate']),
        rateUnit: json['rate_unit'] as String? ?? 'quote',
        imageUrl: json['image'] as String?,
        isPopular: json['is_popular'] as bool? ?? false,
      );

  // DRF renders DecimalField as a string by default.
  static double? _toDouble(dynamic value) => switch (value) {
        null => null,
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
}
