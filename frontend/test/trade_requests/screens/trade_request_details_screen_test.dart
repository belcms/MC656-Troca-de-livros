import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/trade_requests/models/trade_request.dart';
import 'package:frontend/trade_requests/screens/trade_request_details_screen.dart';
import 'package:frontend/trade_requests/services/trade_request_service.dart';

import '../helpers/fake_trade_request_service.dart';
import '../helpers/trade_request_test_data.dart';

Future<void> pumpDetails(
  WidgetTester tester, {
  required FakeTradeRequestService service,
  String requestId = 'offer-1',
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: TradeRequestDetailsScreen(
        requestId: requestId,
        service: service,
      ),
    ),
  );
}

void main() {
  testWidgets('exibe indicador enquanto carrega detalhes', (tester) async {
    final completer = Completer<TradeRequest>();
    final service = FakeTradeRequestService(
      onGetRequestById: (id) => completer.future,
    );

    await pumpDetails(tester, service: service);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(buildTradeRequest());
    await tester.pumpAndSettle();
  });

  testWidgets('exibe usuário, livro solicitado e livros oferecidos',
      (tester) async {
    final service = FakeTradeRequestService(
      onGetRequestById: (id) async => buildTradeRequest(),
    );

    await pumpDetails(tester, service: service);
    await tester.pumpAndSettle();

    expect(find.text('Usuário Interessado'), findsOneWidget);
    expect(find.text('Flores para Algernon'), findsOneWidget);
    expect(find.text('Livros disponíveis'), findsOneWidget);
    expect(find.text('1984'), findsOneWidget);
    expect(find.text('Discurso do Método'), findsOneWidget);
    expect(find.text('Aceitar proposta'), findsOneWidget);
    expect(find.text('Recusar proposta'), findsOneWidget);
  });

  testWidgets('exibe estado vazio quando nenhum livro foi oferecido',
      (tester) async {
    final service = FakeTradeRequestService(
      onGetRequestById: (id) async => buildTradeRequest(
        offeredBooks: const <TradeBook>[],
      ),
    );

    await pumpDetails(tester, service: service);
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum livro foi oferecido para esta troca.'),
      findsOneWidget,
    );
  });

  testWidgets('proposta finalizada esconde ações e mostra status',
      (tester) async {
    final service = FakeTradeRequestService(
      onGetRequestById: (id) async => buildTradeRequest(
        status: OfferStatus.accepted,
      ),
    );

    await pumpDetails(tester, service: service);
    await tester.pumpAndSettle();

    expect(find.text('Aceitar proposta'), findsNothing);
    expect(find.text('Recusar proposta'), findsNothing);
    expect(find.text('Status da solicitação'), findsOneWidget);
    expect(find.text('Aceita'), findsOneWidget);
  });

  testWidgets('cancelar diálogo de aceite não chama o serviço', (tester) async {
    final request = buildTradeRequest();
    final service = FakeTradeRequestService(
      onGetRequestById: (id) async => request,
      onAcceptRequest: (id) async =>
          request.copyWith(status: OfferStatus.accepted),
    );

    await pumpDetails(tester, service: service);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aceitar proposta'));
    await tester.pumpAndSettle();

    expect(find.text('Aceitar proposta?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(service.acceptCalls, 0);
    expect(find.text('Aceitar proposta'), findsOneWidget);
  });

  testWidgets('aceita proposta após confirmação', (tester) async {
    final request = buildTradeRequest();
    final service = FakeTradeRequestService(
      onGetRequestById: (id) async => request,
      onAcceptRequest: (id) async =>
          request.copyWith(status: OfferStatus.accepted),
    );

    await pumpDetails(tester, service: service);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aceitar proposta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Aceitar'));
    await tester.pumpAndSettle();

    expect(service.acceptCalls, 1);
    expect(service.lastAcceptedId, 'offer-1');
    expect(find.text('Proposta aceita com sucesso.'), findsOneWidget);
    expect(find.text('Aceita'), findsOneWidget);
    expect(find.text('Aceitar proposta'), findsNothing);
    expect(find.text('Recusar proposta'), findsNothing);
  });

  testWidgets('recusa proposta após confirmação', (tester) async {
    final request = buildTradeRequest();
    final service = FakeTradeRequestService(
      onGetRequestById: (id) async => request,
      onRejectRequest: (id) async =>
          request.copyWith(status: OfferStatus.rejected),
    );

    await pumpDetails(tester, service: service);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recusar proposta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Recusar'));
    await tester.pumpAndSettle();

    expect(service.rejectCalls, 1);
    expect(service.lastRejectedId, 'offer-1');
    expect(find.text('Proposta recusada com sucesso.'), findsOneWidget);
    expect(find.text('Recusada'), findsOneWidget);
    expect(find.text('Aceitar proposta'), findsNothing);
  });

  testWidgets('mostra erro do serviço e mantém proposta pendente',
      (tester) async {
    final request = buildTradeRequest();
    final service = FakeTradeRequestService(
      onGetRequestById: (id) async => request,
      onAcceptRequest: (id) async {
        throw const TradeRequestServiceException(
          'Falha ao aceitar.',
        );
      },
    );

    await pumpDetails(tester, service: service);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aceitar proposta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Aceitar'));
    await tester.pumpAndSettle();

    expect(find.text('Falha ao aceitar.'), findsOneWidget);
    expect(find.text('Aceitar proposta'), findsOneWidget);
    expect(find.text('Recusar proposta'), findsOneWidget);
  });

  testWidgets('desabilita ações durante o processamento', (tester) async {
    final request = buildTradeRequest();
    final completer = Completer<TradeRequest>();
    final service = FakeTradeRequestService(
      onGetRequestById: (id) async => request,
      onAcceptRequest: (id) => completer.future,
    );

    await pumpDetails(tester, service: service);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aceitar proposta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Aceitar'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final actionButtons = tester.widgetList<FilledButton>(
      find.byType(FilledButton),
    );
    expect(
      actionButtons.where((button) => button.onPressed == null).length,
      greaterThanOrEqualTo(2),
    );

    completer.complete(
      request.copyWith(status: OfferStatus.accepted),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('exibe erro de carregamento e permite tentar novamente',
      (tester) async {
    var shouldFail = true;
    final service = FakeTradeRequestService(
      onGetRequestById: (id) async {
        if (shouldFail) {
          throw const TradeRequestServiceException(
            'Falha no carregamento.',
          );
        }
        return buildTradeRequest();
      },
    );

    await pumpDetails(tester, service: service);
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar esta solicitação.'),
      findsOneWidget,
    );

    shouldFail = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Livros disponíveis'), findsOneWidget);
    expect(service.detailsCalls, 2);
  });

  testWidgets('não apresenta overflow em tela móvel estreita', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final service = FakeTradeRequestService(
      onGetRequestById: (id) async => buildTradeRequest(),
    );

    await pumpDetails(tester, service: service);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
