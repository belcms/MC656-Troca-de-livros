import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/trade_requests/models/trade_request.dart';

import 'helpers/trade_request_test_data.dart';

void main() {
  group('OfferStatusPresentation', () {
    test('retorna os rótulos em português', () {
      expect(OfferStatus.pending.label, 'Pendente');
      expect(OfferStatus.accepted.label, 'Aceita');
      expect(OfferStatus.rejected.label, 'Recusada');
      expect(OfferStatus.canceled.label, 'Cancelada');
    });

    test('converte valores da API ignorando maiúsculas e minúsculas', () {
      expect(
        OfferStatusPresentation.fromJson('PENDING'),
        OfferStatus.pending,
      );
      expect(
        OfferStatusPresentation.fromJson('Accepted'),
        OfferStatus.accepted,
      );
      expect(
        OfferStatusPresentation.fromJson('rejected'),
        OfferStatus.rejected,
      );
      expect(
        OfferStatusPresentation.fromJson('cancelled'),
        OfferStatus.canceled,
      );
    });

    test('lança FormatException para status desconhecido', () {
      expect(
        () => OfferStatusPresentation.fromJson('unknown'),
        throwsA(isA<FormatException>()),
      );
    });

    test('serializa os status no formato do backend', () {
      expect(OfferStatus.pending.toJson(), 'Pending');
      expect(OfferStatus.accepted.toJson(), 'Accepted');
      expect(OfferStatus.rejected.toJson(), 'Rejected');
      expect(OfferStatus.canceled.toJson(), 'Canceled');
    });
  });

  group('TradeUser e TradeBook', () {
    test('montam a localização corretamente', () {
      expect(testRequester.location, 'Campinas - SP');

      const onlyCity = TradeUser(
        id: '1',
        name: 'A',
        city: 'Campinas',
        state: '',
      );
      expect(onlyCity.location, 'Campinas');

      const onlyState = TradeUser(
        id: '2',
        name: 'B',
        city: '',
        state: 'SP',
      );
      expect(onlyState.location, 'SP');

      const noLocation = TradeUser(
        id: '3',
        name: 'C',
        city: '',
        state: '',
      );
      expect(noLocation.location, '');
    });

    test('aplica fallback de nome e título', () {
      final user = TradeUser.fromJson(<String, dynamic>{
        'id': 'user-1',
      });
      final book = TradeBook.fromJson(<String, dynamic>{
        'id': 'announcement-1',
      });

      expect(user.name, 'Usuário');
      expect(book.title, 'Livro sem título');
      expect(book.publishYear, 0);
    });
  });

  group('TradeRequest.fromJson', () {
    test('converte resposta camelCase completa', () {
      final request = TradeRequest.fromJson(buildTradeRequestJson());

      expect(request.id, 'offer-1');
      expect(request.requester.name, 'Usuário Interessado');
      expect(request.requestedBook.title, 'Flores para Algernon');
      expect(request.offeredBooks, hasLength(2));
      expect(request.offeredBooks.first.title, '1984');
      expect(request.status, OfferStatus.pending);
      expect(request.isPending, isTrue);
      expect(request.createdAt, DateTime(2026, 7, 12, 10, 30));
    });

    test('aceita nomes de campos snake_case', () {
      final request = TradeRequest.fromJson(<String, dynamic>{
        'id': 'offer-snake',
        'user': <String, dynamic>{
          'id': 'user-1',
          'name': 'João',
          'city': 'Santos',
          'state': 'SP',
          'photo_url': 'photo.jpg',
        },
        'target_announcement': <String, dynamic>{
          'announcement_id': 'target-1',
          'title': 'Duna',
          'author': 'Frank Herbert',
          'publish_year': 2017,
          'city': 'Campinas',
          'state': 'SP',
          'condition': 'Good',
          'cover_url': 'cover.jpg',
        },
        'offered_announcements': <Map<String, dynamic>>[
          <String, dynamic>{
            'announcement_id': 'offered-1',
            'title': 'O Hobbit',
            'author': 'J. R. R. Tolkien',
            'publish_year': 2019,
            'city': 'Santos',
            'state': 'SP',
            'condition': 'New',
          },
        ],
        'status_offer': 'Rejected',
        'created_at': '2026-07-10T08:00:00',
      });

      expect(request.id, 'offer-snake');
      expect(request.requester.photoUrl, 'photo.jpg');
      expect(request.requestedBook.announcementId, 'target-1');
      expect(request.offeredBooks.single.title, 'O Hobbit');
      expect(request.status, OfferStatus.rejected);
    });

    test('usa epoch quando createdAt é inválido', () {
      final json = buildTradeRequestJson();
      json['createdAt'] = 'invalid-date';

      final request = TradeRequest.fromJson(json);

      expect(
        request.createdAt,
        DateTime.fromMillisecondsSinceEpoch(0),
      );
    });

    test('lança erro quando offeredBooks não é lista', () {
      final json = buildTradeRequestJson();
      json['offeredBooks'] = 'invalid';

      expect(
        () => TradeRequest.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('lança erro quando requester não é mapa', () {
      final json = buildTradeRequestJson();
      json['requester'] = 'invalid';

      expect(
        () => TradeRequest.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('TradeRequest.copyWith e toJson', () {
    test('altera apenas os campos informados', () {
      final pending = buildTradeRequest();
      final accepted = pending.copyWith(status: OfferStatus.accepted);

      expect(accepted.id, pending.id);
      expect(accepted.requester, pending.requester);
      expect(accepted.status, OfferStatus.accepted);
      expect(accepted.isPending, isFalse);
    });

    test('serializa a solicitação', () {
      final json = buildTradeRequest().toJson();

      expect(json['id'], 'offer-1');
      expect(json['status'], 'Pending');
      expect(json['requester'], isA<Map>());
      expect(json['requestedBook'], isA<Map>());
      expect(json['offeredBooks'], isA<List>());
    });
  });
}
