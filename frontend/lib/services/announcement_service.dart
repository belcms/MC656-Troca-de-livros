import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../book_details/announcement_detail_model.dart';


/// A service class responsible for handling HTTP requests related to book announcements.
///
/// This class acts as the bridge between the Flutter application and the 
/// backend API, abstracting away the network logic and JSON decoding.
class AnnouncementService {

  /// Fetches the detailed information of a specific announcement.
  ///
  /// Makes a GET request to the `/api/v1/announcements/details/{id}` endpoint.
  /// 
  /// The [id] parameter is the unique identifier of the announcement.
  /// Returns an [AnnouncementDetail] object if the request is successful (HTTP 200),
  /// or `null` if the request fails, the network drops, or the announcement is not found.
  static Future<AnnouncementDetail?> fetchAnnouncementDetails(String id) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/v1/announcements/details/$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AnnouncementDetail.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Anúncio não encontrado.');
      } else {
        throw Exception('Falha ao carregar anúncio (Erro ${response.statusCode}).');
      }
    } catch (e) {
      throw Exception('Erro de conexão: Não foi possível acessar o servidor.');
    }
  }

  static Future<Map<String, dynamic>?> fetchAnnouncementDetailsRaw(String id) async {
  try {
    final url = Uri.parse('${ApiClient.baseUrl}/api/v1/announcements/details/$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      throw Exception('Anúncio não encontrado.');
    } else {
      throw Exception('Falha ao carregar anúncio (Erro ${response.statusCode}).');
    }
  } catch (e) {
    throw Exception('Erro de conexão: Não foi possível acessar o servidor.');
  }
}

  static Future<bool> updateAnnouncement({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/v1/books/$id');

      print('UPDATE URL: $url');
      print('UPDATE BODY: ${jsonEncode(body)}');

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('UPDATE STATUS: ${response.statusCode}');
      print('UPDATE RESPONSE: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('UPDATE ERROR: $e');
      return false;
    }
  }



  /// Fetches a paginated list of available announcements for the main feed.
  ///
  /// Makes a GET request to the `/api/v1/announcements/feed` endpoint.
  /// 
  /// The [limit] parameter defines the maximum number of items to return (defaults to 20).
  /// The [offset] parameter defines the number of items to skip for pagination (defaults to 0).
  /// 
  /// Returns a `List<dynamic>` containing the decoded JSON data if successful,
  /// or `null` if the request encounters an error.
  
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

