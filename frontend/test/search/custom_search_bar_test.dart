import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/search/widgets/custom_search_bar.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF727272),
        ),
      ),
    ),
    home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
  );
}

void main() {
  testWidgets('hides the clear action until text is entered', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      _testApp(
        CustomSearchBar(
          controller: controller,
          onChanged: (_) {},
          onSubmitted: (_) {},
          onClear: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.close), findsNothing);

    await tester.enterText(find.byType(TextField), 'Harr');
    await tester.pump();

    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('clears text and notifies callbacks when tapped', (tester) async {
    final controller = TextEditingController(text: 'Harr');
    var clearCount = 0;
    String? lastChangedValue;

    await tester.pumpWidget(
      _testApp(
        CustomSearchBar(
          controller: controller,
          onChanged: (value) => lastChangedValue = value,
          onSubmitted: (_) {},
          onClear: () => clearCount++,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(clearCount, 1);
    expect(lastChangedValue, isEmpty);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('forwards submitted text', (tester) async {
    final controller = TextEditingController(text: 'Harr');
    String? submittedValue;

    await tester.pumpWidget(
      _testApp(
        CustomSearchBar(
          controller: controller,
          onChanged: (_) {},
          onSubmitted: (value) => submittedValue = value,
          onClear: () {},
        ),
      ),
    );

    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(submittedValue, 'Harr');
  });

  testWidgets('acts as a launcher when readOnly and onTap are provided', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      _testApp(
        CustomSearchBar(
          readOnly: true,
          onTap: () => tapped = true,
          onChanged: (_) {},
          onSubmitted: (_) {},
          onClear: () {},
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(tapped, isTrue);
  });
}