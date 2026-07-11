/// Represents a single announcement item returned by search.
class AnnouncementSearchItem {
  /// Creates a new [AnnouncementSearchItem].
  const AnnouncementSearchItem({
    required this.id,
    required this.title,
    required this.publishYear,
    required this.cep,
    required this.realPhotoUrl,
  });

  /// Announcement identifier.
  final String id;

  /// Book title.
  final String title;

  /// Publication year of the edition.
  final int publishYear;

  /// Postal code of the advertiser.
  final String cep;

  /// Cover photo URL.
  final String? realPhotoUrl;

  /// Creates an [AnnouncementSearchItem] from JSON.
  factory AnnouncementSearchItem.fromJson(Map<String, dynamic> json) {
    final publishYearValue = json['publishYear'] ?? json['publish_year'];

    return AnnouncementSearchItem(
      id: json['id'].toString(),
      title: (json['title'] ?? '') as String,
      publishYear: publishYearValue is int
          ? publishYearValue
          : int.tryParse(publishYearValue.toString()) ?? 0,
      cep: (json['cep'] ?? '') as String,
      realPhotoUrl: json['real_photo_url'] as String?,
    );
  }
}

/// Represents the paginated search response.
class AnnouncementSearchResponse {
  /// Creates a new [AnnouncementSearchResponse].
  const AnnouncementSearchResponse({
    required this.results,
    required this.total,
  });

  /// Search results returned by the backend.
  final List<AnnouncementSearchItem> results;

  /// Total number of matching announcements.
  final int total;

  /// Creates a response from JSON.
  factory AnnouncementSearchResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = (json['results'] as List<dynamic>? ?? const []);

    return AnnouncementSearchResponse(
      results: rawResults
          .map(
            (item) =>
                AnnouncementSearchItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      total: (json['total'] ?? 0) as int,
    );
  }
}
