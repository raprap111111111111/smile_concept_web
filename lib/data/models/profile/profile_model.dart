// lib/data/models/profile/profile_model.dart

import 'branch_summary_model.dart';
import 'patient_profile_model.dart';

class ProfileModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profilePhotoUrl;
  final String role; // primary role
  final List<String> roles;
  final List<String> permissions;
  final bool needsSetup;
  final PatientProfileModel? patientProfile;
  final List<BranchSummaryModel> branches;
  final bool isActive;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profilePhotoUrl,
    required this.role,
    this.roles = const [],
    this.permissions = const [],
    this.needsSetup = false,
    this.patientProfile,
    this.branches = const [],
    this.isActive = true,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  // ── Role checks ────────────────────────────────────────────────────────
  bool get isPatient => role == 'patient';
  bool get isSuperAdmin => role == 'super-admin' || role == 'superadmin';
  bool get isAdmin => role == 'admin' || isSuperAdmin;
  bool get isDentist => role == 'dentist' || role == 'doctor';
  bool get isReceptionist => role == 'receptionist';
  bool get isStaff => !isPatient;

  // ── Permission helpers ─────────────────────────────────────────────────
  bool hasPermission(String perm) {
    if (isSuperAdmin) return true;
    return permissions.contains(perm);
  }

  bool canAny(List<String> perms) {
    if (isSuperAdmin) return true;
    return perms.any(hasPermission);
  }

  bool canAll(List<String> perms) {
    if (isSuperAdmin) return true;
    return perms.every(hasPermission);
  }

  // ── State checks ───────────────────────────────────────────────────────
  bool get isEmailVerified => emailVerifiedAt != null;
  bool get hasBranch => branches.isNotEmpty;
  BranchSummaryModel? get primaryBranch =>
      branches.isNotEmpty ? branches.first : null;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      role: json['role']?.toString() ?? 'patient',
      roles: _parseStringList(json['roles']),
      permissions: _parseStringList(json['permissions']),
      needsSetup: _asBool(json['needs_setup']),
      patientProfile: json['patient_profile'] is Map<String, dynamic>
          ? PatientProfileModel.fromJson(
              json['patient_profile'] as Map<String, dynamic>,
            )
          : null,
      branches: _parseBranches(json['branches']),
      isActive: _asBool(json['is_active'], defaultValue: true),
      emailVerifiedAt: _parseDate(json['email_verified_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'profile_photo_url': profilePhotoUrl,
        'role': role,
        'roles': roles,
        'permissions': permissions,
        'needs_setup': needsSetup,
        'patient_profile': patientProfile?.toJson(),
        'branches': branches.map((b) => b.toJson()).toList(),
        'is_active': isActive,
        'email_verified_at': emailVerifiedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// Body for updating basic user info
  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
      };

  ProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? profilePhotoUrl,
    PatientProfileModel? patientProfile,
    List<BranchSummaryModel>? branches,
    bool? needsSetup,
    bool? isActive,
  }) {
    return ProfileModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      role: role,
      roles: roles,
      permissions: permissions,
      needsSetup: needsSetup ?? this.needsSetup,
      patientProfile: patientProfile ?? this.patientProfile,
      branches: branches ?? this.branches,
      isActive: isActive ?? this.isActive,
      emailVerifiedAt: emailVerifiedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is double) return v.toInt();
  return 0;
}

bool _asBool(dynamic v, {bool defaultValue = false}) {
  if (v == null) return defaultValue;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return defaultValue;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

List<String> _parseStringList(dynamic raw) {
  if (raw is! List) return [];
  return raw.map((e) => e.toString()).toList();
}

List<BranchSummaryModel> _parseBranches(dynamic raw) {
  if (raw is! List) return [];
  return raw
      .map((b) => BranchSummaryModel.fromJson(b as Map<String, dynamic>))
      .toList();
}