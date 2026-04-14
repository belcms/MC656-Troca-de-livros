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

  static String _mapGenreFromBack(dynamic value) {
    final raw = (value ?? '').toString();

    switch (raw) {
      case 'Fantasy':
        return 'Fantasia';
      case 'Romance':
        return 'Romance';
      case 'Sci_fic':
        return 'Ficção científica';
      case 'Non_fiction':
        return 'Não ficção';
      case 'Biography':
        return 'Biografia';
      case 'Graphic_novel':
        return 'Graphic novel';
      case 'Horror':
        return 'Terror';
      case 'Self_help':
        return 'Autoajuda';
      case 'Thriller':
        return 'Suspense';
      case 'Education':
        return 'Educação';
      default:
        return 'Romance';
    }
  }

  static String _mapLanguageFromBack(dynamic value) {
    final raw = (value ?? '').toString();

    switch (raw) {
      case 'PT-br':
        return 'Português';
      case 'En':
        return 'Inglês';
      case 'Espanhol':
        return 'Espanhol';
      default:
        return 'Português';
    }
  }

  static String _mapStatusFromBack(dynamic value) {
    final raw = (value ?? '').toString();

    switch (raw) {
      case 'Available':
        return 'Disponível';
      case 'Reserved':
        return 'Negociando';
      case 'Traded':
        return 'Trocado';
      default:
        return 'Disponível';
    }
  }

  static String _mapConditionFromBack(dynamic value) {
    final raw = (value ?? '').toString();

    switch (raw) {
      case 'New':
        return 'Novo';
      case 'Good':
        return 'Bom';
      case 'Used':
        return 'Muito bom';
      case 'Worn':
        return 'Desgastado';
      default:
        return 'Novo';
    }
  }

  static String _mapGenreToBack(String value) {
    switch (value) {
      case 'Fantasia':
        return 'Fantasy';
      case 'Romance':
        return 'Romance';
      case 'Ficção científica':
        return 'Sci_fic';
      case 'Não ficção':
        return 'Non_fiction';
      case 'Biografia':
        return 'Biography';
      case 'Graphic novel':
        return 'Graphic_novel';
      case 'Terror':
        return 'Horror';
      case 'Autoajuda':
        return 'Self_help';
      case 'Suspense':
        return 'Thriller';
      case 'Educação':
        return 'Education';
      default:
        return 'Romance';
    }
  }

  static String _mapLanguageToBack(String value) {
    switch (value) {
      case 'Português':
        return 'PT-br';
      case 'Inglês':
        return 'En';
      case 'Espanhol':
        return 'Espanhol';
      default:
        return 'PT-br';
    }
  }

  static String _mapStatusToBack(String value) {
    switch (value) {
      case 'Disponível':
        return 'Available';
      case 'Negociando':
        return 'Reserved';
      case 'Trocado':
        return 'Traded';
      default:
        return 'Available';
    }
  }

  static String _mapConditionToBack(String value) {
    switch (value) {
      case 'Novo':
        return 'New';
      case 'Bom':
        return 'Good';
      case 'Muito bom':
        return 'Used';
      case 'Desgastado':
        return 'Worn';
      default:
        return 'New';
    }
  }

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
      genre: _mapGenreFromBack(json['genre'] ?? book['genre']),
      language: _mapLanguageFromBack(json['language'] ?? edition['language']),
      year: (json['publishYear'] ?? json['year'] ?? edition['publish_year'] ?? '')
          .toString(),
      pages: (json['pages'] ?? edition['number_of_pages'] ?? '').toString(),
      synopsis: (json['synopsis'] ?? book['synopsis'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: _mapStatusFromBack(json['status']),
      condition: _mapConditionFromBack(json['condition']),
      coverUrl: json['real_photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'publisher': publisher,
      'genre': _mapGenreToBack(genre),
      'language': _mapLanguageToBack(language),
      'publishYear': year,
      'pages': pages,
      'synopsis': synopsis,
      'description': description,
      'status': _mapStatusToBack(status),
      'condition': _mapConditionToBack(condition),
      'real_photo_url': coverUrl,
    };
  }
}