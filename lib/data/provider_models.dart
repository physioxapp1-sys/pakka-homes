/// Mirrors providers/serializers.py on the backend.

class ServiceProvider {
  const ServiceProvider({
    required this.id,
    required this.name,
    required this.slug,
    required this.trade,
    required this.tradeDisplay,
    required this.displayRate,
    this.phone = '',
    this.photoUrl,
    this.serviceArea = '',
    this.about = '',
    this.experienceYears = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.rate,
    this.rateUnit = 'quote',
    this.isAvailable = false,
    this.isVerified = false,
    this.categorySlugs = const [],
  });

  final int id;
  final String name;
  final String slug;
  final String trade;
  final String tradeDisplay;

  /// Server-formatted call-out charge, e.g. "NPR 600 per visit" / "On request".
  final String displayRate;
  final String phone;
  final String? photoUrl;
  final String serviceArea;
  final String about;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final double? rate;
  final String rateUnit;
  final bool isAvailable;
  final bool isVerified;
  final List<String> categorySlugs;

  bool get isQuoteOnly => rate == null;

  factory ServiceProvider.fromJson(Map<String, dynamic> json) => ServiceProvider(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        trade: json['trade'] as String? ?? '',
        tradeDisplay: json['trade_display'] as String? ?? '',
        displayRate: json['display_rate'] as String? ?? 'On request',
        phone: json['phone'] as String? ?? '',
        photoUrl: json['photo'] as String?,
        serviceArea: json['service_area'] as String? ?? '',
        about: json['about'] as String? ?? '',
        experienceYears: json['experience_years'] as int? ?? 0,
        rating: _toDouble(json['rating']) ?? 0,
        reviewCount: json['review_count'] as int? ?? 0,
        rate: _toDouble(json['rate']),
        rateUnit: json['rate_unit'] as String? ?? 'quote',
        isAvailable: json['is_available'] as bool? ?? false,
        isVerified: json['is_verified'] as bool? ?? false,
        categorySlugs: (json['category_slugs'] as List<dynamic>? ?? [])
            .map((e) => '$e')
            .toList(),
      );

  // DRF renders DecimalField as a string, so rating arrives as "4.8".
  static double? _toDouble(dynamic value) => switch (value) {
        null => null,
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
}
