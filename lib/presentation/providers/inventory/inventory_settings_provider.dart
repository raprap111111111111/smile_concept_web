// lib/presentation/providers/inventory/inventory_settings_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_message.dart';
import '../../../core/network/dio_client.dart';

/// Clinic-wide inventory rules.
///
/// Flat key/value, keyed by the settings-table keys the API uses — the same
/// names that appear in the seeder and in any error message, so there is one
/// vocabulary rather than two.
class InventorySettingsModel {
  final bool autoDeductEnabled;
  final bool allowNegativeStock;
  final bool trackExpiry;
  final int expiryWarningDays;
  final int defaultMinimumThreshold;
  final bool lowStockAlertsEnabled;
  final int lowStockAlertHour;
  final int lowStockCooldownDays;

  const InventorySettingsModel({
    required this.autoDeductEnabled,
    required this.allowNegativeStock,
    required this.trackExpiry,
    required this.expiryWarningDays,
    required this.defaultMinimumThreshold,
    required this.lowStockAlertsEnabled,
    required this.lowStockAlertHour,
    required this.lowStockCooldownDays,
  });

  factory InventorySettingsModel.fromJson(Map<String, dynamic> json) {
    return InventorySettingsModel(
      autoDeductEnabled: _bool(json['inventory_auto_deduct_enabled']),
      allowNegativeStock: _bool(json['inventory_allow_negative_stock']),
      trackExpiry: _bool(json['inventory_track_expiry']),
      expiryWarningDays: _int(json['inventory_expiry_warning_days'], 30),
      defaultMinimumThreshold:
          _int(json['inventory_default_minimum_threshold'], 10),
      lowStockAlertsEnabled: _bool(json['inventory_low_stock_alert_enabled']),
      lowStockAlertHour: _int(json['inventory_low_stock_alert_hour'], 8),
      lowStockCooldownDays: _int(json['inventory_low_stock_cooldown_days'], 3),
    );
  }

  /// Every key, always. The endpoint requires a complete body — a partial save
  /// would let a half-loaded form write back over settings it never showed.
  Map<String, dynamic> toJson() => {
        'inventory_auto_deduct_enabled': autoDeductEnabled,
        'inventory_allow_negative_stock': allowNegativeStock,
        'inventory_track_expiry': trackExpiry,
        'inventory_expiry_warning_days': expiryWarningDays,
        'inventory_default_minimum_threshold': defaultMinimumThreshold,
        'inventory_low_stock_alert_enabled': lowStockAlertsEnabled,
        'inventory_low_stock_alert_hour': lowStockAlertHour,
        'inventory_low_stock_cooldown_days': lowStockCooldownDays,
      };

  InventorySettingsModel copyWith({
    bool? autoDeductEnabled,
    bool? allowNegativeStock,
    bool? trackExpiry,
    int? expiryWarningDays,
    int? defaultMinimumThreshold,
    bool? lowStockAlertsEnabled,
    int? lowStockAlertHour,
    int? lowStockCooldownDays,
  }) {
    return InventorySettingsModel(
      autoDeductEnabled: autoDeductEnabled ?? this.autoDeductEnabled,
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
      trackExpiry: trackExpiry ?? this.trackExpiry,
      expiryWarningDays: expiryWarningDays ?? this.expiryWarningDays,
      defaultMinimumThreshold:
          defaultMinimumThreshold ?? this.defaultMinimumThreshold,
      lowStockAlertsEnabled:
          lowStockAlertsEnabled ?? this.lowStockAlertsEnabled,
      lowStockAlertHour: lowStockAlertHour ?? this.lowStockAlertHour,
      lowStockCooldownDays: lowStockCooldownDays ?? this.lowStockCooldownDays,
    );
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  static int _int(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

final inventorySettingsProvider =
    FutureProvider.autoDispose<InventorySettingsModel>((ref) async {
  final dio = ref.read(dioProvider);

  try {
    final response = await dio.get('/inventory-settings');

    return InventorySettingsModel.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  } on DioException catch (e) {
    throw Exception(describeError(e, fallback: 'Could not load inventory settings.'));
  }
});

class InventorySettingsWriter {
  final Dio _dio;

  const InventorySettingsWriter(this._dio);

  Future<InventorySettingsModel> save(InventorySettingsModel settings) async {
    try {
      final response =
          await _dio.put('/inventory-settings', data: settings.toJson());

      // The server rebuilds from storage, so this is what enforcement will
      // actually use — not an echo of what was sent.
      return InventorySettingsModel.fromJson(
        Map<String, dynamic>.from(response.data['data'] as Map),
      );
    } on DioException catch (e) {
      throw Exception(describeError(e, fallback: 'Could not save inventory settings.'));
    }
  }
}

final inventorySettingsWriterProvider =
    Provider<InventorySettingsWriter>((ref) {
  return InventorySettingsWriter(ref.read(dioProvider));
});
