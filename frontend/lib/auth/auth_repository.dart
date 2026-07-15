import 'auth_token_provider.dart';
import 'auth_user.dart';

class AuthException implements Exception {
  final String message;
  final int? status;

  const AuthException(
    this.message, [
    this.status,
  ]);

  @override
  String toString() => message;
}

abstract class AuthRepository implements AuthTokenProvider {
  AuthUser? get user;

  set onSessionInvalidated(void Function()? callback);

  Future<bool> restore();

  Future<void> register(Map<String, dynamic> body);

  Future<void> login(
    String email,
    String password,
  );

  @override
  Future<bool> refresh();

  Future<void> logout();

  Future<void> clear();
}