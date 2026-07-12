import '../models/trade_request.dart';

abstract class TradeRequestService {
  Future<List<TradeRequest>> getReceivedRequests();

  Future<TradeRequest> getRequestById(String requestId);

  Future<TradeRequest> acceptRequest(String requestId);

  Future<TradeRequest> rejectRequest(String requestId);
}

class TradeRequestServiceException implements Exception {
  const TradeRequestServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
