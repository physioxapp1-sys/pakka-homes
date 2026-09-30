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

  void dispose() => _api.close();
}
