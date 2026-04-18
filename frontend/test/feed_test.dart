import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/feed/announcement_card.dart';
import 'package:frontend/feed/feed_view.dart';


void main() {
  group('Tests for the widgets from feed', () {
    
    testWidgets('EmptyFeedState should show the icon and text correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyFeedState(),
          ),
        ),
      );
      expect(find.byIcon(Icons.auto_stories), findsOneWidget);

      expect(find.text("O feed está vazio!"), findsOneWidget);
      expect(
        find.text("Que tal dar o primeiro passo e anunciar aquele livro que está parado na estante?"),
        findsOneWidget,
      );
    });

    testWidgets('AnnouncementCard should show title, year and CEP correctly', (WidgetTester tester) async {
      const mockTitle = 'O Senhor dos Anéis';
      const mockYear = 2001;
      const mockCep = '01000-000';
      const mockPhotoUrl = 'https://link-falso.com/foto.png';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnnouncementCard(
              title: mockTitle,
              publishYear: mockYear,
              photo: mockPhotoUrl,
              cep: mockCep,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(mockTitle), findsOneWidget);
      expect(find.text('2001'), findsOneWidget); 
      expect(find.text(mockCep), findsOneWidget);

      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

  });
}

