import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/search/intermediate_search_screen.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF727272),
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    ),
    home: child,
  );
}

void main() {
  testWidgets('renders the mock search layout', (tester) async {
    await tester.pumpWidget(
      const _AppWrapper(child: IntermediateSearchScreen()),
    );

    expect(find.text('Resultados'), findsOneWidget);
    expect(find.text('Encontramos 7 resultados para "Harr"'), findsOneWidget);
    expect(find.byType(IntermediateSearchScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Ver mais resultados'), findsOneWidget);
    expect(find.byType(IntermediateSearchScreen), findsOneWidget);
    expect(find.text('Flores para Algernon'), findsOneWidget);
    expect(find.text('O tal do 1984'), findsOneWidget);
    expect(find.text('O poder do hábito'), findsOneWidget);
  });

  testWidgets('returns to the previous screen when back is pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IntermediateSearchScreen(),
                      ),
                    );
                  },
                  child: const Text('Open search'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open search'));
    await tester.pumpAndSettle();

    expect(find.byType(IntermediateSearchScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Open search'), findsOneWidget);
  });
}

class _AppWrapper extends StatelessWidget {
  const _AppWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF727272),
          ),
          titleMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      home: child,
    );
  }
}
