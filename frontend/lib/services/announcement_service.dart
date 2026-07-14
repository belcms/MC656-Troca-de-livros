import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';
import '../book_details/announcement_detail_model.dart';
import '../feed/announcement_filters.dart';
import '../search/announcement_search_models.dart';

/// Service responsible for handling HTTP requests related to announcements.
class AnnouncementService {
  /// Fetches the details of a specific announcement.
  static Future<AnnouncementDetail?> fetchAnnouncementDetails(
    String id,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/announcements/details/$id',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AnnouncementDetail.fromJson(data);
      }

      if (response.statusCode == 404) {
        throw Exception('Anúncio não encontrado.');
      }

      throw Exception(
        'Falha ao carregar anúncio (Erro ${response.statusCode}).',
      );
    } catch (e) {
      throw Exception(
        'Erro de conexão: Não foi possível acessar o servidor.',
      );
    }
  }

  /// Fetches the details of an announcement as raw JSON.
  static Future<Map<String, dynamic>?> fetchAnnouncementDetailsRaw(
    String id,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/announcements/details/$id',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 404) {
        throw Exception('Anúncio não encontrado.');
      }

      throw Exception(
        'Falha ao carregar anúncio (Erro ${response.statusCode}).',
      );
    } catch (e) {
      throw Exception(
        'Erro de conexão: Não foi possível acessar o servidor.',
      );
    }
  }

  /// Updates an announcement.
  static Future<bool> updateAnnouncement({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/books/$id',
      );

      print('UPDATE URL: $url');
      print('UPDATE BODY: ${jsonEncode(body)}');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('UPDATE STATUS: ${response.statusCode}');
      print('UPDATE RESPONSE: ${response.body}');

      return response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (e) {
      print('UPDATE ERROR: $e');
      return false;
    }
  }

  /// Fetches the paginated announcements shown in the main feed.
  ///
  /// Supports filters for publication year, condition and genre.
  /// When [sortByDistance] is true, the backend can sort announcements
  /// using the location of [currentUserId].
  static Future<List<dynamic>?> fetchFeedAnnouncements({
    required String currentUserId,
    int limit = 20,
    int offset = 0,
    AnnouncementFilters filters = const AnnouncementFilters(),
    bool sortByDistance = false,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        'current_user_id': currentUserId,
        'sort_by_distance': sortByDistance.toString(),
      };

      if (filters.hasYearFilter) {
        queryParameters['start_year'] =
            filters.startYear.toString();

        queryParameters['end_year'] =
            filters.endYear.toString();
      }

      if (filters.conditions.isNotEmpty) {
        queryParameters['condition'] = filters.conditions;
      }

      if (filters.genres.isNotEmpty) {
        queryParameters['genre'] = filters.genres;
      }

      if (filters.maxDistanceKm != null) {
        queryParameters['max_distance_km'] =
            filters.maxDistanceKm.toString();
      }

      final url = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/announcements/feed',
      ).replace(
        queryParameters: queryParameters,
      );

      print('FEED URL: $url');

      final response = await http.get(url);

      print('FEED STATUS: ${response.statusCode}');
      print('FEED RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }

      return null;
    } catch (e) {
      print('FEED ERROR: $e');
      return null;
    }
  }

  /// Searches announcements using a text query.
  static Future<AnnouncementSearchResponse> fetchSearchAnnouncements({
    required String query,
    int limit = 4,
    int offset = 0,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/announcements/search',
      ).replace(
        queryParameters: {
          'query': query,
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body) as Map<String, dynamic>;

        return AnnouncementSearchResponse.fromJson(data);
      }

      throw Exception(
        'Falha ao buscar anúncios (Erro ${response.statusCode}).',
      );
    } catch (e) {
      throw Exception(
        'Erro de conexão: Não foi possível acessar a busca.',
      );
    }
  }

  /// Creates a book, its edition and an announcement.
  static Future<bool> createAnnouncement({
    required Map<String, dynamic> body,
    required String userId,
  }) async {
    try {
      final requestBody = Map<String, dynamic>.from(body);

      final bookUrl = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/books',
      );

      final bookResponse = await http.post(
        bookUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('CREATE BOOK STATUS: ${bookResponse.statusCode}');
      print('CREATE BOOK RESPONSE: ${bookResponse.body}');

      if (bookResponse.statusCode != 200 &&
          bookResponse.statusCode != 201) {
        return false;
      }

      final bookData =
          jsonDecode(bookResponse.body) as Map<String, dynamic>;

      final bookId =
          bookData['bookId'] ?? bookData['id'];

      if (bookId == null) {
        print('CREATE ERROR: bookId não retornado pelo backend.');
        return false;
      }

      final editionUrl = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/editions/$bookId',
      );

      final editionResponse = await http.post(
        editionUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('CREATE EDITION STATUS: ${editionResponse.statusCode}');
      print('CREATE EDITION RESPONSE: ${editionResponse.body}');

      if (editionResponse.statusCode != 200 &&
          editionResponse.statusCode != 201) {
        return false;
      }

      final editionData =
          jsonDecode(editionResponse.body) as Map<String, dynamic>;

      final editionId =
          editionData['editionId'] ?? editionData['id'];

      if (editionId == null) {
        print('CREATE ERROR: editionId não retornado pelo backend.');
        return false;
      }

      requestBody['editionId'] = editionId;

      final announcementUrl = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/announcements/$userId',
      );

      final announcementResponse = await http.post(
        announcementUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print(
        'CREATE ANNOUNCEMENT STATUS: '
        '${announcementResponse.statusCode}',
      );
      print(
        'CREATE ANNOUNCEMENT RESPONSE: '
        '${announcementResponse.body}',
      );

      return announcementResponse.statusCode == 200 ||
          announcementResponse.statusCode == 201;
    } catch (e) {
      print('CREATE ERROR: $e');
      return false;
    }
  }

  /// Requests the backend to create dummy data.
  static Future<bool> setDummyData() async {
    try {
      final url = Uri.parse(
        '${ApiClient.baseUrl}/create-dummy-data',
      );

      final response = await http.post(url);

      print('DUMMY STATUS: ${response.statusCode}');
      print('DUMMY BODY: ${response.body}');

      return response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (e) {
      print('DUMMY ERROR: $e');
      return false;
    }
  }
}