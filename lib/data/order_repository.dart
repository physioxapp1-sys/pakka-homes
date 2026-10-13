import 'api_client.dart';
import 'cart.dart';
import 'order_models.dart';

class OrderRepository {
  OrderRepository({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  Future<List<DeliverySlot>> slots() async {
    final body = await _api.get('/orders/slots/');
    final rows = body is List ? body : const [];
    return rows.map((e) => DeliverySlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Saved addresses. Signed-in only - a guest types one in at checkout.
  Future<List<SavedAddress>> addresses(String token) async {
    final body = await _api.get('/addresses/', token: token);
    final rows = body is List
        ? body
        : (body as Map<String, dynamic>)['results'] as List<dynamic>? ?? [];
    return rows.map((e) => SavedAddress.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SavedAddress> saveAddress(SavedAddress address, String token) async {
    final body = await _api.post('/addresses/', address.toJson(), token: token);
    return SavedAddress.fromJson(body as Map<String, dynamic>);
  }

  /// Places the order. Only slugs and quantities go up - the server prices it,
  /// so the total the app shows is a preview, not the agreement.
  Future<CustomerOrder> place({
    required Cart cart,
    required String contactName,
    required String contactPhone,
    required String deliveryAddress,
    String landmark = '',
    DateTime? scheduledDate,
    String? slot,
    String notes = '',
    String? token,
  }) async {
    final body = await _api.post(
      '/orders/',
      {
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'delivery_address': deliveryAddress,
        if (landmark.isNotEmpty) 'landmark': landmark,
        if (scheduledDate != null)
          'scheduled_date': '${scheduledDate.year.toString().padLeft(4, '0')}-'
              '${scheduledDate.month.toString().padLeft(2, '0')}-'
              '${scheduledDate.day.toString().padLeft(2, '0')}',
        if (slot != null && slot.isNotEmpty) 'slot': slot,
        if (notes.isNotEmpty) 'notes': notes,
        'items': [
          for (final line in cart.lines)
            {'slug': line.product.slug, 'quantity': line.quantity},
        ],
      },
      token: token,
    );
    return CustomerOrder.fromJson(body as Map<String, dynamic>);
  }

  Future<List<CustomerOrder>> mine(String token) async {
    final collected = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final body = await _api.get('/orders/mine/',
          query: page > 1 ? {'page': '$page'} : null, token: token);
      if (body is List) {
        collected.addAll(body.cast<Map<String, dynamic>>());
        break;
      }
      final map = body as Map<String, dynamic>;
      collected.addAll((map['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
      if (map['next'] == null) break;
      page++;
    }
    return collected.map(CustomerOrder.fromJson).toList();
  }

  Future<CustomerOrder> lookup({
    required String reference,
    required String phone,
  }) async {
    final body = await _api.get(
      '/orders/${reference.trim().toUpperCase()}/',
      query: {'phone': phone.trim()},
    );
    return CustomerOrder.fromJson(body as Map<String, dynamic>);
  }

  void dispose() => _api.close();
}
