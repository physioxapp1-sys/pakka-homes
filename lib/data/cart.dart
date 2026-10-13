import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'product_models.dart';

class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get total => product.price * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);

  /// Enough of the product to redraw the cart offline. Prices are refreshed
  /// from the server when the listing is next opened; a cart that survives a
  /// restart is worth more than one that is guaranteed current.
  Map<String, dynamic> toJson() => {
        'quantity': quantity,
        'product': {
          'id': product.id,
          'name': product.name,
          'slug': product.slug,
          'display_name': product.displayName,
          'unit': product.unit,
          'price': product.price,
          'mrp': product.mrp,
          'discount_percent': product.discountPercent,
          'image': product.imageUrl,
          'subcategory_slug': product.subcategorySlug,
        },
      };

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
        quantity: json['quantity'] as int? ?? 1,
      );
}

/// The shopping cart, held on the device.
///
/// Deliberately local: there is no order endpoint yet, and a cart that lives
/// only in memory loses everything when the app is backgrounded.
class Cart extends ChangeNotifier {
  static const _storageKey = 'cart_lines_v1';
  static const freeDeliveryAbove = 1000.0;
  static const deliveryFee = 40.0;

  final Map<int, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();
  bool get isEmpty => _lines.isEmpty;
  int get distinctItems => _lines.length;
  int get totalQuantity => _lines.values.fold(0, (sum, l) => sum + l.quantity);

  double get itemTotal => _lines.values.fold(0.0, (sum, l) => sum + l.total);
  double get delivery =>
      isEmpty || itemTotal >= freeDeliveryAbove ? 0 : deliveryFee;
  double get total => itemTotal + delivery;

  int quantityOf(Product product) => _lines[product.id]?.quantity ?? 0;

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      for (final entry in jsonDecode(raw) as List<dynamic>) {
        final line = CartLine.fromJson(entry as Map<String, dynamic>);
        _lines[line.product.id] = line;
      }
      notifyListeners();
    } catch (_) {
      // A cart that cannot be read is not worth failing startup over.
    }
  }

  void add(Product product, {int quantity = 1}) {
    final existing = _lines[product.id];
    _lines[product.id] = existing == null
        ? CartLine(product: product, quantity: quantity)
        : existing.copyWith(quantity: existing.quantity + quantity);
    _save();
  }

  void setQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      _lines.remove(product.id);
    } else {
      final existing = _lines[product.id];
      _lines[product.id] = existing == null
          ? CartLine(product: product, quantity: quantity)
          : existing.copyWith(quantity: quantity);
    }
    _save();
  }

  void remove(Product product) {
    _lines.remove(product.id);
    _save();
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

/// Puts the cart in reach of any screen without threading it through every
/// constructor, and rebuilds dependents when it changes.
class CartScope extends InheritedNotifier<Cart> {
  const CartScope({super.key, required Cart cart, required super.child})
      : super(notifier: cart);

  static Cart of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CartScope>();
    assert(scope != null, 'No CartScope above this widget');
    return scope!.notifier!;
  }
}
