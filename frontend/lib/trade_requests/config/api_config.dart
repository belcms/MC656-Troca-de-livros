class ApiConfig {
  const ApiConfig._();

  /// Android Emulator: http://10.0.2.2:8000
  /// Flutter Web/Desktop: http://localhost:8000
  ///
  /// Pode ser sobrescrito:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Solução temporária enquanto o projeto não possui autenticação.
  ///
  /// Execute:
  /// flutter run --dart-define=CURRENT_USER_ID=<uuid-do-usuario>
  static const String currentUserId = String.fromEnvironment(
    'CURRENT_USER_ID',
    defaultValue: '',
  );
}
