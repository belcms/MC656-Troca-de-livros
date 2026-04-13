class Book {
  final String id;
  final String title;
  final String author;
  final String publisher;
  final String genre;
  final String language;
  final String year;
  final String pages;
  final String synopsis;
  final String description;
  final String status;
  final String condition;
  final String? coverUrl;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.publisher,
    required this.genre,
    required this.language,
    required this.year,
    required this.pages,
    required this.synopsis,
    required this.description,
    required this.status,
    required this.condition,
    this.coverUrl,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final book = json['book'] is Map<String, dynamic>
        ? json['book'] as Map<String, dynamic>
        : <String, dynamic>{};

    final edition = json['edition'] is Map<String, dynamic>
        ? json['edition'] as Map<String, dynamic>
        : <String, dynamic>{};

    return Book(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? book['title'] ?? '').toString(),
      author: (json['author'] ?? book['author'] ?? '').toString(),
      publisher: (json['publisher'] ?? edition['publisher'] ?? '').toString(),
      genre: (json['genre'] ?? 'Romance').toString(),
      language: (json['language'] ?? 'Português').toString(),
      year: (json['publishYear'] ??
              json['year'] ??
              edition['publish_year'] ??
              '')
          .toString(),
      pages: (json['pages'] ??
              edition['number_of_pages'] ??
              '')
          .toString(),
      synopsis: (json['synopsis'] ?? book['synopsis'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'Disponível').toString(),
      condition: (json['condition'] ?? 'Bom').toString(),
      coverUrl: json['real_photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'publisher': publisher,
      'genre': genre,
      'language': language,
      'publishYear': year,
      'pages': pages,
      'synopsis': synopsis,
      'description': description,
      'status': status,
      'condition': condition,
      'real_photo_url': coverUrl,
    };
  }
}