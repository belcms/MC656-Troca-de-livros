import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../book_details/announcement_detail_model.dart';
import '../search/announcement_search_models.dart';

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
      final url = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/announcements/details/$id',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AnnouncementDetail.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Anúncio não encontrado.');
      } else {
        throw Exception(
          'Falha ao carregar anúncio (Erro ${response.statusCode}).',
        );
      }
    } catch (e) {
      throw Exception('Erro de conexão: Não foi possível acessar o servidor.');
    }
  }

  // Fetches the detailed information of a specific announcement.
  //
  // Makes a GET request to the `/api/v1/announcements/details/{id}` endpoint.
  //
  // The [id] parameter is the unique identifier of the announcement.
  // Returns an [AnnouncementDetail] object if the request is successful (HTTP 200),
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
      } else if (response.statusCode == 404) {
        throw Exception('Anúncio não encontrado.');
      } else {
        throw Exception(
          'Falha ao carregar anúncio (Erro ${response.statusCode}).',
        );
      }
    } catch (e) {
      throw Exception('Erro de conexão: Não foi possível acessar o servidor.');
    }
  }

  // Updates an announcement.
  //
  // Makes a PUT request to the `/api/v1/announcements/{id}` endpoint.
  //
  // The [id] parameter is the unique identifier of the announcement.
  // The [body] parameter contains the updated data for the announcement.
  //
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

  /// Searches announcements by a text query.
  ///
  /// Makes a GET request to `/api/v1/announcements/search` with `query`,
  /// `limit`, and `offset` query parameters.
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

  //  Creates an announcement.
  //
  //  Makes a POST request to the `/api/v1/announcements/{userId}` endpoint.
  //
  //  The [body] parameter contains the data for the announcement.
  //  The [userId] parameter is the unique identifier of the user creating the announcement.
  // static Future<bool> createAnnouncement({
  //   required Map<String, dynamic> body,
  //   required String userId,
  // }) async {
  //   try {
  //     // cria book
  //     final bookUrl = Uri.parse('${ApiClient.baseUrl}/api/v1/books');
  //     final bookResponse = await http.post(
  //       bookUrl,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(body),
  //     );
  //     if (bookResponse.statusCode != 201 && bookResponse.statusCode != 200)
  //       return false;

  //     // cria edition
  //     final editionUrl = Uri.parse(
  //       '${ApiClient.baseUrl}/api/v1/editions/${jsonDecode(bookResponse.body)["bookId"]}',
  //     );
  //     final editionResponse = await http.post(
  //       editionUrl,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(body),
  //     );
  //     if (editionResponse.statusCode != 201 &&
  //         editionResponse.statusCode != 200)
  //       return false;

  //     // cria announcement
  //     final announcementUrl = Uri.parse(
  //       '${ApiClient.baseUrl}/api/v1/announcements/$userId',
  //     );

  //     body["editionId"] = jsonDecode(editionResponse.body)["editionId"];
  //     final announcementResponse = await http.post(
  //       announcementUrl,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(body),
  //     );
  //     if (announcementResponse.statusCode != 201 &&
  //         announcementResponse.statusCode != 200)
  //       return false;
  //   } catch (e) {
  //     print('CREATE ERROR: $e');
  //     return false;
  //   }
  //   return true;
  // }

  static Future<String?> createAnnouncement({
    required Map<String, dynamic> body,
    required String userId,
  }) async {
    try {
      // cria book
      final bookUrl = Uri.parse('${ApiClient.baseUrl}/api/v1/books');
      final bookResponse = await http.post(
        bookUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (bookResponse.statusCode != 201 && bookResponse.statusCode != 200) {
        return null; // Retorna null em vez de false
      }

      // cria edition
      final editionUrl = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/editions/${jsonDecode(bookResponse.body)["bookId"]}',
      );
      final editionResponse = await http.post(
        editionUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (editionResponse.statusCode != 201 &&
          editionResponse.statusCode != 200) {
        return null; // Retorna null em vez de false
      }

      // cria announcement
      final announcementUrl = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/announcements/$userId',
      );

      body["editionId"] = jsonDecode(editionResponse.body)["editionId"];
      final announcementResponse = await http.post(
        announcementUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (announcementResponse.statusCode != 201 &&
          announcementResponse.statusCode != 200) {
        return null; // Retorna null em vez de false
      }

      // SUCESSO! Pega a resposta do backend e extrai o ID gerado.
      final responseBody = jsonDecode(announcementResponse.body);
      print("RESPOSTA DO BACKEND: $responseBody");

      final String? extractedId = responseBody["data"]?["id"]?.toString();

      if (extractedId == null) {
        print("ALERTA: O anúncio foi criado, mas não achei o ID no JSON!");
      }

      // NOTA: Se o seu backend FastAPI retorna o ID com um nome diferente de "id"
      // (como "announcement_id" ou "announcementId"), ajuste a chave abaixo:
      // return responseBody["id"]?.toString();
      return extractedId;
    } catch (e) {
      print('CREATE ERROR: $e');
      return null;
    }
  }

  // Sets dummy data in the backend.
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
