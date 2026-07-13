import 'dart:convert';
import 'package:http/http.dart' as http;
import '../my_books/my_books_model.dart';
import 'api_client.dart';

/// HTTP service for the frontend My Books flow.
///
/// This service requests the backend card feed and maps each item to
/// [MyBooksModel].
class MyBooksService {
  /// Fetches announcements that belong to a user.
  ///
  /// Endpoint: `GET /api/v1/users/{userId}/announcements`.
  /// Returns `null` when request fails or backend does not return `200`.
  static Future<List<MyBooksModel>?> fetchUserBooks(String userId) async {
    final url = '${ApiClient.baseUrl}/api/v1/users/$userId/announcements';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<MyBooksModel> books = [];
        for (final item in data) {
          try {
            books.add(MyBooksModel.fromJson(item));
          } catch (e) {
            print('Erro ao parsear anúncio do usuário: $e — item: $item');
          }
        }
        return books;
      } else {
        print('Erro ao carregar anúncios: ${response.statusCode}');
        print('Resposta: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erro de conexão ao carregar livros: $e');
      return null;
    }
  }
}
