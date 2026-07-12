import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/trade_requests/models/trade_request.dart';
import 'package:frontend/trade_requests/services/mock_trade_request_service.dart';
import 'package:frontend/trade_requests/services/trade_request_service.dart';

void main() {
  late MockTradeRequestService service;

  setUp(() {
    service = MockTradeRequestService(delay: Duration.zero);
  });

  test('retorna as solicitações mockadas', () async {
    final requests = await service.getReceivedRequests();

    expect(requests, hasLength(2));
    expect(requests.first.status, OfferStatus.pending);
    expect(requests.last.status, OfferStatus.rejected);
  });

  test('busca uma solicitação pelo id', () async {
    final request = await service.getRequestById('offer-001');

    expect(request.id, 'offer-001');
    expect(request.requestedBook.title, 'Flores para Algernon');
  });

  test('lança erro para solicitação inexistente', () {
    expect(
      () => service.getRequestById('missing'),
      throwsA(
        isA<TradeRequestServiceException>().having(
          (error) => error.message,
          'message',
          'Solicitação de troca não encontrada.',
        ),
      ),
    );
  });

  test('aceita uma solicitação pendente e persiste a atualização', () async {
    final updated = await service.acceptRequest('offer-001');
    final reloaded = await service.getRequestById('offer-001');

    expect(updated.status, OfferStatus.accepted);
    expect(reloaded.status, OfferStatus.accepted);
  });

  test('recusa uma solicitação pendente e persiste a atualização', () async {
    final updated = await service.rejectRequest('offer-001');
    final reloaded = await service.getRequestById('offer-001');

    expect(updated.status, OfferStatus.rejected);
    expect(reloaded.status, OfferStatus.rejected);
  });

  test('não permite responder uma solicitação já finalizada', () async {
    await expectLater(
      service.acceptRequest('offer-002'),
      throwsA(
        isA<TradeRequestServiceException>().having(
          (error) => error.message,
          'message',
          'Esta solicitação já foi respondida.',
        ),
      ),
    );
  });

  test('não permite responder a mesma solicitação duas vezes', () async {
    await service.acceptRequest('offer-001');

    await expectLater(
      service.rejectRequest('offer-001'),
      throwsA(isA<TradeRequestServiceException>()),
    );
  });
}
