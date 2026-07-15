import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../services/api_client.dart';
import 'auth_repository.dart';
import 'auth_user.dart';

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository._();

  static final instance = HttpAuthRepository._();

  static const _storage = FlutterSecureStorage();

  @override
  String? accessToken;

  String? _refreshToken;

  @override
  AuthUser? user;

  void Function()? _onSessionInvalidated;

  @override
  set onSessionInvalidated(void Function()? callback) {
    _onSessionInvalidated = callback;
  }

  @override
  Future<bool> restore() async {
    accessToken = await _storage.read(
      key: 'access_token',
    );
    _refreshToken = await _storage.read(
      key: 'refresh_token',
    );

    if (_refreshToken == null) {
      return false;
    }

    return refresh();
  }

  @override
  Future<void> register(
    Map<String, dynamic> body,
  ) {
    return _authenticate(
      '/api/v1/auth/register',
      body,
    );
  }

  @override
  Future<void> login(
    String email,
    String password,
  ) {
    return _authenticate(
      '/api/v1/auth/login',
      {
        'email': email,
        'password': password,
      },
    );
  }

  @override
  Future<bool> refresh() async {
    final token = _refreshToken ??
        await _storage.read(
          key: 'refresh_token',
        );

    if (token == null) {
      return false;
    }

    try {
      final response = await _rawPost(
        '/api/v1/auth/refresh',
        {
          'refresh_token': token,
        },
      );

      await _saveSession(
        _decode(response),
      );

      return true;
    } catch (_) {
      await clear();
      return false;
    }
  }

  @override
  Future<void> logout() async {
    final token = _refreshToken;

    if (token != null) {
      try {
        await _rawPost(
          '/api/v1/auth/logout',
          {
            'refresh_token': token,
          },
        );
      } catch (_) {}
    }

    await clear();
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    _refreshToken = null;
    user = null;

    await _storage.deleteAll();

    _onSessionInvalidated?.call();
  }

  Future<void> _authenticate(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _rawPost(
      path,
      body,
    );

    await _saveSession(
      _decode(response),
    );
  }

  Future<http.Response> _rawPost(
    String path,
    Map<String, dynamic> body,
  ) {
    return http.post(
      Uri.parse('${ApiClient.baseUrl}$path'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  Map<String, dynamic> _decode(
    http.Response response,
  ) {
    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (
      response.statusCode < 200 ||
      response.statusCode >= 300
    ) {
      final detail = data['detail'];

      throw AuthException(
        detail is String
            ? detail
            : 'Não foi possível concluir a operação.',
        response.statusCode,
      );
    }

    return data;
  }

  Future<void> _saveSession(
    Map<String, dynamic> data,
  ) async {
    accessToken = data['access_token']?.toString();
    _refreshToken = data['refresh_token']?.toString();

    final rawUser = data['user'];

    if (rawUser is Map) {
      user = AuthUser.fromJson(
        Map<String, dynamic>.from(rawUser),
      );
    }

    await _storage.write(
      key: 'access_token',
      value: accessToken,
    );

    await _storage.write(
      key: 'refresh_token',
      value: _refreshToken,
    );
  }
}