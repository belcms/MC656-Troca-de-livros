/// Data model consumed by the My Books UI.
///
/// It mirrors the backend card payload from:
/// `GET /api/v1/users/{user_id}/announcements`.
class MyBooksModel {
  final String id;
  final String title;
  final int publishYear;
  final String? realPhotoUrl;
  final String status;
  final String location;
  final String? coverPhoto;

  MyBooksModel({
    required this.id,
    required this.title,
    required this.publishYear,
    this.realPhotoUrl,
    required this.status,
    required this.location,
    this.coverPhoto,
  });

  /// Builds a model instance from backend JSON.
  factory MyBooksModel.fromJson(Map<String, dynamic> json) {
    return MyBooksModel(
      id: json['id'] as String,
      title: json['title'] as String,
      publishYear: json['publish_year'] is int
          ? json['publish_year'] as int
          : int.tryParse(json['publish_year']?.toString() ?? '') ?? 0,
      realPhotoUrl: json['real_photo_url'] as String?,
      status: json['status'] as String,
      location: (json['location'] as String?) ?? "Localização não informada",
      coverPhoto: json['cover_photo'] as String?,
    );
  }
}
