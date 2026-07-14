import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/feed/announcement_card.dart';

void main() {
  Widget buildTestWidget({
    required double? distanceKm,
    String cep = 'Campinas - SP',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: AnnouncementCard(
            title: 'Clean Code',
            publishYear: 2008,
            photo: 'https://example.com/clean-code.jpg',
            cep: cep,
            distanceKm: distanceKm,
          ),
        ),
      ),
    );
  }

  group('AnnouncementCard distance display', () {
    testWidgets(
      'exibe distância em quilômetros quando distanceKm é maior ou igual a 1',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(distanceKm: 12.4),
        );

        expect(find.text('Clean Code'), findsOneWidget);
        expect(find.text('2008'), findsOneWidget);
        expect(find.text('Campinas - SP'), findsOneWidget);
        expect(find.text('12.4 km de você'), findsOneWidget);
      },
    );

    testWidgets(
      'exibe distância em metros quando distanceKm é menor que 1',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(distanceKm: 0.35),
        );

        expect(find.text('350 m de você'), findsOneWidget);
        expect(find.text('Campinas - SP'), findsOneWidget);
      },
    );

    testWidgets(
      'não exibe texto de distância quando distanceKm é null',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(distanceKm: null),
        );

        expect(find.text('Clean Code'), findsOneWidget);
        expect(find.text('2008'), findsOneWidget);
        expect(find.text('Campinas - SP'), findsOneWidget);

        expect(find.textContaining('km de você'), findsNothing);
        expect(find.textContaining('m de você'), findsNothing);
      },
    );

    testWidgets(
      'mantém a localização visível mesmo quando há distância',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            distanceKm: 1.8,
            cep: 'São Paulo - SP',
          ),
        );

        expect(find.text('São Paulo - SP'), findsOneWidget);
        expect(find.text('1.8 km de você'), findsOneWidget);
      },
    );
  });
}