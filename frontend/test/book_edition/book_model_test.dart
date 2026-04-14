import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/book_edition/book_model.dart';

void main() {
  group('Book.fromJson', () {
    test('converte enums do backend para português', () {
      final json = {
        "id": "1",
        "title": "1984",
        "author": "George Orwell",
        "publisher": "Secker",
        "genre": "Sci_fic",
        "language": "En",
        "publishYear": 1949,
        "pages": 328,
        "synopsis": "distopia",
        "description": "livro bom",
        "status": "Available",
        "condition": "Good",
        "real_photo_url": "https://example.com/book.jpg"
      };

      final book = Book.fromJson(json);

      expect(book.id, "1");
      expect(book.title, "1984");
      expect(book.genre, "Ficção científica");
      expect(book.language, "Inglês");
      expect(book.status, "Disponível");
      expect(book.condition, "Bom");
    });

    test('usa fallback quando campos faltam', () {
      final book = Book.fromJson({});

      expect(book.id, "");
      expect(book.title, "");
      expect(book.genre, "Romance");
      expect(book.language, "Português");
      expect(book.status, "Disponível");
      expect(book.condition, "Novo");
    });
  });

  group('Book.toJson', () {
    test('converte valores do front para formato do backend', () {
      final book = Book(
        id: "1",
        title: "1984",
        author: "George Orwell",
        publisher: "Secker",
        genre: "Ficção científica",
        language: "Inglês",
        year: "1949",
        pages: "328",
        synopsis: "distopia",
        description: "livro bom",
        status: "Disponível",
        condition: "Bom",
        coverUrl: "url",
      );

      final json = book.toJson();

      expect(json["genre"], "Sci_fic");
      expect(json["language"], "En");
      expect(json["status"], "Available");
      expect(json["condition"], "Good");
    });
  });
}