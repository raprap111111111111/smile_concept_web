// lib/data/models/treatment/plan_consumables_model.dart

import '../inventory/stock_movement_model.dart';

/// One recipe-suggested supply line for the recording dialog.
class PlanSuggestedLineModel {
  final int itemId;
  final String name;
  final String? sku;
  final String? unitOfMeasure;

  /// Suggested, not deducted — optional recipe lines surface here flagged so
  /// staff decide whether they were actually used.
  final bool isOptional;

  /// quantity_per_use x planned procedure count, folded across the plan.
  final int suggestedQuantity;

  const PlanSuggestedLineModel({
    required this.itemId,
    required this.name,
    this.sku,
    this.unitOfMeasure,
    this.isOptional = false,
    required this.suggestedQuantity,
  });

  factory PlanSuggestedLineModel.fromJson(Map<String, dynamic> json) {
    return PlanSuggestedLineModel(
      itemId: _asInt(json['item_id']),
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString(),
      unitOfMeasure: json['unit_of_measure']?.toString(),
      isOptional: json['is_optional'] == true || json['is_optional'] == 1,
      suggestedQuantity: _asInt(json['suggested_quantity']),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

/// GET /treatment-plans/{id}/consumables — what the recipes suggest and what
/// was already recorded, in one response.
class PlanConsumablesStatusModel {
  final bool recorded;
  final List<StockMovementModel> movements;
  final List<PlanSuggestedLineModel> suggestedLines;

  const PlanConsumablesStatusModel({
    required this.recorded,
    this.movements = const [],
    this.suggestedLines = const [],
  });

  factory PlanConsumablesStatusModel.fromJson(Map<String, dynamic> json) {
    return PlanConsumablesStatusModel(
      recorded: json['recorded'] == true || json['recorded'] == 1,
      movements: (json['movements'] as List<dynamic>? ?? const [])
          .map((e) =>
              StockMovementModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      suggestedLines: (json['suggested_lines'] as List<dynamic>? ?? const [])
          .map((e) => PlanSuggestedLineModel.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// A supply the recording could not fully draw from stock.
class PlanShortfallModel {
  final int itemId;
  final String name;
  final int shortBy;
  final String? unit;

  const PlanShortfallModel({
    required this.itemId,
    required this.name,
    required this.shortBy,
    this.unit,
  });

  factory PlanShortfallModel.fromJson(Map<String, dynamic> json) {
    return PlanShortfallModel(
      itemId: PlanSuggestedLineModel._asInt(json['item_id']),
      name: json['name']?.toString() ?? '',
      shortBy: PlanSuggestedLineModel._asInt(json['short_by']),
      unit: json['unit']?.toString(),
    );
  }
}

/// POST result: the ledger rows written plus anything that ran short.
class RecordSuppliesResultModel {
  final List<StockMovementModel> movements;
  final List<PlanShortfallModel> shortfalls;

  const RecordSuppliesResultModel({
    this.movements = const [],
    this.shortfalls = const [],
  });

  bool get hasShortfall => shortfalls.isNotEmpty;

  factory RecordSuppliesResultModel.fromJson(Map<String, dynamic> json) {
    return RecordSuppliesResultModel(
      movements: (json['movements'] as List<dynamic>? ?? const [])
          .map((e) =>
              StockMovementModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      shortfalls: (json['shortfalls'] as List<dynamic>? ?? const [])
          .map((e) =>
              PlanShortfallModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
