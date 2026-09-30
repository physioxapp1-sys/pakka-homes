import 'api_client.dart';
import 'provider_models.dart';

/// Reads the provider directory from the backend.
class ProviderRepository {
  ProviderRepository({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  Future<List<ServiceProvider>> forCategory({
    required String categorySlug,
    required String vertical,
    bool availableOnly = false,
  }) async {
    final body = await _api.get('/providers/', query: {
      'category': categorySlug,
      'vertical': vertical,
      if (availableOnly) 'available': 'true',
    });

    final rows = body is List
        ? body
        : (body as Map<String, dynamic>)['results'] as List<dynamic>? ?? [];
    return rows
        .map((e) => ServiceProvider.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() => _api.close();
}
