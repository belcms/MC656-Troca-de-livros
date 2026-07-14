import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class WishlistItem {
  final String id;
  final String userId;
  final String editionId;
  final String title;
  final String author;
  final String? coverPhoto;

  WishlistItem({
    required this.id,
    required this.userId,
    required this.editionId,
    required this.title,
    required this.author,
    this.coverPhoto,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    // A estrutura do JSON depende da serialização do backend (SQLAlchemy).
    // O backend retorna a wishlist com as relações embutidas (edition -> book).
    final edition = json['edition'] ?? {};
    final book = edition['book'] ?? {};

    return WishlistItem(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      editionId: json['edition_id'] ?? '',
      title: book['title'] ?? 'Título Indisponível',
      author: book['author'] ?? 'Autor Desconhecido',
      coverPhoto: edition['cover_photo'],
    );
  }
}

class WishlistService {
  static Future<List<WishlistItem>?> getWishlist(String userId) async {
    final url = '${ApiClient.baseUrl}/api/v1/users/$userId/wishlist';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => WishlistItem.fromJson(item)).toList();
      } else {
        print('Erro ao carregar wishlist: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro de conexão ao carregar wishlist: $e');
      return null;
    }
  }

  static Future<bool> addToWishlist(String userId, String editionId) async {
    final url = '${ApiClient.baseUrl}/api/v1/users/$userId/wishlist/$editionId';

    try {
      final response = await http.post(Uri.parse(url));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Erro de conexão ao adicionar na wishlist: $e');
      return false;
    }
  }

  static Future<bool> removeFromWishlist(String userId, String editionId) async {
    final url = '${ApiClient.baseUrl}/api/v1/users/$userId/wishlist/$editionId';

    try {
      final response = await http.delete(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      print('Erro de conexão ao remover da wishlist: $e');
      return false;
    }
  }
}
