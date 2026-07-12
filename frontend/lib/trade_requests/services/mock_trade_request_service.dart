import '../models/trade_request.dart';
import 'trade_request_service.dart';

class MockTradeRequestService implements TradeRequestService {
  MockTradeRequestService({
    this.delay = const Duration(milliseconds: 500),
  }) : _requests = _createMockRequests();

  final Duration delay;
  final List<TradeRequest> _requests;

  @override
  Future<List<TradeRequest>> getReceivedRequests() async {
    await Future<void>.delayed(delay);
    return List<TradeRequest>.unmodifiable(_requests);
  }

  @override
  Future<TradeRequest> getRequestById(String requestId) async {
    await Future<void>.delayed(delay);
    return _findById(requestId);
  }

  @override
  Future<TradeRequest> acceptRequest(String requestId) async {
    await Future<void>.delayed(delay);
    final request = _findById(requestId);
    _ensurePending(request);

    final updated = request.copyWith(status: OfferStatus.accepted);
    _replace(updated);
    return updated;
  }

  @override
  Future<TradeRequest> rejectRequest(String requestId) async {
    await Future<void>.delayed(delay);
    final request = _findById(requestId);
    _ensurePending(request);

    final updated = request.copyWith(status: OfferStatus.rejected);
    _replace(updated);
    return updated;
  }

  TradeRequest _findById(String requestId) {
    try {
      return _requests.firstWhere((request) => request.id == requestId);
    } on StateError {
      throw const TradeRequestServiceException(
        'Solicitação de troca não encontrada.',
      );
    }
  }

  void _ensurePending(TradeRequest request) {
    if (!request.isPending) {
      throw const TradeRequestServiceException(
        'Esta solicitação já foi respondida.',
      );
    }
  }

  void _replace(TradeRequest updated) {
    final index = _requests.indexWhere((item) => item.id == updated.id);
    _requests[index] = updated;
  }

  static List<TradeRequest> _createMockRequests() {
    const requester = TradeUser(
      id: 'user-neymar',
      name: 'Neymar Jr.',
      city: 'Santos',
      state: 'SP',
      photoUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500',
    );

    const requestedBook = TradeBook(
      announcementId: 'announcement-algernon',
      title: 'Flores para Algernon',
      author: 'Daniel Keyes',
      publishYear: 2000,
      city: 'Campinas',
      state: 'SP',
      condition: 'Bom',
      coverUrl:
          'https://covers.openlibrary.org/b/isbn/9788576573937-L.jpg',
    );

    const offered1984 = TradeBook(
      announcementId: 'announcement-1984',
      title: '1984',
      author: 'George Orwell',
      publishYear: 2009,
      city: 'Santos',
      state: 'SP',
      condition: 'Usado',
      coverUrl:
          'https://covers.openlibrary.org/b/isbn/9780451524935-L.jpg',
    );

    const offeredDescartes = TradeBook(
      announcementId: 'announcement-descartes',
      title: 'Descartes',
      author: 'Tom Sorell',
      publishYear: 2004,
      city: 'Campinas',
      state: 'SP',
      condition: 'Bom',
      coverUrl:
          'https://covers.openlibrary.org/b/isbn/9780192876272-L.jpg',
    );

    const offeredMetamorphosis = TradeBook(
      announcementId: 'announcement-metamorphosis',
      title: 'A Metamorfose',
      author: 'Franz Kafka',
      publishYear: 2018,
      city: 'Santos',
      state: 'SP',
      condition: 'Novo',
      coverUrl:
          'https://covers.openlibrary.org/b/isbn/9788594318788-L.jpg',
    );

    return [
      TradeRequest(
        id: 'offer-001',
        requester: requester,
        requestedBook: requestedBook,
        offeredBooks: const [
          offered1984,
          offeredDescartes,
          offeredMetamorphosis,
        ],
        status: OfferStatus.pending,
        createdAt: DateTime(2026, 7, 11, 10, 30),
      ),
      TradeRequest(
        id: 'offer-002',
        requester: const TradeUser(
          id: 'user-julia',
          name: 'Júlia Martins',
          city: 'Campinas',
          state: 'SP',
          photoUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500',
        ),
        requestedBook: const TradeBook(
          announcementId: 'announcement-1984-target',
          title: '1984',
          author: 'George Orwell',
          publishYear: 2000,
          city: 'Campinas',
          state: 'SP',
          condition: 'Bom',
          coverUrl:
              'https://covers.openlibrary.org/b/isbn/9780451524935-L.jpg',
        ),
        offeredBooks: const [offeredDescartes],
        status: OfferStatus.rejected,
        createdAt: DateTime(2026, 7, 9, 14, 15),
      ),
    ];
  }
}
