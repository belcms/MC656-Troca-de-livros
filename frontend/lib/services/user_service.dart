import 'dart:convert';
import 'api_client.dart'; // Importa a configuração base

class UserService {
  static Future<Map<String, dynamic>?> fetchMe() async {
    final response = await ApiClient.get('/api/v1/users/me');
    if (response.statusCode == 200)
      return jsonDecode(response.body) as Map<String, dynamic>;
    return null;
  }
}
