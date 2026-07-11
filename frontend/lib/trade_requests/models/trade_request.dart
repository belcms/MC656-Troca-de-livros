enum OfferStatus {
  pending,
  accepted,
  rejected,
  canceled,
}

extension OfferStatusPresentation on OfferStatus {
  String get label {
    switch (this) {
      case OfferStatus.pending:
        return 'Pendente';
      case OfferStatus.accepted:
        return 'Aceita';
      case OfferStatus.rejected:
        return 'Recusada';
      case OfferStatus.canceled:
        return 'Cancelada';
    }
  }

  static OfferStatus fromJson(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return OfferStatus.pending;
      case 'ACCEPTED':
        return OfferStatus.accepted;
      case 'REJECTED':
        return OfferStatus.rejected;
      case 'CANCELED':
      case 'CANCELLED':
        return OfferStatus.canceled;
      default:
        throw FormatException('Status de oferta inválido: $value');
    }
  }

  String toJson() {
    switch (this) {
      case OfferStatus.pending:
        return 'PENDING';
      case OfferStatus.accepted:
        return 'ACCEPTED';
      case OfferStatus.rejected:
        return 'REJECTED';
      case OfferStatus.canceled:
        return 'CANCELED';
    }
  }
}

class TradeUser {
  const TradeUser({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String city;
  final String state;
  final String? photoUrl;

  String get location => '$city - $state';

  factory TradeUser.fromJson(Map<String, dynamic> json) {
    return TradeUser(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      state: (json['state'] as String?) ?? '',
      photoUrl: json['photo_url'] as String? ?? json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'state': state,
        'photo_url': photoUrl,
      };
}

class TradeBook {
  const TradeBook({
    required this.announcementId,
    required this.title,
    required this.author,
    required this.publishYear,
    required this.city,
    required this.state,
    required this.condition,
    this.coverUrl,
  });

  final String announcementId;
  final String title;
  final String author;
  final int publishYear;
  final String city;
  final String state;
  final String condition;
  final String? coverUrl;

  String get location => '$city - $state';

  factory TradeBook.fromJson(Map<String, dynamic> json) {
    return TradeBook(
      announcementId:
          (json['announcement_id'] ?? json['announcementId']) as String,
      title: json['title'] as String,
      author: (json['author'] as String?) ?? '',
      publishYear: (json['publish_year'] ?? json['publishYear']) as int,
      city: (json['city'] as String?) ?? '',
      state: (json['state'] as String?) ?? '',
      condition: (json['condition'] as String?) ?? '',
      coverUrl: json['cover_url'] as String? ?? json['coverUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'announcement_id': announcementId,
        'title': title,
        'author': author,
        'publish_year': publishYear,
        'city': city,
        'state': state,
        'condition': condition,
        'cover_url': coverUrl,
      };
}

class TradeRequest {
  const TradeRequest({
    required this.id,
    required this.requester,
    required this.requestedBook,
    required this.offeredBooks,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final TradeUser requester;
  final TradeBook requestedBook;
  final List<TradeBook> offeredBooks;
  final OfferStatus status;
  final DateTime createdAt;

  bool get isPending => status == OfferStatus.pending;

  TradeRequest copyWith({
    TradeUser? requester,
    TradeBook? requestedBook,
    List<TradeBook>? offeredBooks,
    OfferStatus? status,
    DateTime? createdAt,
  }) {
    return TradeRequest(
      id: id,
      requester: requester ?? this.requester,
      requestedBook: requestedBook ?? this.requestedBook,
      offeredBooks: offeredBooks ?? this.offeredBooks,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TradeRequest.fromJson(Map<String, dynamic> json) {
    return TradeRequest(
      id: json['id'] as String,
      requester: TradeUser.fromJson(json['requester'] as Map<String, dynamic>),
      requestedBook: TradeBook.fromJson(
        (json['requested_book'] ?? json['requestedBook'])
            as Map<String, dynamic>,
      ),
      offeredBooks: ((json['offered_books'] ?? json['offeredBooks']) as List)
          .map((item) => TradeBook.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      status: OfferStatusPresentation.fromJson(json['status'] as String),
      createdAt: DateTime.parse(
        (json['created_at'] ?? json['createdAt']) as String,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'requester': requester.toJson(),
        'requested_book': requestedBook.toJson(),
        'offered_books': offeredBooks.map((book) => book.toJson()).toList(),
        'status': status.toJson(),
        'created_at': createdAt.toIso8601String(),
      };
}
