import 'api_client.dart';
import 'booking_models.dart';

class BookingRepository {
  BookingRepository({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  Future<BookingConfirmation> create(BookingRequest request) async {
    final body = await _api.post('/bookings/', request.toJson());
    return BookingConfirmation.fromJson(body as Map<String, dynamic>);
  }

  void dispose() => _api.close();
}
