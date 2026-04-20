import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/book_details/announcement_detail_screen.dart';
import 'package:frontend/book_details/announcement_detail_model.dart';

void main() {
  group('Tests for Announcement Detail Screen and Model', () {
    
    // 1. TESTE DO ESTADO DE CARREGAMENTO (Loading)
    testWidgets('Should show loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnnouncementDetailScreen(announcementId: '123-uuid'),
        ),
      );

      // Logo que a tela é montada, o FutureBuilder está no estado "waiting".
      // Esperamos encontrar exatamente um CircularProgressIndicator.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // 2. TESTE DO ESTADO DE ERRO (Tratamento de Exceção visual)
    testWidgets('Should show error state when API request fails', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnnouncementDetailScreen(announcementId: '123-uuid'),
        ),
      );

      // O pumpAndSettle aguarda a requisição falhar e a tela ser atualizada
      await tester.pumpAndSettle();

      // Verifica apenas a existência dos elementos visuais principais da tela de erro
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    // 3. TESTE DE UNIDADE DO MODELO (Garante que o JSON é lido corretamente)
    test('AnnouncementDetail model should parse JSON correctly', () {
      // Mock de um JSON simulando o retorno da API
      final Map<String, dynamic> mockJson = {
        "id": "123-uuid",
        "description": "Livro muito bem conservado, lido apenas uma vez.",
        "real_photo_url": "https://link-falso.com/foto.jpg",
        "condition": "New",
        "status": "Available",
        "user_name": "Victor Luigi",
        "user_cep": "13000-000",
        "edition": {
          "id": "ed-1",
          "publisher": "Editora Arqueiro",
          "publish_year": 2021
        },
        "book": {
          "id": "bk-1",
          "title": "Clean Code",
          "author": "Robert C. Martin",
          "synopsis": "Mesmo código, melhor design."
        }
      };

      // Transformando o JSON no objeto Dart
      final announcement = AnnouncementDetail.fromJson(mockJson);

      // Verificações
      expect(announcement.id, "123-uuid");
      expect(announcement.condition, "New");
      expect(announcement.userName, "Victor Luigi");
      expect(announcement.userCep, "13000-000");
      
      // Verificando classes aninhadas (Book e Edition)
      expect(announcement.book?.title, "Clean Code");
      expect(announcement.book?.author, "Robert C. Martin");
      expect(announcement.edition?.publishYear, 2021);
    });
    
  });
}