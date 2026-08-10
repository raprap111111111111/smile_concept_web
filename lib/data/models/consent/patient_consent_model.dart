class PatientConsentModel {
  final int id;
  final DateTime signedAt;
  final bool isVoided;
  final DateTime? voidedAt;
  final String? voidedReason;

  final ConsentTemplateBrief? template;
  final PatientBrief? patient;
  final AppointmentBrief? appointment;
  final StaffBrief? signedByStaff;

  final String? signatureData;
  final String? ipAddress;

  const PatientConsentModel({
    required this.id,
    required this.signedAt,
    required this.isVoided,
    this.voidedAt,
    this.voidedReason,
    this.template,
    this.patient,
    this.appointment,
    this.signedByStaff,
    this.signatureData,
    this.ipAddress,
  });

  factory PatientConsentModel.fromJson(Map<String, dynamic> json) {
    return PatientConsentModel(
      id: _toInt(json['id']) ?? 0,
      signedAt: _toDate(json['signed_at']) ?? DateTime.now(),
      isVoided: json['is_voided'] as bool? ?? false,
      voidedAt: _toDate(json['voided_at']),
      voidedReason: json['voided_reason'] as String?,
      template: json['template'] is Map<String, dynamic>
          ? ConsentTemplateBrief.fromJson(
              json['template'] as Map<String, dynamic>)
          : null,
      patient: json['patient'] is Map<String, dynamic>
          ? PatientBrief.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
      appointment: json['appointment'] is Map<String, dynamic>
          ? AppointmentBrief.fromJson(
              json['appointment'] as Map<String, dynamic>)
          : null,
      signedByStaff: json['signed_by_staff'] is Map<String, dynamic>
          ? StaffBrief.fromJson(
              json['signed_by_staff'] as Map<String, dynamic>)
          : null,
      signatureData: json['signature_data'] as String?,
      ipAddress: json['ip_address'] as String?,
    );
  }
}

// ─── Briefs ───────────────────────────────────────────────────────────────
class ConsentTemplateBrief {
  final int id;
  final String title;
  final String? body;

  const ConsentTemplateBrief({
    required this.id,
    required this.title,
    this.body,
  });

  factory ConsentTemplateBrief.fromJson(Map<String, dynamic> json) {
    return ConsentTemplateBrief(
      id: _toInt(json['id']) ?? 0,
      title: (json['title'] as String?) ?? 'Untitled',
      body: json['body'] as String?,
    );
  }
}

class PatientBrief {
  final int id;
  final String name;

  const PatientBrief({required this.id, required this.name});

  factory PatientBrief.fromJson(Map<String, dynamic> json) {
    return PatientBrief(
      id: _toInt(json['id']) ?? 0,
      name: (json['name'] as String?) ?? 'Unknown',
    );
  }
}

class AppointmentBrief {
  final int id;
  final DateTime? scheduledAt;

  const AppointmentBrief({required this.id, this.scheduledAt});

  factory AppointmentBrief.fromJson(Map<String, dynamic> json) {
    return AppointmentBrief(
      id: _toInt(json['id']) ?? 0,
      scheduledAt: _toDate(json['scheduled_at']),
    );
  }
}

class StaffBrief {
  final int id;
  final String name;

  const StaffBrief({required this.id, required this.name});

  factory StaffBrief.fromJson(Map<String, dynamic> json) {
    return StaffBrief(
      id: _toInt(json['id']) ?? 0,
      name: (json['name'] as String?) ?? 'Unknown',
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────
int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}