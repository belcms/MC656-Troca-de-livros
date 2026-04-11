import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AnnouncementService {
  static Future<Map<String, dynamic>?> fetchAnnouncementDetails(String id) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/v1/books/details/$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}