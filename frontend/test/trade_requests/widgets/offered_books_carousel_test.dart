import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/trade_requests/widgets/offered_book_card.dart';
import 'package:frontend/trade_requests/widgets/offered_books_carousel.dart';

import '../helpers/trade_request_test_data.dart';

void main() {
  testWidgets('exibe mensagem quando nenhum livro foi oferecido', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OfferedBooksCarousel(books: []),
        ),
      ),
    );

    expect(
      find.text('Nenhum livro foi oferecido para esta troca.'),
      findsOneWidget,
    );
  });

  testWidgets('renderiza um card para cada livro oferecido', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OfferedBooksCarousel(
            books: [
              testOfferedBook1984,
              testOfferedBookDescartes,
            ],
          ),
        ),
      ),
    );

    expect(find.byType(OfferedBookCard), findsNWidgets(2));
    expect(find.text('1984'), findsOneWidget);
    expect(find.text('Discurso do Método'), findsOneWidget);
  });

  testWidgets('usa lista horizontal', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OfferedBooksCarousel(
            books: [
              testOfferedBook1984,
              testOfferedBookDescartes,
            ],
          ),
        ),
      ),
    );

    final list = tester.widget<ListView>(find.byType(ListView));

    expect(list.scrollDirection, Axis.horizontal);
  });

  testWidgets('permite rolagem horizontal com vários livros', (tester) async {
    await tester.binding.setSurfaceSize(const Size(260, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OfferedBooksCarousel(
            books: [
              testOfferedBook1984,
              testOfferedBookDescartes,
              testOfferedBook1984,
              testOfferedBookDescartes,
            ],
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(-250, 0));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
