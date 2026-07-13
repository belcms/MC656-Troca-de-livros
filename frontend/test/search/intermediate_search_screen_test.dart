import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/book_details/announcement_detail_screen.dart';
import 'package:frontend/search/announcement_search_models.dart';
import 'package:frontend/search/final_search_results_screen.dart';
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
  testWidgets('debounces search requests before hitting the loader', (
    tester,
  ) async {
    var callCount = 0;

    Future<AnnouncementSearchResponse> fakeLoader({
      required String query,
      required int limit,
      required int offset,
    }) async {
      callCount++;
      return const AnnouncementSearchResponse(results: [], total: 0);
    }

    await tester.pumpWidget(
      _testApp(IntermediateSearchScreen(searchLoader: fakeLoader)),
    );

    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Har');
    await tester.pump(const Duration(milliseconds: 400));

    expect(callCount, 0);

    await tester.pump(const Duration(milliseconds: 200));

    expect(callCount, 1);
  });

  testWidgets('renders populated results from the API response', (
    tester,
  ) async {
    Future<AnnouncementSearchResponse> fakeLoader({
      required String query,
      required int limit,
      required int offset,
    }) async {
      return const AnnouncementSearchResponse(
        total: 7,
        results: [
          AnnouncementSearchItem(
            id: '1',
            title: 'Flores para Algernon',
            publishYear: 2000,
            cep: '13000-000',
            realPhotoUrl: 'https://example.com/flores.jpg',
          ),
          AnnouncementSearchItem(
            id: '2',
            title: 'O tal do 1984',
            publishYear: 2000,
            cep: '13000-000',
            realPhotoUrl: 'https://example.com/1984.jpg',
          ),
          AnnouncementSearchItem(
            id: '3',
            title: 'O poder do hábito',
            publishYear: 2000,
            cep: '13000-000',
            realPhotoUrl: 'https://example.com/habito.jpg',
          ),
          AnnouncementSearchItem(
            id: '4',
            title: 'Mais um livro',
            publishYear: 2000,
            cep: '13000-000',
            realPhotoUrl: 'https://example.com/mais-um.jpg',
          ),
        ],
      );
    }

    await tester.pumpWidget(
      _testApp(IntermediateSearchScreen(searchLoader: fakeLoader)),
    );

    await tester.enterText(find.byType(TextField), 'Harr');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Resultados'), findsOneWidget);
    expect(find.text('Encontramos 7 resultados para "Harr"'), findsOneWidget);
    expect(find.text('Flores para Algernon'), findsOneWidget);
    expect(find.text('O tal do 1984'), findsOneWidget);
    expect(find.text('O poder do hábito'), findsOneWidget);
    expect(find.text('Ver mais resultados'), findsOneWidget);
  });

  testWidgets('opens the announcement details screen when a result is tapped', (
    tester,
  ) async {
    Future<AnnouncementSearchResponse> fakeLoader({
      required String query,
      required int limit,
      required int offset,
    }) async {
      return const AnnouncementSearchResponse(
        total: 1,
        results: [
          AnnouncementSearchItem(
            id: 'announcement-1',
            title: 'Flores para Algernon',
            publishYear: 2000,
            cep: '13000-000',
            realPhotoUrl: 'https://example.com/flores.jpg',
          ),
        ],
      );
    }

    await tester.pumpWidget(
      _testApp(IntermediateSearchScreen(searchLoader: fakeLoader)),
    );

    await tester.enterText(find.byType(TextField), 'Har');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    await tester.tap(find.text('Flores para Algernon'));
    await tester.pumpAndSettle();

    expect(find.byType(IntermediateSearchScreen), findsNothing);
    expect(find.byType(AnnouncementDetailScreen), findsOneWidget);
  });

  testWidgets('opens the final results screen when Enter is pressed', (
    tester,
  ) async {
    Future<AnnouncementSearchResponse> fakeLoader({
      required String query,
      required int limit,
      required int offset,
    }) async {
      return const AnnouncementSearchResponse(
        total: 4,
        results: [
          AnnouncementSearchItem(
            id: '1',
            title: 'Flores para Algernon',
            publishYear: 2000,
            cep: '13000-000',
            realPhotoUrl: 'https://example.com/flores.jpg',
          ),
        ],
      );
    }

    await tester.pumpWidget(
      _testApp(IntermediateSearchScreen(searchLoader: fakeLoader)),
    );

    await tester.enterText(find.byType(TextField), 'Har');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.byType(IntermediateSearchScreen), findsNothing);
    expect(find.byType(FinalSearchResultsScreen), findsOneWidget);
  });

  testWidgets('shows the empty state for short queries and clears results', (
    tester,
  ) async {
    Future<AnnouncementSearchResponse> fakeLoader({
      required String query,
      required int limit,
      required int offset,
    }) async {
      return const AnnouncementSearchResponse(results: [], total: 0);
    }

    await tester.pumpWidget(
      _testApp(IntermediateSearchScreen(searchLoader: fakeLoader)),
    );

    await tester.enterText(find.byType(TextField), 'H');
    await tester.pump();

    expect(find.text('Nenhum livro encontrado.'), findsOneWidget);
    expect(find.text('Ver mais resultados'), findsNothing);
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
                        builder: (_) => IntermediateSearchScreen(
                          searchLoader:
                              ({
                                required String query,
                                required int limit,
                                required int offset,
                              }) async => const AnnouncementSearchResponse(
                                results: [],
                                total: 0,
                              ),
                        ),
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
