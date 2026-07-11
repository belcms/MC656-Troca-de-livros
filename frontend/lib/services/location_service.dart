import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class LocationService {
  /// Busca a localização no backend a partir do CEP
  static Future<Map<String, dynamic>?> fetchLocation(String cep) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/v1/locations/$cep');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}