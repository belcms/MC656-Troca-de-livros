class FeedAnnouncement {
  final String id;
  final String title;
  final int publishYear;
  final String coverPhoto;
  final String location;
  final double? distanceKm;
  final String condition;

  const FeedAnnouncement({
    required this.id,
    required this.title,
    required this.publishYear,
    required this.coverPhoto,
    required this.location,
    required this.distanceKm,
    required this.condition,
  });

  factory FeedAnnouncement.fromJson(Map<String, dynamic> json) {
    return FeedAnnouncement(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Livro sem título',
      publishYear: _parsePublishYear(json['publishYear']),
      coverPhoto: json['cover_photo']?.toString() ??
          json['real_photo_url']?.toString() ??
          '',
      location: json['cep']?.toString() ?? 'Localização não informada',
      distanceKm: _parseDistanceKm(json['distanceKm']),
      condition: json['condition']?.toString() ?? '',
    );
  }

  static int _parsePublishYear(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _parseDistanceKm(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}