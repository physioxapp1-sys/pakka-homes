import 'api_client.dart';
import 'product_models.dart';

/// A page of an aisle, and whether there is another behind it.
class ProductPage {
  const ProductPage({
    required this.products,
    required this.hasMore,
    this.total,
  });

  final List<Product> products;
  final bool hasMore;

  /// How many the whole aisle holds, when the server says.
  final int? total;
}

class ProductRepository {
  ProductRepository({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  /// One page of an aisle.
  ///
  /// The screen asks for ten at a time and fetches the next ten as you reach
  /// the bottom, so opening an aisle does not pull every product and every
  /// photo up front.
  ///
  /// [seed] shuffles the aisle. It is chosen once when the screen opens and
  /// sent with every page: the server orders deterministically from it, so
  /// page 2 continues page 1 instead of re-rolling and repeating products.
  Future<ProductPage> page({
    required String subcategorySlug,
    required int pageNumber,
    int pageSize = 10,
    int? seed,
    String? collectionSlug,
    String? search,
  }) async {
    final body = await _api.get('/products/', query: {
      'subcategory': subcategorySlug,
      'page_size': '$pageSize',
      if (pageNumber > 1) 'page': '$pageNumber',
      if (seed != null) 'seed': '$seed',
      if (collectionSlug != null) 'collection': collectionSlug,
      if (search != null && search.isNotEmpty) 'search': search,
    });

    // An unpaginated list means the server gave everything it had.
    if (body is List) {
      return ProductPage(
        products: body
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: false,
      );
    }
    final map = body as Map<String, dynamic>;
    return ProductPage(
      products: (map['results'] as List<dynamic>? ?? [])
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: map['next'] != null,
      total: map['count'] as int?,
    );
  }

  /// Every product in an aisle, following DRF's page links. Kept for callers
  /// that genuinely need the lot; the listing screen pages instead.
  Future<List<Product>> list({
    required String subcategorySlug,
    String? collectionSlug,
    String? search,
  }) async {
    final rows = await _collect('/products/', {
      'subcategory': subcategorySlug,
      if (collectionSlug != null) 'collection': collectionSlug,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return rows.map(Product.fromJson).toList();
  }

  Future<List<ProductCollection>> collections(String subcategorySlug) async {
    final body = await _api.get('/products/collections/', query: {
      'subcategory': subcategorySlug,
    });
    final rows = body is List ? body : const [];
    return rows
        .map((e) => ProductCollection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() => _api.close();

  /// Follows DRF's page links, so a long aisle is not silently truncated.
  Future<List<Map<String, dynamic>>> _collect(
    String path,
    Map<String, String> query,
  ) async {
    final collected = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final body = await _api.get(path, query: {
        ...query,
        if (page > 1) 'page': '$page',
      });
      if (body is List) {
        collected.addAll(body.cast<Map<String, dynamic>>());
        return collected;
      }
      final map = body as Map<String, dynamic>;
      collected.addAll((map['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
      if (map['next'] == null) return collected;
      page++;
    }
  }
}
