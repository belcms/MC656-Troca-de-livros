import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/trade_requests/widgets/trade_request_card.dart';

import '../helpers/trade_request_test_data.dart';

void main() {
  testWidgets('exibe os dados principais da solicitação', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TradeRequestCard(
            request: buildTradeRequest(),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Flores para Algernon'), findsOneWidget);
    expect(find.text('2000'), findsOneWidget);
    expect(find.text('Campinas - SP'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('todo o card executa onTap', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TradeRequestCard(
            request: buildTradeRequest(),
            onTap: () => taps += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));

    expect(taps, 1);
  });

  testWidgets('usa ícone de fallback quando não há capa', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TradeRequestCard(
            request: buildTradeRequest(),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
  });

  testWidgets('não gera overflow em tela estreita', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TradeRequestCard(
            request: buildTradeRequest(),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
