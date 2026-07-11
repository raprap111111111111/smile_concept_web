class PrescriptionItemModel {
  final int id;
  final int prescriptionId;
  final String medicineName;
  final String dosage;
  final String frequency;
  final int durationDays;
  final String? instructions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PrescriptionItemModel({
    required this.id,
    required this.prescriptionId,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    this.instructions,
    this.createdAt,
    this.updatedAt,
  });

  factory PrescriptionItemModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionItemModel(
      id: json['id'] as int,
      prescriptionId: json['prescription_id'] as int,
      medicineName: json['medicine_name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      durationDays: json['duration_days'] as int,
      instructions: json['instructions'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prescription_id': prescriptionId,
      'medicine_name': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'duration_days': durationDays,
      'instructions': instructions,
    };
  }

  bool get hasInstructions =>
      instructions != null && instructions!.trim().isNotEmpty;

  String get durationLabel =>
      '$durationDays day${durationDays == 1 ? '' : 's'}';
}