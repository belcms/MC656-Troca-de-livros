abstract class AuthTokenProvider {
  String? get accessToken;

  Future<bool> refresh();
}