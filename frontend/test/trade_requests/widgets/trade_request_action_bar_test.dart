import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/trade_requests/widgets/trade_request_action_bar.dart';

void main() {
  testWidgets('exibe botões de aceitar e recusar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TradeRequestActionBar(
            isLoading: false,
            onReject: () {},
            onAccept: () {},
          ),
        ),
      ),
    );

    expect(find.text('Recusar proposta'), findsOneWidget);
    expect(find.text('Aceitar proposta'), findsOneWidget);
  });

  testWidgets('executa os callbacks', (tester) async {
    var acceptCalls = 0;
    var rejectCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TradeRequestActionBar(
            isLoading: false,
            onReject: () => rejectCalls += 1,
            onAccept: () => acceptCalls += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Recusar proposta'));
    await tester.tap(find.text('Aceitar proposta'));

    expect(rejectCalls, 1);
    expect(acceptCalls, 1);
  });

  testWidgets('desabilita ações e mostra loading durante envio', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TradeRequestActionBar(
            isLoading: true,
            onReject: () {},
            onAccept: () {},
          ),
        ),
      ),
    );

    final buttons = tester.widgetList<FilledButton>(
      find.byType(FilledButton),
    );

    expect(buttons.every((button) => button.onPressed == null), isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Aceitar proposta'), findsNothing);
  });
}
