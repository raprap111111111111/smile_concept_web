// lib/models/auth/auth_user.dart
class AuthUser {
  final int id;
  final String name;
  final String? email;
  final String? role;
  final String? profilePhotoUrl;
  final List<String> permissions; // ← ADD THIS

  const AuthUser({
    required this.id,
    required this.name,
    this.email,
    this.role,
    this.profilePhotoUrl,
    this.permissions = const [], // ← ADD THIS
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      profilePhotoUrl: json['profile_photo_url'],
      permissions: List<String>.from(json['permissions'] ?? []), // ← ADD THIS
    );
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<String> perms) {
    return perms.any((p) => permissions.contains(p));
  }
}