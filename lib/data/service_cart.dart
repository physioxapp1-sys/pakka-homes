import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_models.dart';

/// One service someone means to book.
///
/// The category travels with it because subcategory slugs are unique per
/// category, not globally - 'deep-cleaning' exists under both Maid and
/// Cleaning and they are not the same job.
class ServiceLine {
  const ServiceLine({required this.categorySlug, required this.service});

  final String categorySlug;
  final RemoteSubcategory service;

  String get key => '$categorySlug/${service.slug}';

  /// Enough to redraw the cart with no network. Rates are refreshed whenever
  /// the listing is opened again; a cart that survives a restart is worth
  /// more than one guaranteed to be current.
  Map<String, dynamic> toJson() => {
        'category': categorySlug,
        'service': {
          'id': service.id,
          'name': service.name,
          'slug': service.slug,
          'display_rate': service.displayRate,
          'description': service.description,
          'rate': service.rate,
          'rate_unit': service.rateUnit,
          'image': service.imageUrl,
          'is_popular': service.isPopular,
        },
      };

  factory ServiceLine.fromJson(Map<String, dynamic> json) => ServiceLine(
        categorySlug: json['category'] as String? ?? '',
        service:
            RemoteSubcategory.fromJson(json['service'] as Map<String, dynamic>),
      );
}

/// The services someone has picked but not yet booked.
///
/// Separate from the grocery [Cart] on purpose. A basket of tomatoes becomes
/// an order with a delivery fee and a slot; a list of services becomes one
/// booking with an address, how often help is wanted and which times suit.
/// Sharing one cart would mean one checkout that could not ask either set of
/// questions properly.
///
/// No quantities: two of a cooking service is not a thing. A service is in or
/// it is out.
class ServiceCart extends ChangeNotifier {
  static const _storageKey = 'service_cart_v1';

  final Map<String, ServiceLine> _lines = {};

  List<ServiceLine> get lines => _lines.values.toList();
  bool get isEmpty => _lines.isEmpty;
  int get count => _lines.length;

  bool contains(String categorySlug, String slug) =>
      _lines.containsKey('$categorySlug/$slug');

  List<String> slugs() => [for (final l in _lines.values) l.service.slug];
  List<String> names() => [for (final l in _lines.values) l.service.name];

  /// The category these services belong to, when they all share one - which
  /// is what a booking needs to disambiguate the slugs it is sent.
  String? get commonCategory {
    if (_lines.isEmpty) return null;
    final first = _lines.values.first.categorySlug;
    return _lines.values.every((l) => l.categorySlug == first) ? first : null;
  }

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      for (final entry in jsonDecode(raw) as List<dynamic>) {
        final line = ServiceLine.fromJson(entry as Map<String, dynamic>);
        _lines[line.key] = line;
      }
      notifyListeners();
    } catch (_) {
      // A cart that cannot be read is not worth failing startup over.
    }
  }

  void add(RemoteSubcategory service, {required String categorySlug}) {
    final line = ServiceLine(categorySlug: categorySlug, service: service);
    _lines[line.key] = line;
    _save();
  }

  void remove(String categorySlug, String slug) {
    _lines.remove('$categorySlug/$slug');
    _save();
  }

  void toggle(RemoteSubcategory service, {required String categorySlug}) {
    if (contains(categorySlug, service.slug)) {
      remove(categorySlug, service.slug);
    } else {
      add(service, categorySlug: categorySlug);
    }
  }

  void clear() {
    _lines.clear();
    _save();
  }

  void _save() {
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(
        _storageKey,
        jsonEncode(_lines.values.map((l) => l.toJson()).toList()),
      );
    }).catchError((_) => false);
  }
}

/// Puts the service cart in reach of any screen, and rebuilds dependents when
/// it changes.
class ServiceCartScope extends InheritedNotifier<ServiceCart> {
  const ServiceCartScope({
    super.key,
    required ServiceCart cart,
    required super.child,
  }) : super(notifier: cart);

  static ServiceCart of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ServiceCartScope>();
    assert(scope != null, 'No ServiceCartScope above this widget');
    return scope!.notifier!;
  }
}
