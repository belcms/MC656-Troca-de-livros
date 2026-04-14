import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/book_edition/book_edition_screen.dart';

void main() {
  testWidgets('renderiza a tela de edição', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BookEditionPage(id: '1'),
      ),
    );

    expect(find.byType(BookEditionPage), findsOneWidget);
  });
}