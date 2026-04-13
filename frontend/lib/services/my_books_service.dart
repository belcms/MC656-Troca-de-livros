import 'dart:convert';
import 'package:http/http.dart' as http;
import '../my_books/my_books_model.dart';
import 'api_client.dart';

class MyBooksService {
  static Future<List<MyBooksModel>?> fetchUserBooks(String userId) async {
    final url = '${ApiClient.baseUrl}/api/v1/users/$userId/announcements';

    try {
      final response = await http.get(Uri.parse(url));

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
