import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors});

  final String message;
  final int? statusCode;

  /// DRF validation errors, keyed by field name.
  final Map<String, List<String>>? fieldErrors;

  @override
  String toString() => 'ApiException(${statusCode ?? '-'}): $message';
}

/// Thin JSON client for the Dhaubanjar Nirman Sewa backend.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? defaultBaseUrl;

  static const defaultBaseUrl = 'https://www.dhaubanjarnirmansewa.com.np/api/v1';
  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final String baseUrl;

  Future<dynamic> get(String path, {Map<String, String>? query, String? token}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers(token)));

  Future<dynamic> post(String path, Map<String, dynamic> body, {String? token}) => _send(
        () => _client.post(_uri(path), headers: _headers(token), body: jsonEncode(body)),
      );

  void close() => _client.close();

  Map<String, String> _headers(String? token) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse('$baseUrl$path')
      .replace(queryParameters: (query?.isEmpty ?? true) ? null : query);

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on SocketException {
      throw ApiException('No internet connection.');
    } on http.ClientException catch (e) {
      throw ApiException(e.message);
    }

    final body = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      _messageFor(response.statusCode, body),
      statusCode: response.statusCode,
      fieldErrors: _fieldErrorsFrom(body),
    );
  }

  String _messageFor(int status, dynamic body) {
    if (body is Map && body['detail'] is String) return body['detail'] as String;
    if (status == 404) return 'Not found.';
    if (status >= 500) return 'The server is having trouble. Try again shortly.';
    return 'Request failed ($status).';
  }

  Map<String, List<String>>? _fieldErrorsFrom(dynamic body) {
    if (body is! Map) return null;
    final errors = <String, List<String>>{};
    body.forEach((key, value) {
      if (value is List) {
        errors['$key'] = value.map((e) => '$e').toList();
      }
    });
    return errors.isEmpty ? null : errors;
  }
}
