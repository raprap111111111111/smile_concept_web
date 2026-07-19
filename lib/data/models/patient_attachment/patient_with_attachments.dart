class PatientWithAttachments {
  final int id;
  final String name;
  final String? email;
  final String? profilePhoto;
  final int attachmentCount;
  final int xrayCount;
  final int pendingScans;

  const PatientWithAttachments({
    required this.id,
    required this.name,
    this.email,
    this.profilePhoto,
    required this.attachmentCount,
    required this.xrayCount,
    this.pendingScans = 0,
  });

  factory PatientWithAttachments.fromJson(Map<String, dynamic> json) {
    return PatientWithAttachments(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
      attachmentCount: _parseInt(json['attachment_count']) ?? 0,
      xrayCount: _parseInt(json['xray_count']) ?? 0,
      pendingScans: _parseInt(json['pending_scans']) ?? 0,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get hasPendingScans => pendingScans > 0;

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }
}