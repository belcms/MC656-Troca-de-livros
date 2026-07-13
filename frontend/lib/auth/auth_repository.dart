import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../services/api_client.dart';
import 'auth_user.dart';

class AuthException implements Exception {
  final String message;
  final int? status;
  const AuthException(this.message, [this.status]);

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository._();
  static final instance = AuthRepository._();
  static const _storage = FlutterSecureStorage();

  String? accessToken;
  String? _refreshToken;
  AuthUser? user;
  void Function()? onSessionInvalidated;

  Future<bool> restore() async {
    accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
    if (_refreshToken == null) return false;
    return refresh();
  }

  Future<void> register(Map<String, dynamic> body) =>
      _authenticate('/api/v1/auth/register', body);

  Future<void> login(String email, String password) => _authenticate(
    '/api/v1/auth/login',
    {'email': email, 'password': password},
  );

  Future<bool> refresh() async {
    final token = _refreshToken ?? await _storage.read(key: 'refresh_token');
    if (token == null) return false;
    try {
      final response = await _rawPost('/api/v1/auth/refresh', {
        'refresh_token': token,
      });
      await _saveSession(_decode(response));
      return true;
    } catch (_) {
      await clear();
      return false;
    }
  }

  Future<void> logout() async {
    final token = _refreshToken;
    if (token != null) {
      try {
        await _rawPost('/api/v1/auth/logout', {'refresh_token': token});
      } catch (_) {}
    }
    await clear();
  }

  Future<void> clear() async {
    accessToken = null;
    _refreshToken = null;
    user = null;
    await _storage.deleteAll();
    onSessionInvalidated?.call();
  }

  Future<void> _authenticate(String path, Map<String, dynamic> body) async {
    final response = await _rawPost(path, body);
    await _saveSession(_decode(response));
  }

  Future<http.Response> _rawPost(String path, Map<String, dynamic> body) =>
      http.post(
        Uri.parse('${ApiClient.baseUrl}$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

  Map<String, dynamic> _decode(http.Response response) {
    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data['detail'];
      throw AuthException(
        detail is String ? detail : 'Não foi possível concluir a operação.',
        response.statusCode,
      );
    }
    return data;
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    accessToken = data['access_token'];
    _refreshToken = data['refresh_token'];
    user = AuthUser.fromJson(data['user']);
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: _refreshToken);
  }
}
