import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/auth/auth_repository.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/trade_requests/models/trade_request.dart';
import 'package:frontend/trade_requests/services/api_trade_request_service.dart';
import 'package:frontend/trade_requests/services/trade_request_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers/trade_request_test_data.dart';

void main() {
  const accessToken = 'access-token';

  group('ApiTradeRequestService', () {
    setUp(() {
      AuthRepository.instance.accessToken = accessToken;
      ApiClient.authTokenProvider = AuthRepository.instance;
    });

    tearDown(() {
      AuthRepository.instance.accessToken = null;
      ApiClient.authTokenProvider = null;
    });

    test('GET received usa URL e autenticação corretamente', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.origin, ApiClient.baseUrl);
        expect(request.url.path, '/api/v1/offers/received');
        expect(request.url.queryParameters, isEmpty);
        expect(request.headers['Accept'], 'application/json');
        expect(request.headers['Content-Type'], 'application/json');
        expect(request.headers['Authorization'], 'Bearer $accessToken');

        return http.Response(
          jsonEncode(<Map<String, dynamic>>[buildTradeRequestJson()]),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      });

      final service = ApiTradeRequestService(client: client);

      final requests = await service.getReceivedRequests();

      expect(requests, hasLength(1));
      expect(requests.single.id, 'offer-1');
      expect(requests.single.status, OfferStatus.pending);
    });

    test('GET details usa o id da solicitação', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/offers/offer-99');
        expect(request.url.queryParameters, isEmpty);

        return http.Response(
          jsonEncode(buildTradeRequestJson(id: 'offer-99')),
          200,
        );
      });

      final service = ApiTradeRequestService(client: client);

      final request = await service.getRequestById('offer-99');

      expect(request.id, 'offer-99');
    });

    test('PATCH accept usa endpoint correto e interpreta resposta', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/offers/offer-1/accept');
        expect(request.url.queryParameters, isEmpty);
        expect(request.headers['Authorization'], 'Bearer $accessToken');

        return http.Response(
          jsonEncode(buildTradeRequestJson(status: 'Accepted')),
          200,
        );
      });

      final service = ApiTradeRequestService(client: client);

      final request = await service.acceptRequest('offer-1');

      expect(request.status, OfferStatus.accepted);
    });

    test('PATCH reject usa endpoint correto e interpreta resposta', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/offers/offer-1/reject');
        expect(request.url.queryParameters, isEmpty);

        return http.Response(
          jsonEncode(buildTradeRequestJson(status: 'Rejected')),
          200,
        );
      });

      final service = ApiTradeRequestService(client: client);

      final request = await service.rejectRequest('offer-1');

      expect(request.status, OfferStatus.rejected);
    });

    test('propaga detail retornado pelo backend', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'detail': 'Apenas solicitações pendentes podem ser respondidas.',
          }),
          409,
        );
      });

      final service = ApiTradeRequestService(client: client);

      await expectLater(
        service.acceptRequest('offer-1'),
        throwsA(
          isA<TradeRequestServiceException>().having(
            (error) => error.message,
            'message',
            'Apenas solicitações pendentes podem ser respondidas.',
          ),
        ),
      );
    });

    test('usa mensagem padrão quando erro não é JSON', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ApiTradeRequestService(client: client);

      await expectLater(
        service.getRequestById('offer-1'),
        throwsA(
          isA<TradeRequestServiceException>().having(
            (error) => error.message,
            'message',
            'Erro 500 ao acessar o servidor.',
          ),
        ),
      );
    });

    test('rejeita lista com formato inválido', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{'id': 'not-a-list'}),
          200,
        );
      });

      final service = ApiTradeRequestService(client: client);

      await expectLater(
        service.getReceivedRequests(),
        throwsA(
          isA<TradeRequestServiceException>().having(
            (error) => error.message,
            'message',
            contains('formato inválido'),
          ),
        ),
      );
    });

    test('rejeita resposta de detalhes que não seja objeto', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode(<dynamic>[]), 200);
      });

      final service = ApiTradeRequestService(client: client);

      await expectLater(
        service.getRequestById('offer-1'),
        throwsA(isA<TradeRequestServiceException>()),
      );
    });

    test('rejeita resposta 200 que não seja JSON', () async {
      final client = MockClient((request) async {
        return http.Response('not-json', 200);
      });

      final service = ApiTradeRequestService(client: client);

      await expectLater(
        service.getReceivedRequests(),
        throwsA(
          isA<TradeRequestServiceException>().having(
            (error) => error.message,
            'message',
            'O servidor retornou uma resposta que não é JSON.',
          ),
        ),
      );
    });
  });
}
