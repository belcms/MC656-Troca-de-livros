import 'dart:convert';
import '../my_books/my_books_model.dart';
import 'api_client.dart';

/// HTTP service for the frontend My Books flow.
///
/// This service requests the backend card feed and maps each item to
/// [MyBooksModel].
class MyBooksService {
  /// Fetches announcements that belong to a user.
  ///
  /// Endpoint: `GET /api/v1/users/me/announcements`.
  /// Returns `null` when request fails or backend does not return `200`.
  static Future<List<MyBooksModel>?> fetchMyBooks() async {
    try {
      final response = await ApiClient.get('/api/v1/users/me/announcements');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MyBooksModel.fromJson(json)).toList();
      } else {
        print('Erro ao carregar anúncios: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro de conexão ao carregar livros: $e');
      return null;
    }
  }
}
