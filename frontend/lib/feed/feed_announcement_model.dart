/// Represents a single book announcement in the feed.
///
/// This data model holds the essential information required to display
/// an [AnnouncementCard] on the main feed screen.
class FeedAnnouncement {
  /// The unique identifier of the announcement.
  ///
  /// Used to fetch more detailed information when navigating
  /// to the announcement details screen.
  final String id;

  /// The title of the book being offered.
  final String title;

  /// The year the specific edition of the book was published.
  final int publishYear;

  /// The postal code (CEP) of the user offering the book.
  final String cep;

  /// The public URL of the actual photo of the book.
  ///
  /// This property is nullable (`String?`) because the user might not
  /// have uploaded a custom photo for the announcement.
  final String? realPhotoUrl;

  // Creates a new [FeedAnnouncement] instance.
  ///
  /// The [id], [title], [publishYear], and [cep] parameters are required.
  FeedAnnouncement({
    required this.id,
    required this.title,
    required this.publishYear,
    required this.cep,
    this.realPhotoUrl,
  });

  /// Creates a [FeedAnnouncement] instance from a JSON map.
  ///
  /// This factory constructor is used to deserialize the data received
  /// from the backend API into a strongly-typed Dart object.
  factory FeedAnnouncement.fromJson(Map<String, dynamic> json) {
    return FeedAnnouncement(
      id: json['id'],
      title: json['title'],
      publishYear: json['publishYear'],
      cep: json['cep'],
      realPhotoUrl: json['real_photo_url'],
    );
  }
}
