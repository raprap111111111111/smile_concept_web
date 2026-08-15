// lib/presentation/providers/treatment/treatment_consumable_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_message.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/inventory/treatment_consumable_model.dart';

/// A treatment's recipe, loaded per treatment.
///
/// autoDispose and family: this is only ever open while one treatment's form
/// is on screen, and holding every treatment's recipe for the session would be
/// stale by the time it was read again.
final treatmentConsumablesProvider = FutureProvider.autoDispose
    .family<List<TreatmentConsumableModel>, int>((ref, treatmentId) async {
  final dio = ref.read(dioProvider);

  final response = await dio.get('/treatments/$treatmentId/consumables');

  final list = response.data['data'] as List<dynamic>? ?? [];

  return list
      .map((e) => TreatmentConsumableModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ))
      .toList();
});

/// Saves a treatment's whole recipe in one call.
///
/// The endpoint is a sync, not per-row CRUD: whatever is sent becomes the
/// recipe, and an empty list clears it. That is what lets the panel treat
/// "remove this line" as an ordinary unsaved edit.
class TreatmentConsumableWriter {
  final Dio _dio;

  const TreatmentConsumableWriter(this._dio);

  Future<List<TreatmentConsumableModel>> sync({
    required int treatmentId,
    required List<TreatmentConsumableModel> consumables,
  }) async {
    try {
      final response = await _dio.put(
        '/treatments/$treatmentId/consumables',
        data: {
          'consumables': consumables.map((c) => c.toJson()).toList(),
        },
      );

      final list = response.data['data'] as List<dynamic>? ?? [];

      return list
          .map((e) => TreatmentConsumableModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } on DioException catch (e) {
      throw Exception(describeError(e, fallback: 'Could not save consumables.'));
    }
  }
}

final treatmentConsumableWriterProvider =
    Provider<TreatmentConsumableWriter>((ref) {
  return TreatmentConsumableWriter(ref.read(dioProvider));
});
