import 'package:frontend/trade_requests/models/trade_request.dart';

const testRequester = TradeUser(
  id: 'user-requester-1',
  name: 'Usuário Interessado',
  city: 'Campinas',
  state: 'SP',
);

const testRequestedBook = TradeBook(
  announcementId: 'announcement-target-1',
  title: 'Flores para Algernon',
  author: 'Daniel Keyes',
  publishYear: 2000,
  city: 'Campinas',
  state: 'SP',
  condition: 'Good',
);

const testOfferedBook1984 = TradeBook(
  announcementId: 'announcement-offered-1',
  title: '1984',
  author: 'George Orwell',
  publishYear: 2009,
  city: 'Santos',
  state: 'SP',
  condition: 'Used',
);

const testOfferedBookDescartes = TradeBook(
  announcementId: 'announcement-offered-2',
  title: 'Discurso do Método',
  author: 'René Descartes',
  publishYear: 2004,
  city: 'Campinas',
  state: 'SP',
  condition: 'Good',
);

TradeRequest buildTradeRequest({
  String id = 'offer-1',
  OfferStatus status = OfferStatus.pending,
  List<TradeBook> offeredBooks = const [
    testOfferedBook1984,
    testOfferedBookDescartes,
  ],
}) {
  return TradeRequest(
    id: id,
    requester: testRequester,
    requestedBook: testRequestedBook,
    offeredBooks: offeredBooks,
    status: status,
    createdAt: DateTime(2026, 7, 12, 10, 30),
  );
}

Map<String, dynamic> buildTradeRequestJson({
  String id = 'offer-1',
  String status = 'Pending',
}) {
  return <String, dynamic>{
    'id': id,
    'requester': <String, dynamic>{
      'id': 'user-requester-1',
      'name': 'Usuário Interessado',
      'city': 'Campinas',
      'state': 'SP',
      'photoUrl': null,
    },
    'requestedBook': <String, dynamic>{
      'announcementId': 'announcement-target-1',
      'title': 'Flores para Algernon',
      'author': 'Daniel Keyes',
      'publishYear': 2000,
      'city': 'Campinas',
      'state': 'SP',
      'condition': 'Good',
      'coverUrl': null,
    },
    'offeredBooks': <Map<String, dynamic>>[
      <String, dynamic>{
        'announcementId': 'announcement-offered-1',
        'title': '1984',
        'author': 'George Orwell',
        'publishYear': 2009,
        'city': 'Santos',
        'state': 'SP',
        'condition': 'Used',
        'coverUrl': null,
      },
      <String, dynamic>{
        'announcementId': 'announcement-offered-2',
        'title': 'Discurso do Método',
        'author': 'René Descartes',
        'publishYear': 2004,
        'city': 'Campinas',
        'state': 'SP',
        'condition': 'Good',
        'coverUrl': null,
      },
    ],
    'status': status,
    'createdAt': '2026-07-12T10:30:00.000',
  };
}
