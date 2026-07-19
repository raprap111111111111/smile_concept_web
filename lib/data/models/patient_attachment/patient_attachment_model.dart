// lib/data/models/patient_attachment/patient_attachment_model.dart

class DetectedCondition {
  final int? toothNumber;
  final String condition;
  final String severity;
  final double confidence;
  final String? location;
  final String? description;

  const DetectedCondition({
    this.toothNumber,
    required this.condition,
    required this.severity,
    required this.confidence,
    this.location,
    this.description,
  });

  factory DetectedCondition.fromJson(Map<String, dynamic> json) {
    return DetectedCondition(
      toothNumber: _parseInt(json['tooth_number']),
      condition: json['condition']?.toString() ?? '',
      severity: json['severity']?.toString() ?? '',
      confidence: _parseDouble(json['confidence']) ?? 0.0,
      location: json['location']?.toString(),
      description: json['description']?.toString(),
    );
  }

  // ✅ Safe parsers
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class PatientAttachment {
  final int id;
  final int userId;
  final int? appointmentId;
  final String fileName;
  final String filePath;
  final String fileType;
  final String category;
  final String? notes;

  // AI Scan
  final bool isXray;
  final String scanStatus;
  final List<DetectedCondition> detectedConditions;
  final double? scanConfidence;
  final DateTime? scannedAt;
  final String? scanProvider;

  // Patient
  final int? patientId;
  final String? patientName;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const PatientAttachment({
    required this.id,
    required this.userId,
    this.appointmentId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.category,
    this.notes,
    this.isXray = false,
    this.scanStatus = 'not_applicable',
    this.detectedConditions = const [],
    this.scanConfidence,
    this.scannedAt,
    this.scanProvider,
    this.patientId,
    this.patientName,
    required this.createdAt,
    this.updatedAt,
  });

  factory PatientAttachment.fromJson(Map<String, dynamic> json) {
    final conditions = (json['detected_conditions'] as List?)
            ?.map((e) => DetectedCondition.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PatientAttachment(
      id: _parseInt(json['id']) ?? 0,
      userId: _parseInt(json['user_id']) ?? 0,
      appointmentId: _parseInt(json['appointment_id']),
      fileName: json['file_name']?.toString() ?? '',
      filePath: json['file_path']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      notes: json['notes']?.toString(),
      isXray: _parseBool(json['is_xray']),
      scanStatus: json['scan_status']?.toString() ?? 'not_applicable',
      detectedConditions: conditions,
      scanConfidence: _parseDouble(json['scan_confidence']), // ✅ FIXED
      scannedAt: _parseDate(json['scanned_at']),
      scanProvider: json['scan_provider']?.toString(),
      patientId: _parseInt(json['patient']?['id']),
      patientName: json['patient']?['name']?.toString(),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  // ✅ Safe parsers (handle any type from Laravel)
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // ─── Convenience Getters ───────────────────────────────
  bool get isScanCompleted => scanStatus == 'completed';
  bool get isScanProcessing => scanStatus == 'processing';
  bool get isScanPending => scanStatus == 'pending';
  bool get isScanFailed => scanStatus == 'failed';
  bool get hasConditions => detectedConditions.isNotEmpty;
}