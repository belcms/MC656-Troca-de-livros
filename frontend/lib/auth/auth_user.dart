class AuthUser {
  final String id;
  final String fullName;
  final String nickname;
  final String email;
  final String? birthDate;
  final String? cep;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.nickname,
    required this.email,
    this.birthDate,
    this.cep,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'],
    fullName: json['full_name'] ?? '',
    nickname: json['nickname'] ?? '',
    email: json['email'],
    birthDate: json['birth_date'],
    cep: json['cep'],
  );
}
