class ApiClient {
  // Use '127.0.0.1' ou 'localhost' se estiver testando no Simulador iOS ou Web. O memso para o simulador Android.
  // Use '10.0.2.2' se estiver testando no Emulador Android.
  // Use o IP da sua máquina (ex: 192.168.1.15) se testar no celular físico.
  // static const String baseUrl = 'http://10.0.2.2:8000';
  // static const String baseUrl = 'http://192.168.15.65:8000';
  // }
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
