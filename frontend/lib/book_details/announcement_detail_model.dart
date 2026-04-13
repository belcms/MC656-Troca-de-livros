class AnnouncementDetail {
  final String id;
  final String? description;
  final String? realPhotoUrl;
  final String? condition;
  final String? status;
  final EditionDetail? edition;
  final BookInfo? book;
  final String? userName;
  final String? userCep;

  AnnouncementDetail({
    required this.id,
    this.description,
    this.realPhotoUrl,
    this.condition,
    this.status,
    this.edition,
    this.book,
    this.userName,
    this.userCep,
  });

  factory AnnouncementDetail.fromJson(Map<String, dynamic> json) {
    final editionJson = json['edition'] as Map<String, dynamic>?;
    final rootBook = json['book'] as Map<String, dynamic>?;
    final nestedBook = editionJson?['book'] as Map<String, dynamic>?;

    return AnnouncementDetail(
      id: json['id'] as String,
      description: json['description'] as String?,
      realPhotoUrl: json['real_photo_url'] as String?,
      condition: json['condition'] as String?,
      status: json['status'] as String?,
      edition: editionJson != null ? EditionDetail.fromJson(editionJson) : null,
      book: (nestedBook ?? rootBook) != null
          ? BookInfo.fromJson((nestedBook ?? rootBook)!)
          : null,
      userName: json['user_name'] as String?,
      userCep: json['user_cep'] as String?,
    );
  }
}

class EditionDetail {
  final String id;
  final String? publisher;
  final int? publishYear;

  EditionDetail({
    required this.id,
    this.publisher,
    this.publishYear,
  });

  factory EditionDetail.fromJson(Map<String, dynamic> json) {
    return EditionDetail(
      id: json['id'] as String,
      publisher: json['publisher'] as String?,
      publishYear: json['publish_year'] as int?,
    );
  }
}

class BookInfo {
  final String id;
  final String? title;
  final String? author;
  final String? synopsis;

  BookInfo({
    required this.id,
    this.title,
    this.author,
    this.synopsis,
  });

  factory BookInfo.fromJson(Map<String, dynamic> json) {
    return BookInfo(
      id: json['id'] as String,
      title: json['title'] as String?,
      author: json['author'] as String?,
      synopsis: json['synopsis'] as String?,
    );
  }
}