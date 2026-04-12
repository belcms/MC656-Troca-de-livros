import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../book_details/announcement_detail_model.dart';

class AnnouncementService {
  static Future<AnnouncementDetail?> fetchAnnouncementDetails(String id) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/v1/announcements/details/$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AnnouncementDetail.fromJson(data);
      }

      return null;
    } catch (_) {
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
      return null;
    } catch (e) {
      return null;
    }
  }
}
