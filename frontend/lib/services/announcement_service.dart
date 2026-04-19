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
        headers: {'Content-Type': 'application/json'},
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

  static Future<bool> createAnnouncement({
    required Map<String, dynamic> body, required String userId,
  }) async {
    try {
      // cria book
      final bookUrl = Uri.parse('${ApiClient.baseUrl}/api/v1/books');
      final bookResponse = await http.post(
        bookUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if(bookResponse.statusCode != 201 && bookResponse.statusCode != 200) return false;
      
      // cria edition
      final editionUrl = Uri.parse('${ApiClient.baseUrl}/api/v1/editions/${jsonDecode(bookResponse.body)["bookId"]}');
      final editionResponse = await http.post(
        editionUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if(editionResponse.statusCode != 201 && editionResponse.statusCode != 200) return false;

      // cria announcement
      final announcementUrl = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/announcements/d9490809-09b7-4bf9-8165-56db8d45c32c',
      );

      body["editionId"] = jsonDecode(editionResponse.body)["editionId"];
      final announcementResponse = await http.post(
        announcementUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if(announcementResponse.statusCode != 201 && announcementResponse.statusCode != 200) return false;

    } catch (e) {
      print('CREATE ERROR: $e');
      return false;
    }
    return true;
  }

  static Future<bool> setDummyData() async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/create-dummy-data');
      final response = await http.post(url);

      print('DUMMY STATUS: ${response.statusCode}');
      print('DUMMY BODY: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('DUMMY ERROR: $e');
      return false;
    }
  }
}
