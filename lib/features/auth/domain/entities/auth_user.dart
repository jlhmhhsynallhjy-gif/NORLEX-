
class AuthUser {
  final String id;
  final String email;
  final String? fullName;
  final bool isActive;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    this.isActive = true,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
