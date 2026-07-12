import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

class GoogleOnboarding {
  final String token;
  final String fullName;
  final String email;
  const GoogleOnboarding(this.token, this.fullName, this.email);
}

class AuthRepository {
  AuthRepository._();
  static final instance = AuthRepository._();
  static const _storage = FlutterSecureStorage();
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  final _google = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: _googleServerClientId.isEmpty
        ? null
        : _googleServerClientId,
  );
  String? accessToken;
  String? _refreshToken;
  AuthUser? user;
  GoogleOnboarding? pendingOnboarding;
  void Function()? onSessionInvalidated;

  Future<bool> restore() async {
    final onboardingToken = await _storage.read(key: 'google_onboarding_token');
    final onboardingName = await _storage.read(key: 'google_onboarding_name');
    final onboardingEmail = await _storage.read(key: 'google_onboarding_email');
    if (onboardingToken != null &&
        onboardingName != null &&
        onboardingEmail != null) {
      pendingOnboarding = GoogleOnboarding(
        onboardingToken,
        onboardingName,
        onboardingEmail,
      );
      return false;
    }
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

  Future<GoogleOnboarding?> loginWithGoogle() async {
    if (_googleServerClientId.isEmpty) {
      throw const AuthException(
        'Login Google não configurado. Execute o app com '
        '--dart-define=GOOGLE_SERVER_CLIENT_ID=seu-web-client-id.',
      );
    }
    final account = await _google.signIn();
    if (account == null) return null;
    final authentication = await account.authentication;
    if (authentication.idToken == null) {
      throw const AuthException('Google não forneceu um ID token.');
    }
    final response = await _rawPost('/api/v1/auth/google', {
      'id_token': authentication.idToken,
    });
    final data = _decode(response);
    if (data['requires_onboarding'] == true) {
      pendingOnboarding = GoogleOnboarding(
        data['onboarding_token'],
        data['full_name'],
        data['email'],
      );
      await _storage.write(
        key: 'google_onboarding_token',
        value: pendingOnboarding!.token,
      );
      await _storage.write(
        key: 'google_onboarding_name',
        value: pendingOnboarding!.fullName,
      );
      await _storage.write(
        key: 'google_onboarding_email',
        value: pendingOnboarding!.email,
      );
      return pendingOnboarding;
    }
    await _clearPendingOnboarding();
    await _saveSession(data);
    return null;
  }

  Future<void> completeGoogle(
    GoogleOnboarding onboarding,
    String nickname,
    String birthDate,
    String cep,
  ) async {
    await _authenticate('/api/v1/auth/google/complete', {
      'onboarding_token': onboarding.token,
      'nickname': nickname,
      'birth_date': birthDate,
      'cep': cep,
    });
    await _clearPendingOnboarding();
  }

  Future<void> _clearPendingOnboarding() async {
    pendingOnboarding = null;
    await _storage.delete(key: 'google_onboarding_token');
    await _storage.delete(key: 'google_onboarding_name');
    await _storage.delete(key: 'google_onboarding_email');
  }

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
    await _google.signOut();
    await clear();
  }

  Future<void> clear() async {
    accessToken = null;
    _refreshToken = null;
    user = null;
    pendingOnboarding = null;
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
