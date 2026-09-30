import 'api_client.dart';
import 'catalog_models.dart';

/// Reads the catalog from the Dhaubanjar Nirman Sewa backend.
///
/// Callers are expected to fall back to the bundled catalog when a request
/// fails or returns nothing — see lib/data/local_catalog.dart.
class CatalogRepository {
  CatalogRepository({ApiClient? client}) : _api = client ?? ApiClient();

  static const serviceVertical = 'service';
  static const shopVertical = 'shop';
  static const rentalVertical = 'rental';

  final ApiClient _api;

  Future<List<RemoteCategory>> categories(String vertical) async {
    final rows = await _collect('/categories/', {'vertical': vertical});
    return rows.map(RemoteCategory.fromJson).toList();
  }

  Future<List<RemoteSubcategory>> subcategories({
    required String vertical,
    String? categorySlug,
    bool popularOnly = false,
    String? search,
  }) async {
    final rows = await _collect('/subcategories/', {
      'vertical': vertical,
      if (categorySlug != null) 'category': categorySlug,
      if (popularOnly) 'popular': 'true',
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return rows.map(RemoteSubcategory.fromJson).toList();
  }

  /// Whole vertical in one round trip, categories with subcategories inlined.
  Future<List<RemoteCategory>> tree(String vertical) async {
    final body = await _api.get('/categories/tree/', query: {'vertical': vertical});
    final categories = (body as Map<String, dynamic>)['categories'] as List<dynamic>? ?? [];
    return categories
        .map((e) => RemoteCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() => _api.close();

  /// Walks DRF's page links so a category list longer than PAGE_SIZE is not
  /// silently truncated.
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
      collected.addAll(
        (map['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );
      if (map['next'] == null) return collected;
      page++;
    }
  }
}
