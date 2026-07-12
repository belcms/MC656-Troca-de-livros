import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trade_request.dart';
import 'trade_request_service.dart';

class ApiTradeRequestService implements TradeRequestService {
  ApiTradeRequestService({
    required this.baseUrl,
    required this.currentUserId,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String currentUserId;
  final http.Client _client;

  String get _normalizedBaseUrl =>
      baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  void _validateConfiguration() {
    if (currentUserId.trim().isEmpty) {
      throw const TradeRequestServiceException(
        'CURRENT_USER_ID não foi configurado. '
        'Execute o Flutter com --dart-define=CURRENT_USER_ID=<uuid>.',
      );
    }
  }

  @override
  Future<List<TradeRequest>> getReceivedRequests() async {
    _validateConfiguration();

    final uri = Uri.parse('$_normalizedBaseUrl/api/v1/offers/received')
        .replace(queryParameters: {'owner_user_id': currentUserId});

    final response = await _client.get(uri, headers: _headers);
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
            (item) => TradeRequest.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
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
    _validateConfiguration();

    final uri = Uri.parse(
      '$_normalizedBaseUrl/api/v1/offers/$requestId',
    ).replace(queryParameters: {'owner_user_id': currentUserId});

    final response = await _client.get(uri, headers: _headers);
    return _parseTradeRequest(response);
  }

  @override
  Future<TradeRequest> acceptRequest(String requestId) async {
    _validateConfiguration();

    final uri = Uri.parse(
      '$_normalizedBaseUrl/api/v1/offers/$requestId/accept',
    ).replace(queryParameters: {'owner_user_id': currentUserId});

    final response = await _client.patch(uri, headers: _headers);
    return _parseTradeRequest(response);
  }

  @override
  Future<TradeRequest> rejectRequest(String requestId) async {
    _validateConfiguration();

    final uri = Uri.parse(
      '$_normalizedBaseUrl/api/v1/offers/$requestId/reject',
    ).replace(queryParameters: {'owner_user_id': currentUserId});

    final response = await _client.patch(uri, headers: _headers);
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
      return TradeRequest.fromJson(
        Map<String, dynamic>.from(decoded),
      );
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
  if (response.statusCode >= 200 &&
      response.statusCode < 300) {
    return;
  }

  var message =
      'Erro ${response.statusCode} ao acessar o servidor.';

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
    _client.close();
  }
}
