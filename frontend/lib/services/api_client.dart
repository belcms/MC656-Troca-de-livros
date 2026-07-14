class ApiClient {
  // Use API_BASE_URL para alternar entre emulador, web, iOS ou celular físico
  // sem alterar o código.
  //
  // Android Emulator:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  //
  // Web/Desktop/iOS Simulator:
  // flutter run --dart-define=API_BASE_URL=http://localhost:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // Enquanto não houver autenticação integrada, o usuário atual vem por
  // dart-define. Se estiver vazio, o feed mantém o comportamento antigo.
  //
  // Exemplo:
  // flutter run --dart-define=CURRENT_USER_ID=<id-do-usuario>
  static const String currentUserId = String.fromEnvironment(
    'CURRENT_USER_ID',
    defaultValue: '',
  );
}