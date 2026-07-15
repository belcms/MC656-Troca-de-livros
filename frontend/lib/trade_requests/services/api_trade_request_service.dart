import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/api_client.dart';
import '../models/trade_request.dart';
import 'trade_request_service.dart';

class ApiTradeRequestService implements TradeRequestService {
  ApiTradeRequestService({http.Client? client}) : _client = client;

  final http.Client? _client;

  @override
  Future<List<TradeRequest>> getReceivedRequests() async {
    final response = await ApiClient.get(
      '/api/v1/offers/received',
      client: _client,
    );
    _ensureSuccess(response);

    final decoded = _decodeJson(response);
    if (decoded is! List) {
      throw const TradeRequestServiceException(
        'A API retornou um formato inválido para a lista de solicitações.',
      );
    }

    try {
      return decoded
          .map(
            (item) =>
                TradeRequest.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);
    } on FormatException catch (error) {
      throw TradeRequestServiceException(
        'Não foi possível interpretar os dados da API: ${error.message}',
      );
    }
  }

  @override
  Future<TradeRequest> getRequestById(String requestId) async {
    final response = await ApiClient.get(
      '/api/v1/offers/$requestId',
      client: _client,
    );
    return _parseTradeRequest(response);
  }

  @override
  Future<TradeRequest> acceptRequest(String requestId) async {
    final response = await ApiClient.patch(
      '/api/v1/offers/$requestId/accept',
      client: _client,
    );
    return _parseTradeRequest(response);
  }

  @override
  Future<TradeRequest> rejectRequest(String requestId) async {
    final response = await ApiClient.patch(
      '/api/v1/offers/$requestId/reject',
      client: _client,
    );
    return _parseTradeRequest(response);
  }

  TradeRequest _parseTradeRequest(http.Response response) {
    _ensureSuccess(response);
    final decoded = _decodeJson(response);

    if (decoded is! Map) {
      throw const TradeRequestServiceException(
        'A API retornou um formato inválido para a solicitação.',
      );
    }

    try {
      return TradeRequest.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException catch (error) {
      throw TradeRequestServiceException(
        'Não foi possível interpretar os dados da API: ${error.message}',
      );
    }
  }

  Object? _decodeJson(http.Response response) {
    final body = response.body.trim();

    if (body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } on FormatException {
      throw const TradeRequestServiceException(
        'O servidor retornou uma resposta que não é JSON.',
      );
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    var message = 'Erro ${response.statusCode} ao acessar o servidor.';

    final body = response.body.trim();

    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);

        if (decoded is Map) {
          message =
              decoded['detail']?.toString() ??
              decoded['message']?.toString() ??
              message;
        }
      } on FormatException {
        // Mantém a mensagem padrão quando a resposta não é JSON.
      }
    }

    throw TradeRequestServiceException(message);
  }

  void dispose() {
    _client?.close();
  }
}
