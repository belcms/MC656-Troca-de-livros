import 'package:http/http.dart' as http;
import '../auth/auth_repository.dart';

class ApiClient {
  // Use '127.0.0.1' ou 'localhost' se estiver testando no Simulador iOS ou Web. O memso para o simulador Android.
  // Use '10.0.2.2' se estiver testando no Emulador Android.
  // Use o IP da sua máquina (ex: 192.168.1.15) se testar no celular físico.
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<http.Response> get(String path) => _send('GET', path);
  static Future<http.Response> post(String path, {String? body}) =>
      _send('POST', path, body: body);
  static Future<http.Response> put(String path, {String? body}) =>
      _send('PUT', path, body: body);
  static Future<http.Response> delete(String path, {String? body}) =>
      _send('DELETE', path, body: body);
  static Future<http.Response> _send(
    String method,
    String path, {
    String? body,
    bool retry = true,
  }) async {
    final token = AuthRepository.instance.accessToken;
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    if (method == 'POST') {
      response = await http.post(uri, headers: headers, body: body);
    } else if (method == 'PUT') {
      response = await http.put(uri, headers: headers, body: body);
    } else if (method == 'DELETE') {
      response = await http.delete(uri, headers: headers, body: body);
    } else {
      response = await http.get(uri, headers: headers);
    }
    if (response.statusCode == 401 &&
        retry &&
        await AuthRepository.instance.refresh()) {
      return _send(method, path, body: body, retry: false);
    }
    return response;
  }
}
