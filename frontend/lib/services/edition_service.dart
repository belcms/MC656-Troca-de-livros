import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class EditionDetailsModel {
  final String id;
  final String title;
  final String author;
  final String publisher;
  final String? genre;
  final String? language;
  final int? publishYear;
  final int? pages;
  final String? synopsis;
  final String? coverPhoto;

  EditionDetailsModel({
    required this.id,
    required this.title,
    required this.author,
    required this.publisher,
    this.genre,
    this.language,
    this.publishYear,
    this.pages,
    this.synopsis,
    this.coverPhoto,
  });

  factory EditionDetailsModel.fromJson(Map<String, dynamic> json) {
    return EditionDetailsModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Sem Título',
      author: json['author'] ?? 'Autor Desconhecido',
      publisher: json['publisher'] ?? 'Editora Desconhecida',
      genre: json['genre'],
      language: json['language'],
      publishYear: json['publishYear'],
      pages: json['pages'],
      synopsis: json['synopsis'],
      coverPhoto: json['cover_photo'],
    );
  }
}

class EditionService {
  static Future<EditionDetailsModel?> getEditionDetails(String editionId) async {
    final url = '${ApiClient.baseUrl}/api/v1/editions/$editionId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EditionDetailsModel.fromJson(data);
      } else {
        print('Erro ao carregar edição: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erro de conexão ao carregar edição: $e');
      return null;
    }
  }
}
