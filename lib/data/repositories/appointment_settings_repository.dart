import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_config.dart';
import '../../core/errors/error_message.dart';
import '../../core/errors/failures.dart';
import '../../core/network/dio_client.dart';
import '../models/settings/appointment_settings_model.dart';

final appointmentSettingsRepositoryProvider =
    Provider<AppointmentSettingsRepository>((ref) {
  return AppointmentSettingsRepository(ref.watch(dioProvider));
});

/// GET/PUT for the typed /appointment-settings endpoint.
/// Mirrors SettingRepository: Dio in, model out, ApiFailure on error.
class AppointmentSettingsRepository {
  final Dio dio;

  AppointmentSettingsRepository(this.dio);

  Future<AppointmentSettingsModel> getSettings() async {
    try {
      final response = await dio.get(ApiConfig.appointmentSettings);

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] ?? body;

      return AppointmentSettingsModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    } on DioException catch (e) {
      throw ApiFailure(
        message: describeError(e, fallback: 'Failed to load appointment settings'),
        code: 'APPOINTMENT_SETTINGS_FETCH_ERROR',
        statusCode: errorStatusCode(e),
      );
    }
  }

  /// Atomic save of the whole form. A 422 carries Laravel's validation bag,
  /// keyed by setting key; [fieldErrorsOf] turns it into field messages.
  Future<AppointmentSettingsModel> updateSettings(
    AppointmentSettingsModel settings,
  ) async {
    try {
      final response = await dio.put(
        ApiConfig.appointmentSettings,
        data: settings.toJson(),
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] ?? body;

      return AppointmentSettingsModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    } on DioException catch (e) {
      throw ApiFailure(
        message: describeError(e, fallback: 'Failed to save appointment settings'),
        code: 'APPOINTMENT_SETTINGS_UPDATE_ERROR',
        statusCode: errorStatusCode(e),
        fieldErrors: _fieldErrorsOf(e),
      );
    }
  }

  /// Laravel's 422 error bag as {setting_key: first message}, so the form can
  /// show each error inline next to its own field.
  static Map<String, String> _fieldErrorsOf(DioException e) {
    final data = e.response?.data;
    if (data is! Map || data['errors'] is! Map) return const {};

    final result = <String, String>{};
    (data['errors'] as Map).forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        result[key.toString()] = value.first.toString();
      }
    });
    return result;
  }
}
