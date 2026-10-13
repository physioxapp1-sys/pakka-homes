import 'api_client.dart';
import 'product_models.dart';

class ProductRepository {
  ProductRepository({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

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
