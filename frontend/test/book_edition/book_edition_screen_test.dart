import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/book_edition/book_edition_screen.dart';

void main() {

  /// basic widget test to check if the screen renders correctly
  testWidgets('renderiza a tela de edição', (tester) async {

    /// builds the widget inside a material app context
    await tester.pumpWidget(
      const MaterialApp(
        home: BookEditionPage(id: '1'),
      ),
    );

    /// verifies that the page is present in the widget tree
    expect(find.byType(BookEditionPage), findsOneWidget);

  });

}