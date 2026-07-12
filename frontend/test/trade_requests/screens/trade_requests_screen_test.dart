import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/trade_requests/models/trade_request.dart';
import 'package:frontend/trade_requests/screens/trade_requests_screen.dart';
import 'package:frontend/trade_requests/services/trade_request_service.dart';

import '../helpers/fake_trade_request_service.dart';
import '../helpers/trade_request_test_data.dart';

void main() {
  testWidgets('exibe indicador enquanto carrega', (tester) async {
    final completer = Completer<List<TradeRequest>>();
    final service = FakeTradeRequestService(
      onGetReceivedRequests: () => completer.future,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TradeRequestsScreen(service: service),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(<TradeRequest>[buildTradeRequest()]);
    await tester.pumpAndSettle();
  });

  testWidgets('lista solicitações recebidas', (tester) async {
    final service = FakeTradeRequestService(
      onGetReceivedRequests: () async => <TradeRequest>[
        buildTradeRequest(),
        buildTradeRequest(
          id: 'offer-2',
          status: OfferStatus.rejected,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TradeRequestsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Solicitações de troca'), findsOneWidget);
    expect(find.text('Flores para Algernon'), findsNWidgets(2));
    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Recusada'), findsOneWidget);
    expect(service.listCalls, 1);
  });

  testWidgets('exibe estado vazio', (tester) async {
    final service = FakeTradeRequestService(
      onGetReceivedRequests: () async => const <TradeRequest>[],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TradeRequestsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Você ainda não recebeu solicitações de troca.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
  });

  testWidgets('exibe erro e permite tentar novamente', (tester) async {
    var shouldFail = true;
    final service = FakeTradeRequestService(
      onGetReceivedRequests: () async {
        if (shouldFail) {
          throw const TradeRequestServiceException(
            'Falha simulada.',
          );
        }
        return <TradeRequest>[buildTradeRequest()];
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TradeRequestsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Falha simulada.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Flores para Algernon'), findsOneWidget);
    expect(service.listCalls, 2);
  });

  testWidgets('usa mensagem genérica para erro inesperado', (tester) async {
    final service = FakeTradeRequestService(
      onGetReceivedRequests: () async {
        throw StateError('unexpected');
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TradeRequestsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar as solicitações.'),
      findsOneWidget,
    );
  });

  testWidgets('abre detalhes ao tocar no card', (tester) async {
    final request = buildTradeRequest();
    final service = FakeTradeRequestService(
      onGetReceivedRequests: () async => <TradeRequest>[request],
      onGetRequestById: (id) async => request,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TradeRequestsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flores para Algernon'));
    await tester.pumpAndSettle();

    expect(find.text('Livros disponíveis'), findsOneWidget);
    expect(find.text('Usuário Interessado'), findsOneWidget);
    expect(service.lastDetailsId, 'offer-1');
  });

  testWidgets('recarrega a lista ao voltar dos detalhes', (tester) async {
    final request = buildTradeRequest();
    final service = FakeTradeRequestService(
      onGetReceivedRequests: () async => <TradeRequest>[request],
      onGetRequestById: (id) async => request,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TradeRequestsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flores para Algernon'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(service.listCalls, 2);
  });

  testWidgets('não apresenta overflow em tela móvel estreita', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final service = FakeTradeRequestService(
      onGetReceivedRequests: () async => <TradeRequest>[
        buildTradeRequest(),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TradeRequestsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
