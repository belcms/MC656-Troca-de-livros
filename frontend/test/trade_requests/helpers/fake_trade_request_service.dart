import 'package:frontend/trade_requests/models/trade_request.dart';
import 'package:frontend/trade_requests/services/trade_request_service.dart';

typedef ListRequestsHandler = Future<List<TradeRequest>> Function();
typedef RequestHandler = Future<TradeRequest> Function(String requestId);

class FakeTradeRequestService implements TradeRequestService {
  FakeTradeRequestService({
    ListRequestsHandler? onGetReceivedRequests,
    RequestHandler? onGetRequestById,
    RequestHandler? onAcceptRequest,
    RequestHandler? onRejectRequest,
  })  : _onGetReceivedRequests = onGetReceivedRequests,
        _onGetRequestById = onGetRequestById,
        _onAcceptRequest = onAcceptRequest,
        _onRejectRequest = onRejectRequest;

  final ListRequestsHandler? _onGetReceivedRequests;
  final RequestHandler? _onGetRequestById;
  final RequestHandler? _onAcceptRequest;
  final RequestHandler? _onRejectRequest;

  int listCalls = 0;
  int detailsCalls = 0;
  int acceptCalls = 0;
  int rejectCalls = 0;

  String? lastDetailsId;
  String? lastAcceptedId;
  String? lastRejectedId;

  @override
  Future<List<TradeRequest>> getReceivedRequests() {
    listCalls += 1;
    final handler = _onGetReceivedRequests;
    if (handler == null) {
      return Future<List<TradeRequest>>.value(const <TradeRequest>[]);
    }
    return handler();
  }

  @override
  Future<TradeRequest> getRequestById(String requestId) {
    detailsCalls += 1;
    lastDetailsId = requestId;
    final handler = _onGetRequestById;
    if (handler == null) {
      return Future<TradeRequest>.error(
        const TradeRequestServiceException(
          'Solicitação de troca não encontrada.',
        ),
      );
    }
    return handler(requestId);
  }

  @override
  Future<TradeRequest> acceptRequest(String requestId) {
    acceptCalls += 1;
    lastAcceptedId = requestId;
    final handler = _onAcceptRequest;
    if (handler == null) {
      return Future<TradeRequest>.error(
        const TradeRequestServiceException(
          'Não foi possível aceitar a solicitação.',
        ),
      );
    }
    return handler(requestId);
  }

  @override
  Future<TradeRequest> rejectRequest(String requestId) {
    rejectCalls += 1;
    lastRejectedId = requestId;
    final handler = _onRejectRequest;
    if (handler == null) {
      return Future<TradeRequest>.error(
        const TradeRequestServiceException(
          'Não foi possível recusar a solicitação.',
        ),
      );
    }
    return handler(requestId);
  }
}
