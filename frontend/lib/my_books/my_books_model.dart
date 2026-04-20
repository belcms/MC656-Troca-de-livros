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

  MyBooksModel({
    required this.id,
    required this.title,
    required this.publishYear,
    this.realPhotoUrl,
    required this.status,
  });

  /// Builds a model instance from backend JSON.
  factory MyBooksModel.fromJson(Map<String, dynamic> json) {
    return MyBooksModel(
      id: json['id'] as String,
      title: json['title'] as String,
      publishYear: json['publish_year'] as int,
      realPhotoUrl: json['real_photo_url'] as String?,
      status: json['status'] as String,
    );
  }
}
