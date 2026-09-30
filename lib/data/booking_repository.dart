import 'api_client.dart';
import 'booking_models.dart';

class BookingRepository {
  BookingRepository({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  /// [token] attaches the booking to a signed-in customer. Guests book
  /// without one; the backend accepts both.
  Future<BookingConfirmation> create(BookingRequest request, {String? token}) async {
    final body = await _api.post('/bookings/', request.toJson(), token: token);
    return BookingConfirmation.fromJson(body as Map<String, dynamic>);
  }

  /// The signed-in customer's own bookings.
  Future<List<CustomerBooking>> mine(String token) async {
    final collected = <Map<String, dynamic>>[];
    var page = 1;

    while (true) {
      final body = await _api.get(
        '/bookings/mine/',
        query: page > 1 ? {'page': '$page'} : null,
        token: token,
      );
      if (body is List) {
        collected.addAll(body.cast<Map<String, dynamic>>());
        break;
      }
      final map = body as Map<String, dynamic>;
      collected.addAll((map['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
      if (map['next'] == null) break;
      page++;
    }
    return collected.map(CustomerBooking.fromJson).toList();
  }

  /// Track one booking without an account. The phone must match the one the
  /// booking was made with, so a forwarded reference alone reveals nothing.
  Future<CustomerBooking> lookup({
    required String reference,
    required String phone,
  }) async {
    final body = await _api.get(
      '/bookings/${reference.trim().toUpperCase()}/',
      query: {'phone': phone.trim()},
    );
    return CustomerBooking.fromJson(body as Map<String, dynamic>);
  }

  void dispose() => _api.close();
}
