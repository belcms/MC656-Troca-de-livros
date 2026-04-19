import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/book_edition/book_edition_screen.dart';
import 'package:frontend/book_edition/book_edition_viewmodel.dart';

class FakeAnnouncementService implements AnnouncementServiceInterface {
  @override
  Future<Map<String, dynamic>?> fetchAnnouncementDetails(String id) async {
    return {
      'id': id,
      'title': '1984',
      'author': 'George Orwell',
      'publisher': 'Secker & Warburg',
      'genre': 'Romance',
      'language': 'PT-br',
      'publishYear': 1949,
      'pages': 328,
      'synopsis': 'Sinopse teste',
      'description': 'Descrição teste',
      'status': 'Available',
      'condition': 'Good',
      'real_photo_url': '',
    };
  }

  @override
  Future<bool> updateAnnouncement({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    return true;
  }
}

void main() {
  testWidgets('renderiza a tela de edição', (tester) async {
    final viewModel = BookEditionViewModel(
      service: FakeAnnouncementService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BookEditionPage(
          id: '1',
          viewModel: viewModel,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(BookEditionPage), findsOneWidget);
    expect(find.text('Editar livro'), findsOneWidget);
    expect(find.text('Sobre o livro'), findsOneWidget);
    expect(find.text('Condição'), findsOneWidget);
    expect(find.text('Editar anúncio'), findsOneWidget);
  });
}