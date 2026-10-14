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

  /// Adds a property. The server makes the caller its owner; nothing here
  /// says who owns it, because nothing here should be able to.
  Future<RentProperty> addProperty({
    required String token,
    required String title,
    required String address,
    required double monthlyRent,
    String kind = 'flat',
    String city = '',
    String landmark = '',
    int bedrooms = 0,
    int bathrooms = 0,
    int? areaSqft,
    double deposit = 0,
    bool isListed = false,
    String description = '',
  }) async {
    final body = await _api.post(
      '/rent/properties/',
      {
        'title': title,
        'address': address,
        'kind': kind,
        'monthly_rent': monthlyRent.round().toString(),
        'deposit': deposit.round().toString(),
        if (city.isNotEmpty) 'city': city,
        if (landmark.isNotEmpty) 'landmark': landmark,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        if (areaSqft != null) 'area_sqft': areaSqft,
        'is_listed': isListed,
        if (description.isNotEmpty) 'description': description,
      },
      token: token,
    );
    return RentProperty.fromJson(body as Map<String, dynamic>);
  }

  /// Puts a tenant into a property. The server raises that month's rent as
  /// part of it, so the rent roll is not empty afterwards.
  /// [roomIds] is every room the lease covers - one for a single room, more
  /// where a family takes several. The server treats the first as the
  /// headline one.
  Future<RentContract> addTenant({
    required String token,
    required List<int> roomIds,
    required String tenantName,
    required String tenantPhone,
    required DateTime startDate,
    required double monthlyRent,
    double deposit = 0,
    int rentDueDay = 1,
    String notes = '',
  }) async {
    final body = await _api.post(
      '/rent/contracts/',
      {
        'rooms': roomIds,
        'tenant_name': tenantName,
        'tenant_phone': tenantPhone,
        'start_date': _ymd(startDate),
        'monthly_rent': monthlyRent.round().toString(),
        'deposit': deposit.round().toString(),
        'rent_due_day': rentDueDay,
        if (notes.isNotEmpty) 'notes': notes,
      },
      token: token,
    );
    return RentContract.fromJson(body as Map<String, dynamic>);
  }

  /// Someone has moved out. Ends the lease rather than deleting it.
  Future<RentContract> endTenancy(int tenancyId, {required String token}) async {
    final body = await _api.post(
      '/rent/contracts/$tenancyId/end/',
      const {},
      token: token,
    );
    return RentContract.fromJson(body as Map<String, dynamic>);
  }

  static String _ymd(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

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
