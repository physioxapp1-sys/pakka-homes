import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AuthUser {
  const AuthUser({required this.id, required this.phone, this.fullName = '', this.address = ''});

  final int id;
  final String phone;
  final String fullName;
  final String address;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int? ?? 0,
        phone: json['phone'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        address: json['address'] as String? ?? '',
      );
}

/// Holds the signed-in session and notifies the widgets gated on it.
///
/// Sign-in is never required to browse; only the booking step asks, and only
/// when the customer reaches it.
class AuthRepository extends ChangeNotifier {
  AuthRepository({ApiClient? client}) : _api = client ?? ApiClient();

  static const _tokenKey = 'auth_token';
  static const _phoneKey = 'auth_phone';
  static const _nameKey = 'auth_name';

  final ApiClient _api;

  String? _token;
  AuthUser? _user;

  String? get token => _token;
  AuthUser? get user => _user;
  bool get isSignedIn => _token != null;

  /// Restores a previous session, if any. Safe to call more than once.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return;
    _token = token;
    _user = AuthUser(
      id: 0,
      phone: prefs.getString(_phoneKey) ?? '',
      fullName: prefs.getString(_nameKey) ?? '',
    );
    notifyListeners();
  }

  Future<AuthUser> register({
    required String phone,
    required String password,
    String fullName = '',
  }) =>
      _authenticate('/auth/register/', {
        'phone': phone,
        'password': password,
        if (fullName.isNotEmpty) 'full_name': fullName,
      });

  Future<AuthUser> login({required String phone, required String password}) =>
      _authenticate('/auth/login/', {'phone': phone, 'password': password});

  /// Always succeeds from the caller's point of view - the backend answers
  /// the same way whether or not the number has an account, so this can't
  /// be used to probe which phone numbers are registered.
  Future<String> requestPasswordReset(String phone) async {
    final response =
        await _api.post('/auth/password/forgot/', {'phone': phone}) as Map<String, dynamic>;
    return response['detail'] as String? ??
        'If that phone number has an account, a reset code has been sent to it.';
  }

  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) =>
      _api.post('/auth/password/reset/', {
        'phone': phone,
        'code': code,
        'new_password': newPassword,
      });

  /// Closing the account for good. Requires the current password - see
  /// DeleteAccountSerializer on the backend for why holding a valid token
  /// isn't treated as enough on its own.
  Future<void> deleteAccount(String password) async {
    final token = _token;
    if (token == null) return;
    await _api.delete('/auth/me/', body: {'password': password}, token: token);

    _token = null;
    _user = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_nameKey);
  }

  Future<void> signOut() async {
    final token = _token;
    _token = null;
    _user = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_nameKey);

    if (token != null) {
      // Best effort: the device is already signed out locally either way.
      try {
        await _api.post('/auth/logout/', const {}, token: token);
      } on ApiException {
        // ignored
      }
    }
  }

  Future<AuthUser> _authenticate(String path, Map<String, dynamic> body) async {
    final response = await _api.post(path, body) as Map<String, dynamic>;
    final user = AuthUser.fromJson(response['user'] as Map<String, dynamic>? ?? const {});
    _token = response['token'] as String?;
    _user = user;

    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_phoneKey, user.phone);
    await prefs.setString(_nameKey, user.fullName);

    notifyListeners();
    return user;
  }
}
