import 'package:http/http.dart' as http;
import '../auth/auth_repository.dart';

class ApiClient {
  // Use '127.0.0.1' ou 'localhost' se estiver testando no Simulador iOS ou Web. O memso para o simulador Android.
  // Use '10.0.2.2' se estiver testando no Emulador Android.
  // Use o IP da sua máquina (ex: 192.168.1.15) se testar no celular físico.
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<http.Response> get(String path, {http.Client? client}) =>
      _send('GET', path, client: client);

  static Future<http.Response> post(
    String path, {
    String? body,
    http.Client? client,
  }) => _send('POST', path, body: body, client: client);

  static Future<http.Response> put(
    String path, {
    String? body,
    http.Client? client,
  }) => _send('PUT', path, body: body, client: client);

  static Future<http.Response> patch(
    String path, {
    String? body,
    http.Client? client,
  }) => _send('PATCH', path, body: body, client: client);

  static Future<http.Response> _send(
    String method,
    String path, {
    String? body,
    bool retry = true,
    http.Client? client,
  }) async {
    final requestClient = client ?? http.Client();
    final ownsClient = client == null;
    final token = AuthRepository.instance.accessToken;
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final uri = Uri.parse('$baseUrl$path');
    try {
      late http.Response response;
      if (method == 'POST') {
        response = await requestClient.post(uri, headers: headers, body: body);
      } else if (method == 'PUT') {
        response = await requestClient.put(uri, headers: headers, body: body);
      } else if (method == 'PATCH') {
        response = await requestClient.patch(uri, headers: headers, body: body);
      } else {
        response = await requestClient.get(uri, headers: headers);
      }
      if (response.statusCode == 401 &&
          retry &&
          await AuthRepository.instance.refresh()) {
        return _send(
          method,
          path,
          body: body,
          retry: false,
          client: requestClient,
        );
      }
      return response;
    } finally {
      if (ownsClient) {
        requestClient.close();
      }
    }
  }
}
