import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart'; // Importa a configuração base

class UserService {
  // Usa o baseUrl do ApiClient
  static final String _usersUrl = '${ApiClient.baseUrl}/api/v1/users';

  static Future<List<dynamic>?> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse(_usersUrl));

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Retorna os dados brutos
      } else {
        print('Erro: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro de conexão: $e');
      return null;
    }
  }
}
