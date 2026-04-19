import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/my_books/my_book_card.dart';
import 'package:frontend/my_books/my_books_carousel.dart';
import 'package:frontend/my_books/my_books_model.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(1200, 2000),
        textScaler: TextScaler.linear(0.8),
      ),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('MyBooksModel', () {
    test('fromJson parses payload correctly', () {
      final model = MyBooksModel.fromJson({
        'id': 'book-1',
        'title': 'Clean Code',
        'publish_year': 2008,
        'real_photo_url': 'https://example.com/cover.jpg',
        'status': 'available',
      });

      expect(model.id, 'book-1');
      expect(model.title, 'Clean Code');
      expect(model.publishYear, 2008);
      expect(model.realPhotoUrl, 'https://example.com/cover.jpg');
      expect(model.status, 'available');
    });
  });

  group('MyBookCard', () {
    testWidgets('renders mapped status label and metadata', (tester) async {
      await tester.pumpWidget(
        _testApp(
          const Center(
            child: SizedBox(
              width: 220,
              height: 500,
              child: MyBookCard(
                title: 'Domain-Driven Design',
                publishYear: 2003,
                photo: 'https://example.com/cover.jpg',
                status: 'available',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Domain-Driven Design'), findsOneWidget);
      expect(find.text('2003'), findsOneWidget);
      expect(find.text('Disponivel'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('calls onEdit when edit button is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _testApp(
          Center(
            child: SizedBox(
              width: 220,
              height: 500,
              child: MyBookCard(
                title: 'Refactoring',
                publishYear: 1999,
                photo: 'https://example.com/cover.jpg',
                status: 'reserved',
                onEdit: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.byIcon(Icons.edit_outlined));
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('MyBooksCarousel', () {
    testWidgets('shows empty-state text when there are no books', (
      tester,
    ) async {
      await tester.pumpWidget(_testApp(const MyBooksCarousel(books: [])));

      expect(find.text('Nenhum livro encontrado.'), findsOneWidget);
    });

    testWidgets('renders books in horizontal list', (tester) async {
      final books = [
        MyBooksModel(
          id: '1',
          title: 'Book A',
          publishYear: 2021,
          realPhotoUrl: null,
          status: 'traded',
        ),
        MyBooksModel(
          id: '2',
          title: 'Book B',
          publishYear: 2022,
          realPhotoUrl: null,
          status: 'traded',
        ),
      ];

      await tester.pumpWidget(_testApp(MyBooksCarousel(books: books)));

      expect(find.text('Book A'), findsOneWidget);
      expect(find.text('Book B'), findsOneWidget);
      expect(find.byType(MyBookCard), findsNWidgets(2));
    });
  });
}
