class OfferBookModel {
  final String id;
  final String title;
  final String publishYear;
  final String realPhotoUrl;
  final String location;

  OfferBookModel({
    required this.id,
    required this.title,
    required this.publishYear,
    required this.realPhotoUrl,
    required this.location,
  });

  factory OfferBookModel.fromJson(Map<String, dynamic> json) {
    return OfferBookModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      publishYear:
          (json['publishYear'] ?? json['publish_year'])?.toString() ?? '',
      realPhotoUrl: json['cover_photo'] ?? json['cover_url'] ?? '',
      location:
          json['status'] ?? json['location'] ?? 'Localização não informada',
    );
  }
}
