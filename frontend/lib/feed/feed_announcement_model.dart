class FeedAnnouncement {
  final String id;
  final String title;
  final int publishYear;
  final String cep;
  final String? realPhotoUrl;

  FeedAnnouncement({
    required this.id,
    required this.title,
    required this.publishYear,
    required this.cep,
    this.realPhotoUrl,
  });

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
