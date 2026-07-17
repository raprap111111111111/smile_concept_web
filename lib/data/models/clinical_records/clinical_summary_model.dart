// lib/data/models/clinical_records/clinical_summary_model.dart

class ClinicalStatsModel {
  final int totalDentalCharts;
  final int totalClinicalNotes;
  final int lockedNotes;
  final int totalLabCases;
  final int pendingLabCases;
  final int totalAttachments;
  final int totalPrescriptions;

  const ClinicalStatsModel({
    this.totalDentalCharts = 0,
    this.totalClinicalNotes = 0,
    this.lockedNotes = 0,
    this.totalLabCases = 0,
    this.pendingLabCases = 0,
    this.totalAttachments = 0,
    this.totalPrescriptions = 0,
  });

  factory ClinicalStatsModel.fromJson(Map<String, dynamic> json) {
    return ClinicalStatsModel(
      totalDentalCharts:   _asInt(json['total_dental_charts']),
      totalClinicalNotes:  _asInt(json['total_clinical_notes']),
      lockedNotes:         _asInt(json['locked_notes']),
      totalLabCases:       _asInt(json['total_lab_cases']),
      pendingLabCases:     _asInt(json['pending_lab_cases']),
      totalAttachments:    _asInt(json['total_attachments']),
      totalPrescriptions:  _asInt(json['total_prescriptions']),
    );
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class RecentActivityModel {
  final int id;
  final String type; // 'clinical_note', 'dental_chart', 'lab_case', 'attachment'
  final String title;
  final String? subtitle;
  final String? patientName;
  final DateTime? createdAt;

  const RecentActivityModel({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.patientName,
    this.createdAt,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      id:          _asInt(json['id']),
      type:        json['type']?.toString() ?? 'unknown',
      title:       json['title']?.toString() ?? '',
      subtitle:    json['subtitle']?.toString(),
      patientName: json['patient_name']?.toString(),
      createdAt:   json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class ClinicalSummaryModel {
  final ClinicalStatsModel stats;
  final List<RecentActivityModel> recentActivity;

  const ClinicalSummaryModel({
    this.stats = const ClinicalStatsModel(),
    this.recentActivity = const [],
  });

  factory ClinicalSummaryModel.fromJson(Map<String, dynamic> json) {
    return ClinicalSummaryModel(
      stats: json['stats'] != null
          ? ClinicalStatsModel.fromJson(json['stats'] as Map<String, dynamic>)
          : const ClinicalStatsModel(),
      recentActivity: (json['recent_activity'] as List<dynamic>?)
              ?.map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}