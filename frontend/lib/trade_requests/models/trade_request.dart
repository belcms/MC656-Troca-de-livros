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

  static OfferStatus fromJson(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();

    switch (normalized) {
      case 'pending':
        return OfferStatus.pending;
      case 'accepted':
        return OfferStatus.accepted;
      case 'rejected':
        return OfferStatus.rejected;
      case 'canceled':
      case 'cancelled':
        return OfferStatus.canceled;
      default:
        throw FormatException('Status de oferta inválido: $value');
    }
  }

  String toJson() {
    switch (this) {
      case OfferStatus.pending:
        return 'Pending';
      case OfferStatus.accepted:
        return 'Accepted';
      case OfferStatus.rejected:
        return 'Rejected';
      case OfferStatus.canceled:
        return 'Canceled';
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

  String get location {
    if (city.isEmpty && state.isEmpty) return '';
    if (state.isEmpty) return city;
    if (city.isEmpty) return state;
    return '$city - $state';
  }

  factory TradeUser.fromJson(Map<String, dynamic> json) {
    return TradeUser(
      id: _stringValue(json['id']),
      name: _stringValue(json['name'], fallback: 'Usuário'),
      city: _stringValue(json['city']),
      state: _stringValue(json['state']),
      photoUrl: _nullableString(
        json['cover_photo'] ?? json['photo_url'] ?? json['photo'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'state': state,
        'photoUrl': photoUrl,
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

  String get location {
    if (city.isEmpty && state.isEmpty) return '';
    if (state.isEmpty) return city;
    if (city.isEmpty) return state;
    return '$city - $state';
  }

  factory TradeBook.fromJson(Map<String, dynamic> json) {
    return TradeBook(
      announcementId: _stringValue(
        json['announcementId'] ??
            json['announcement_id'] ??
            json['id'],
      ),
      title: _stringValue(json['title'], fallback: 'Livro sem título'),
      author: _stringValue(json['author']),
      publishYear: _intValue(
        json['publishYear'] ?? json['publish_year'],
      ),
      city: _stringValue(json['city']),
      state: _stringValue(json['state']),
      condition: _stringValue(json['condition']),
      coverUrl: _nullableString(
        json['coverUrl'] ??
            json['cover_url'] ??
            json['realPhotoUrl'] ??
            json['real_photo_url'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'announcementId': announcementId,
        'title': title,
        'author': author,
        'publishYear': publishYear,
        'city': city,
        'state': state,
        'condition': condition,
        'coverUrl': coverUrl,
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
    final requesterJson = _mapValue(
      json['requester'] ?? json['user'],
      fieldName: 'requester',
    );

    final requestedBookJson = _mapValue(
      json['requestedBook'] ??
          json['requested_book'] ??
          json['targetAnnouncement'] ??
          json['target_announcement'],
      fieldName: 'requestedBook',
    );

    final offeredRaw = json['offeredBooks'] ??
        json['offered_books'] ??
        json['offeredAnnouncements'] ??
        json['offered_announcements'] ??
        const <dynamic>[];

    if (offeredRaw is! List) {
      throw const FormatException(
        'O campo offeredBooks precisa ser uma lista.',
      );
    }

    return TradeRequest(
      id: _stringValue(json['id']),
      requester: TradeUser.fromJson(requesterJson),
      requestedBook: TradeBook.fromJson(requestedBookJson),
      offeredBooks: offeredRaw
          .map((item) => TradeBook.fromJson(
                _mapValue(item, fieldName: 'offeredBooks item'),
              ))
          .toList(growable: false),
      status: OfferStatusPresentation.fromJson(
        json['status'] ?? json['statusOffer'] ?? json['status_offer'],
      ),
      createdAt: DateTime.tryParse(
            _stringValue(json['createdAt'] ?? json['created_at']),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'requester': requester.toJson(),
        'requestedBook': requestedBook.toJson(),
        'offeredBooks': offeredBooks.map((book) => book.toJson()).toList(),
        'status': status.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };
}

Map<String, dynamic> _mapValue(
  Object? value, {
  required String fieldName,
}) {
  if (value is Map<String, dynamic>) return value;

  if (value is Map) {
    return value.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  throw FormatException('Campo inválido: $fieldName');
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final result = value.toString();
  return result.isEmpty ? fallback : result;
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final result = value.toString().trim();
  return result.isEmpty ? null : result;
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
