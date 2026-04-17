import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AnnouncementService {

  /// fetches the details of one announcement by id
  /// used to load book data in the edit screen
  /// returns decoded json if request is successful
  static Future<Map<String, dynamic>?> fetchAnnouncementDetails(
    String id,
  ) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/v1/books/details/$id');
      final response = await http.get(url);

      /// sucess response
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      /// debug information in case of error
      print('DETAILS STATUS: ${response.statusCode}');
      print('DETAILS BODY: ${response.body}');
      return null;
    } catch (e) {

      /// network or parsing error
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

  /// sends edited book data to backend
  /// used when user presses save button
  /// returns true if update works
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

      /// debug response to help track errors
      print('UPDATE STATUS: ${response.statusCode}');
      print('UPDATE BODY: ${response.body}');

      ///200 and 204 is succes
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {

      /// network or server error
      print('UPDATE ERROR: $e');
      return false;
    }
  }
}