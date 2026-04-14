import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AnnouncementService {
  static Future<Map<String, dynamic>?> fetchAnnouncementDetails(
    String id,
  ) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/v1/books/details/$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      print('DETAILS STATUS: ${response.statusCode}');
      print('DETAILS BODY: ${response.body}');
      return null;
    } catch (e) {
      print('DETAILS ERROR: $e');
      return null;
    }
  }

  static Future<List<dynamic>?> fetchFeedAnnouncements({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/v1/announcements/feed')
          .replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }

      print('FEED STATUS: ${response.statusCode}');
      print('FEED BODY: ${response.body}');
      return null;
    } catch (e) {
      print('FEED ERROR: $e');
      return null;
    }
  }

  static Future<bool> updateAnnouncement({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/v1/books/$id');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('UPDATE STATUS: ${response.statusCode}');
      print('UPDATE BODY: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('UPDATE ERROR: $e');
      return false;
    }
  }
}