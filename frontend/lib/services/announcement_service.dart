import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';
import '../book_details/announcement_detail_model.dart';
import '../feed/announcement_filters.dart';
import '../feed/feed_announcement.dart';
import '../search/announcement_search_models.dart';

/// Service responsible for handling HTTP requests related to announcements.
class AnnouncementService {
  /// Fetches the details of a specific announcement.
  static Future<AnnouncementDetail?> fetchAnnouncementDetails(String id) async {
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
      throw Exception('Erro de conexão: Não foi possível acessar o servidor.');
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

      throw Exception(
        'Falha ao carregar anúncio (Erro ${response.statusCode}).',
      );
    } catch (e) {
      throw Exception('Erro de conexão: Não foi possível acessar o servidor.');
    }
  }

  /// Updates an announcement.
  ///
  /// Makes a PUT request to the `/api/v1/books/{id}` endpoint.
  ///
  /// The [id] parameter is the unique identifier of the announcement.
  /// The [body] parameter contains the updated data for the announcement.
  static Future<bool> updateAnnouncement({
    required String id,
    required Map body,
  }) async {
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/v1/books/$id');

      print('UPDATE URL: $url');
      print('UPDATE BODY: ${jsonEncode(body)}');

      final response = await ApiClient.put(
        '/api/v1/books/$id',
        body: jsonEncode(body),
      );

      print('UPDATE STATUS: ${response.statusCode}');
      print('UPDATE RESPONSE: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Default behavior:
  /// - sends only [limit] and [offset], preserving the old feed behavior.
  ///
  /// Distance behavior:
  /// - when [sortByDistance] is true and a non-empty [currentUserId] exists,
  ///   sends `current_user_id` and `sort_by_distance=true`.
  /// - the backend returns the feed already ordered by distance.

  static Future<List<FeedAnnouncement>?> fetchFeedAnnouncements({
    required String? currentUserId,
    int limit = 20,
    int offset = 0,
    AnnouncementFilters filters = const AnnouncementFilters(),
    bool sortByDistance = false,
    http.Client? client,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      final normalizedCurrentUserId = currentUserId?.trim();
      final hasCurrentUser = normalizedCurrentUserId?.isNotEmpty ?? false;

      if (hasCurrentUser) {
        queryParameters['current_user_id'] = normalizedCurrentUserId!;
        if (sortByDistance) {
          queryParameters['sort_by_distance'] = 'true';
        }
      }

      if (filters.hasYearFilter) {
        queryParameters['start_year'] = filters.startYear.toString();

        queryParameters['end_year'] = filters.endYear.toString();
      }

      if (filters.conditions.isNotEmpty) {
        queryParameters['condition'] = filters.conditions;
      }

      if (filters.genres.isNotEmpty) {
        queryParameters['genre'] = filters.genres;
      }

      if (hasCurrentUser && filters.maxDistanceKm != null) {
        queryParameters['max_distance_km'] = filters.maxDistanceKm.toString();
      }

      final url = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/announcements/feed',
      ).replace(queryParameters: queryParameters);

      final response = client == null
          ? await http.get(url)
          : await client.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;

        return decoded
            .map(
              (item) => FeedAnnouncement.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
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
      final url = Uri.parse('${ApiClient.baseUrl}/api/v1/announcements/search')
          .replace(
            queryParameters: {
              'query': query,
              'limit': limit.toString(),
              'offset': offset.toString(),
            },
          );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        return AnnouncementSearchResponse.fromJson(data);
      }

      throw Exception(
        'Falha ao buscar anúncios (Erro ${response.statusCode}).',
      );
    } catch (e) {
      throw Exception('Erro de conexão: Não foi possível acessar a busca.');
    }
  }

  static Future<String?> createAnnouncement({
    required Map<String, dynamic> body,
  }) async {
    try {
      final requestBody = Map<String, dynamic>.from(body);

      final bookResponse = await ApiClient.post(
        '/api/v1/books',
        body: jsonEncode(requestBody),
      );
      if (bookResponse.statusCode != 201 && bookResponse.statusCode != 200) {
        return null;
      }

      print('CREATE BOOK STATUS: ${bookResponse.statusCode}');
      print('CREATE BOOK RESPONSE: ${bookResponse.body}');

      final bookData = jsonDecode(bookResponse.body) as Map<String, dynamic>;

      final bookId = bookData['bookId'] ?? bookData['id'];

      if (bookId == null) {
        print('CREATE ERROR: bookId não retornado pelo backend.');
        return null;
      }

      final editionResponse = await ApiClient.post(
        '/api/v1/editions/$bookId',
        body: jsonEncode(requestBody),
      );
      if (editionResponse.statusCode != 201 &&
          editionResponse.statusCode != 200) {
        return null;
      }

      print('CREATE EDITION STATUS: ${editionResponse.statusCode}');
      print('CREATE EDITION RESPONSE: ${editionResponse.body}');

      final editionData =
          jsonDecode(editionResponse.body) as Map<String, dynamic>;

      final editionId = editionData['editionId'] ?? editionData['id'];

      if (editionId == null) {
        print('CREATE ERROR: editionId não retornado pelo backend.');
        return null;
      }

      requestBody['editionId'] = editionId;

      final announcementResponse = await ApiClient.post(
        '/api/v1/announcements',
        body: jsonEncode(requestBody),
      );

      if (announcementResponse.statusCode != 201 &&
          announcementResponse.statusCode != 200) {
        return null;
      }

      // SUCESSO! Pega a resposta do backend e extrai o ID gerado.
      final responseBody = jsonDecode(announcementResponse.body);
      print("RESPOSTA DO BACKEND: $responseBody");

      final String? extractedId = responseBody["data"]?["id"]?.toString();

      if (extractedId == null) {
        print("ALERTA: O anúncio foi criado, mas não achei o ID no JSON!");
      }

      return extractedId;
    } catch (e) {
      print('CREATE ERROR: $e');
      return null;
    }
  }

  /// Requests the backend to create dummy data.
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
