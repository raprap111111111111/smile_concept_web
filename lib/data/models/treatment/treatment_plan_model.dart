// lib/data/models/treatment/treatment_plan_model.dart

import 'package:flutter/material.dart';
import '../../../core/utils/money.dart';
import 'treatment_model.dart';

class TreatmentPlanModel {
  final int id;
  final int userId;
  final int doctorId;
  final String name;
  final String status;
  final double totalEstimatedAmount;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final List<TreatmentPlanItemModel> items;
  final TreatmentPlanPatientModel? patient;
  final TreatmentPlanDoctorModel? doctor;

  const TreatmentPlanModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.name,
    required this.status,
    required this.totalEstimatedAmount,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
    this.patient,
    this.doctor,
  });

  factory TreatmentPlanModel.fromJson(Map<String, dynamic> json) {
    // TreatmentPlanResource serialises the plan's steps under `steps`, not
    // `items`. Read both so the list, detail and create responses all populate
    // — reading only `items` left every plan looking empty.
    final rawItems =
        (json['steps'] ?? json['items']) as List<dynamic>? ?? const [];

    final patient = json['patient'] != null
        ? TreatmentPlanPatientModel.fromJson(_toMap(json['patient'] as Map))
        : null;
    final doctor = json['doctor'] != null
        ? TreatmentPlanDoctorModel.fromJson(_toMap(json['doctor'] as Map))
        : null;

    return TreatmentPlanModel(
      id: _asInt(json['id']),
      // The resource omits the raw foreign keys; fall back to the nested
      // relations so these are not silently 0.
      userId: json.containsKey('user_id')
          ? _asInt(json['user_id'])
          : patient?.id ?? 0,
      doctorId: json.containsKey('doctor_id')
          ? _asInt(json['doctor_id'])
          : doctor?.id ?? 0,
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'proposed',
      totalEstimatedAmount: _asDouble(json['total_estimated_amount']),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      items: rawItems
          .map((e) => TreatmentPlanItemModel.fromJson(_toMap(e as Map)))
          .toList()
        ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder)),
      patient: patient,
      doctor: doctor,
    );
  }

  // ── Status helpers ─────────────────────────────────────────
  bool get isDraft => status == 'draft';
  bool get isProposed => status == 'proposed';
  bool get isAccepted => status == 'accepted';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';

  bool get hasItems => items.isNotEmpty;
  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;
  bool get hasPatient => patient != null;
  bool get hasDoctor => doctor != null;

  String get formattedTotal => formatMoney(totalEstimatedAmount);

  String get statusLabel {
    return switch (status) {
      'draft' => 'Draft',
      'proposed' => 'Proposed',
      'accepted' => 'Accepted',
      'completed' => 'Completed',
      'rejected' => 'Rejected',
      _ => status,
    };
  }

  // ── Private helpers ────────────────────────────────────────
  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static Map<String, dynamic> _toMap(Map source) =>
      source.map((k, v) => MapEntry(k.toString(), v));
}

// ── Treatment Plan Item ───────────────────────────────────────
class TreatmentPlanItemModel {
  final int id;
  final int treatmentPlanId;
  final int treatmentId;
  final int sequenceOrder;
  final int quantity;

  /// Catalog price frozen at quote time.
  final double unitPrice;

  /// Line total — [unitPrice] × [quantity].
  final double estimatedCost;
  final String? notes;
  final TreatmentModel? treatment;

  /// Flat name from the API resource, used when [treatment] is not embedded.
  final String? treatmentNameRaw;

  const TreatmentPlanItemModel({
    required this.id,
    required this.treatmentPlanId,
    required this.treatmentId,
    required this.sequenceOrder,
    required this.estimatedCost,
    this.quantity = 1,
    this.unitPrice = 0,
    this.notes,
    this.treatment,
    this.treatmentNameRaw,
  });

  factory TreatmentPlanItemModel.fromJson(Map<String, dynamic> json) {
    final estimatedCost = _asDouble(json['estimated_cost']);
    // Rows written before quantity existed carry neither field; treat them as
    // a single unit priced at the line total.
    final quantity =
        json['quantity'] == null ? 1 : _asInt(json['quantity']).clamp(1, 99);
    final unitPrice = json['unit_price'] == null
        ? estimatedCost / quantity
        : _asDouble(json['unit_price']);

    return TreatmentPlanItemModel(
      id: _asInt(json['id']),
      treatmentPlanId: _asInt(json['treatment_plan_id']),
      treatmentId: _asInt(json['treatment_id']),
      sequenceOrder: _asInt(json['sequence_order']),
      quantity: quantity,
      unitPrice: unitPrice,
      estimatedCost: estimatedCost,
      notes: json['notes']?.toString(),
      // The resource flattens the treatment to `treatment_name`; only the
      // eager-loaded model shape carries the nested object.
      treatment: json['treatment'] != null
          ? TreatmentModel.fromJson(_toMap(json['treatment'] as Map))
          : null,
      treatmentNameRaw: json['treatment_name']?.toString(),
    );
  }

  /// Display name, whichever shape the payload used.
  String get treatmentName {
    final nested = treatment?.name;
    if (nested != null && nested.isNotEmpty) return nested;
    final flat = treatmentNameRaw;
    if (flat != null && flat.isNotEmpty) return flat;
    return 'Treatment #$treatmentId';
  }

  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;

  String get formattedCost => formatMoney(estimatedCost);

  String get formattedUnitPrice => formatMoney(unitPrice);

  /// `₱1,500.00 × 3` — omitted entirely by callers when [quantity] is 1.
  String get quantityLabel => '$formattedUnitPrice × $quantity';

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static Map<String, dynamic> _toMap(Map source) =>
      source.map((k, v) => MapEntry(k.toString(), v));
}

// ── Nested Patient ────────────────────────────────────────────
class TreatmentPlanPatientModel {
  final int id;
  final String name;
  final String email;

  const TreatmentPlanPatientModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory TreatmentPlanPatientModel.fromJson(Map<String, dynamic> json) {
    return TreatmentPlanPatientModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

// ── Nested Doctor ─────────────────────────────────────────────
class TreatmentPlanDoctorModel {
  final int id;
  final String name;
  final String? specialization;

  const TreatmentPlanDoctorModel({
    required this.id,
    required this.name,
    this.specialization,
  });

  factory TreatmentPlanDoctorModel.fromJson(Map<String, dynamic> json) {
    final userName = json['user'] != null
        ? (json['user'] as Map)['name']?.toString()
        : json['name']?.toString();

    return TreatmentPlanDoctorModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: userName ?? 'Unknown Doctor',
      specialization: json['specialization']?.toString(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ── FORM EDITING CLASS ────────────────────────────────────────
// Mutable state for a plan item while user is filling the form.
// Convert to backend JSON via [toPayload].
// ═══════════════════════════════════════════════════════════════
class TreatmentPlanItemForm {
  TreatmentModel? selectedTreatment;
  final TextEditingController notesController = TextEditingController();
  int quantity = 1;
  bool treatmentError = false;

  double get price => selectedTreatment?.price ?? 0.0;
  double get subtotal => price * quantity;

  /// Convert to the JSON payload backend expects.
  /// [sequenceOrder] should be 1-based (index + 1).
  ///
  /// Price is deliberately omitted: the API prices each line from the catalog
  /// and freezes it as `unit_price`, so a client-sent price would be ignored at
  /// best and a way to under-quote at worst.
  Map<String, dynamic> toPayload(int sequenceOrder) {
    final notes = notesController.text.trim();
    return {
      'sequence_order': sequenceOrder,
      'treatment_id': selectedTreatment!.id,
      'quantity': quantity,
      if (notes.isNotEmpty) 'notes': notes,
    };
  }

  void dispose() => notesController.dispose();
}
