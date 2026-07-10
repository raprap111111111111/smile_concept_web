// lib/data/models/auth/user_model.dart

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profilePhoto;
  final String? profilePhotoUrl;
  final int? branchId;
  final String? emailVerifiedAt;
  final String? createdAt;
  final String? updatedAt;
  final List<RoleModel> roles;
  final List<String> permissions;
  final List<dynamic> socialAccounts;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profilePhoto,
    this.profilePhotoUrl,
    this.branchId,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.roles = const [],
    this.permissions = const [],
    this.socialAccounts = const [],
  });

  String get role => roles.isNotEmpty ? roles.first.name : 'user';

  bool get isSuperAdmin {
    final normalizedRole = role.toLowerCase();
    return normalizedRole == 'super-admin' ||
        normalizedRole == 'super admin';
  }

  String? get avatarUrl => profilePhotoUrl ?? profilePhoto;

  bool can(String permission) {
    if (isSuperAdmin) return true;
    return permissions.contains(permission);
  }

  bool canAny(List<String> items) {
    if (isSuperAdmin) return true;
    return items.any(permissions.contains);
  }

  bool canAll(List<String> items) {
    if (isSuperAdmin) return true;
    return items.every(permissions.contains);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      email: _asString(json['email']),
      phone: json['phone']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      branchId: _asIntOrNull(json['branch_id']),
      emailVerifiedAt: json['email_verified_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      roles: _parseRoles(json['roles'], json['role']),
      permissions: _parsePermissions(json['permissions']),
      socialAccounts: json['social_accounts'] is List
          ? json['social_accounts'] as List
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'profile_photo': profilePhoto,
        'profile_photo_url': profilePhotoUrl,
        'branch_id': branchId,
        'roles': roles.map((role) => role.toJson()).toList(),
        'permissions': permissions,
        'social_accounts': socialAccounts,
      };

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return 0;
  }

  static int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return null;
  }

  static String _asString(dynamic value) {
    return value?.toString() ?? '';
  }

  static List<RoleModel> _parseRoles(
    dynamic rolesValue,
    dynamic singleRoleValue,
  ) {
    if (rolesValue is List && rolesValue.isNotEmpty) {
      return rolesValue.map<RoleModel>((role) {
        if (role is Map<String, dynamic>) {
          return RoleModel.fromJson(role);
        }

        if (role is Map) {
          return RoleModel.fromJson(Map<String, dynamic>.from(role));
        }

        return RoleModel(
          id: 0,
          name: role.toString(),
        );
      }).toList();
    }

    if (singleRoleValue != null) {
      return [
        RoleModel(
          id: 0,
          name: singleRoleValue.toString(),
        ),
      ];
    }

    return const [];
  }

  static List<String> _parsePermissions(dynamic value) {
    if (value is! List) return const [];

    return value.map<String>((permission) {
      if (permission is Map<String, dynamic> &&
          permission['name'] != null) {
        return permission['name'].toString();
      }

      if (permission is Map && permission['name'] != null) {
        return permission['name'].toString();
      }

      return permission.toString();
    }).toList();
  }
}

class RoleModel {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final String? guardName;

  const RoleModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.guardName,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: _asBool(json['is_active'], fallback: true),
      guardName: json['guard_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'is_active': isActive,
        'guard_name': guardName,
      };

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return 0;
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }

    return fallback;
  }
}