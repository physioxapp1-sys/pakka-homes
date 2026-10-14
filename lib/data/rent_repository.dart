import 'api_client.dart';
import 'rent_models.dart';

/// The Rent section's data.
///
/// Every call but [listed] needs a token: the server decides what to return
/// from who is asking, so there is nothing sensible to show without one.
class RentRepository {
  RentRepository({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  /// Which side of the section the customer is on, and their dashboard.
  Future<RentHome> home(String token) async {
    final body = await _api.get('/rent/', token: token);
    return RentHome.fromJson(body as Map<String, dynamic>);
  }

  Future<List<RentProperty>> myProperties(String token) async =>
      _properties(token: token);

  /// Places going spare. Open to anyone - looking for a flat is no reason to
  /// need an account.
  Future<List<RentProperty>> listed() async =>
      _properties(query: {'listed': 'true'});

  Future<List<RentPayment>> payments(String token, {bool asTenant = false}) async {
    final rows = await _collect(
      '/rent/payments/',
      token: token,
      query: asTenant ? {'as': 'tenant'} : null,
    );
    return rows.map(RentPayment.fromJson).toList();
  }

  /// Marks a month's rent received. Owners only; the server checks.
  Future<RentPayment> recordPayment(
    int paymentId, {
    required String token,
    String method = '',
    String reference = '',
  }) async {
    final body = await _api.post(
      '/rent/payments/$paymentId/record/',
      {
        if (method.isNotEmpty) 'method': method,
        if (reference.isNotEmpty) 'reference': reference,
      },
      token: token,
    );
    return RentPayment.fromJson(body as Map<String, dynamic>);
  }

  Future<List<RentContract>> contracts(String token,
      {bool asTenant = false}) async {
    final rows = await _collect(
      '/rent/contracts/',
      token: token,
      query: asTenant ? {'as': 'tenant'} : null,
    );
    return rows.map(RentContract.fromJson).toList();
  }

  void dispose() => _api.close();

  Future<List<RentProperty>> _properties({
    String? token,
    Map<String, String>? query,
  }) async {
    final rows = await _collect('/rent/properties/', token: token, query: query);
    return rows.map(RentProperty.fromJson).toList();
  }

  /// Follows DRF's page links, so a landlord with more than a page of flats
  /// does not quietly lose some.
  Future<List<Map<String, dynamic>>> _collect(
    String path, {
    String? token,
    Map<String, String>? query,
  }) async {
    final collected = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final body = await _api.get(
        path,
        token: token,
        query: {...?query, if (page > 1) 'page': '$page'},
      );
      if (body is List) {
        collected.addAll(body.cast<Map<String, dynamic>>());
        return collected;
      }
      final map = body as Map<String, dynamic>;
      collected.addAll(
          (map['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
      if (map['next'] == null) return collected;
      page++;
    }
  }
}
