// lib/data/datasources/local/appointment_local_datasource.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/appointment/appointment_model.dart';

final appointmentLocalDataSourceProvider =
    Provider<AppointmentLocalDataSource>((ref) {
  return AppointmentLocalDataSource();
});

class AppointmentLocalDataSource {
  // ─── In-memory cache (no Hive needed) ───────────────────────────
  final Map<String, AppointmentModel> _cache = {};

  // ─── Cache list ──────────────────────────────────────────────────
  Future<void> cacheAppointments(List<AppointmentModel> appointments) async {
    _cache.clear();
    for (final appointment in appointments) {
      _cache[appointment.id.toString()] = appointment;
    }
  }

  // ─── Get all cached ──────────────────────────────────────────────
  Future<List<AppointmentModel>> getCachedAppointments() async {
    return _cache.values.toList();
  }

  // ─── Get single cached ───────────────────────────────────────────
  Future<AppointmentModel?> getCachedAppointment(String id) async {
    return _cache[id];
  }

  // ─── Cache single ────────────────────────────────────────────────
  Future<void> cacheAppointment(AppointmentModel appointment) async {
    _cache[appointment.id.toString()] = appointment;
  }

  // ─── Delete single ───────────────────────────────────────────────
  Future<void> deleteAppointment(String id) async {
    _cache.remove(id);
  }

  // ─── Clear all ───────────────────────────────────────────────────
  Future<void> clearCache() async {
    _cache.clear();
  }
}