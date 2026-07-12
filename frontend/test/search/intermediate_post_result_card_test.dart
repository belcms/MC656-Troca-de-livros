import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/search/widgets/intermediate_post_result_card.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      textTheme: const TextTheme(
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF727272),
        ),
      ),
    ),
    home: Scaffold(
      body: Center(child: SizedBox(width: 700, child: child)),
    ),
  );
}

void main() {
  testWidgets('renders title and metadata with the expected typography', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const IntermediatePostResultCard(
          title: 'Flores para Algernon',
          publishYear: '2000',
          location: 'Campinas - SP',
          photoUrl: 'https://example.com/cover.jpg',
        ),
      ),
    );

    expect(find.text('Flores para Algernon'), findsOneWidget);
    expect(find.text('2000'), findsOneWidget);
    expect(find.text('Campinas - SP'), findsOneWidget);

    final titleText = tester.widget<Text>(find.text('Flores para Algernon'));
    expect(titleText.maxLines, 2);
    expect(titleText.overflow, TextOverflow.ellipsis);
    expect(titleText.style?.fontSize, 15);
    expect(titleText.style?.fontWeight, FontWeight.w700);

    final detailText = tester.widget<Text>(find.text('2000'));
    expect(detailText.style?.fontSize, 12);
    expect(detailText.style?.fontWeight, FontWeight.w400);
    expect(detailText.style?.color, const Color(0xFF727272));
  });

  testWidgets('exposes an optional tap action', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      _testApp(
        IntermediatePostResultCard(
          title: '1984',
          publishYear: '2000',
          location: 'Campinas - SP',
          photoUrl: 'https://example.com/cover.jpg',
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
