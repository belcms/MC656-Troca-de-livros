import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/search/announcement_search_models.dart';
import 'package:frontend/search/final_search_results_screen.dart';
import 'dart:async';

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
  testWidgets('loads the first page and renders the grid', (tester) async {
    var calls = 0;
    final completer = Completer<AnnouncementSearchResponse>();

    Future<AnnouncementSearchResponse> fakeLoader({
      required String query,
      required int limit,
      required int offset,
    }) async {
      calls++;
      return completer.future;
    }

    await tester.pumpWidget(
      _testApp(
        FinalSearchResultsScreen(query: 'Harr', searchLoader: fakeLoader),
      ),
    );

    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const AnnouncementSearchResponse(
        total: 7,
        results: [
          AnnouncementSearchItem(
            id: '1',
            title: 'Flores para Algernon',
            publishYear: 2000,
            cep: '13000-000',
            realPhotoUrl: 'https://example.com/flores.jpg',
            condition: "New",
          ),
          AnnouncementSearchItem(
            id: '2',
            title: 'O tal do 1984',
            publishYear: 2000,
            cep: '13000-000',
            realPhotoUrl: 'https://example.com/1984.jpg',
            condition: "Worn",
          ),
          AnnouncementSearchItem(
            id: '3',
            title: 'O poder do hábito',
            publishYear: 2000,
            cep: '13000-000',
            realPhotoUrl: 'https://example.com/habito.jpg',
            condition: "New",
          ),
          AnnouncementSearchItem(
            id: '4',
            title: 'Mais um livro',
            publishYear: 2000,
            cep: '13000-000',
            realPhotoUrl: 'https://example.com/mais-um.jpg',
            condition: "Good",
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.text('Resultados'), findsOneWidget);
    expect(find.text('Encontramos 7 resultados para "Harr"'), findsOneWidget);
    expect(find.text('Flores para Algernon'), findsOneWidget);
    expect(find.text('Ver mais resultados'), findsOneWidget);
  });

  testWidgets('fetches a new query when submitted', (tester) async {
    final queries = <String>[];

    Future<AnnouncementSearchResponse> fakeLoader({
      required String query,
      required int limit,
      required int offset,
    }) async {
      queries.add(query);
      return AnnouncementSearchResponse(
        total: 1,
        results: [
          AnnouncementSearchItem(
            id: query,
            title: query,
            publishYear: 2000,
            cep: '13000-000',
            realPhotoUrl: 'https://example.com/$query.jpg',
            condition: "New",
          ),
        ],
      );
    }

    await tester.pumpWidget(
      _testApp(
        FinalSearchResultsScreen(query: 'Harr', searchLoader: fakeLoader),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Dune');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(queries.first, 'Harr');
    expect(queries.last, 'Dune');
    expect(find.text('Encontramos 1 resultados para "Dune"'), findsOneWidget);
  });

  testWidgets('requests the next page when scrolled near the bottom', (
    tester,
  ) async {
    final calls = <int>[];
    final scrollController = ScrollController();

    Future<AnnouncementSearchResponse> fakeLoader({
      required String query,
      required int limit,
      required int offset,
    }) async {
      calls.add(offset);
      return AnnouncementSearchResponse(
        total: 25,
        results: List.generate(
          20,
          (index) => AnnouncementSearchItem(
            id: 'id-$offset-$index',
            title: 'Book ${offset + index}',
            publishYear: 2000,
            cep: '13000-000',
            realPhotoUrl: 'https://example.com/book-$index.jpg',
            condition: "New",
          ),
        ),
      );
    }

    await tester.pumpWidget(
      _testApp(
        FinalSearchResultsScreen(
          query: 'Harr',
          searchLoader: fakeLoader,
          scrollController: scrollController,
        ),
      ),
    );

    await tester.pumpAndSettle();

    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(calls, contains(0));
    expect(calls, contains(20));
  });

  testWidgets('returns to the home screen when back is pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FinalSearchResultsScreen(
                        query: 'Harr',
                        searchLoader:
                            ({
                              required String query,
                              required int limit,
                              required int offset,
                            }) async => const AnnouncementSearchResponse(
                              total: 0,
                              results: [],
                            ),
                      ),
                    ),
                  );
                },
                child: const Text('Open search'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open search'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Open search'), findsOneWidget);
    expect(find.byType(FinalSearchResultsScreen), findsNothing);
  });
}
