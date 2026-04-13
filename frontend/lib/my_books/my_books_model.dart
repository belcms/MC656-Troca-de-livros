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
