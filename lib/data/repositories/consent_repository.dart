// lib/data/repositories/consent_repository.dart
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/local/consent_local_datasource.dart';
import '../datasources/remote/consent_remote_datasource.dart';
import '../models/consent/consent_sign_request.dart';
import '../models/consent/consent_template_model.dart';
import '../models/consent/paginated_consent_result.dart';
import '../models/consent/patient_consent_model.dart';

final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  return ConsentRepository(
    remote: ref.watch(consentRemoteDataSourceProvider),
    local: ref.watch(consentLocalDataSourceProvider),
  );
});

class ConsentRepository {
  final ConsentRemoteDataSource _remote;
  final ConsentLocalDataSource _local;

  ConsentRepository({
    required ConsentRemoteDataSource remote,
    required ConsentLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  /// Fetches paginated signed consents.
  ///
  /// Backend scopes results by the authenticated user's permissions:
  ///   - Patients only see their own consents
  ///   - Staff with `consent-form.viewAny` see all
  ///
  /// [search] — filters by patient name/email or template title
  /// [status] — 'valid' | 'voided' | null (all)
  Future<PaginatedConsentResult> getSignedConsents({
    int page = 1,
    int pageSize = 15,
    int? userId,
    int? appointmentId,
    int? consentTemplateId,
    String? search,
    String? status,
  }) {
    final offset = (page - 1) * pageSize;
    return _remote.getSignedConsents(
      userId: userId,
      appointmentId: appointmentId,
      consentTemplateId: consentTemplateId,
      search: search,
      status: status,
      offset: offset,
      limit: pageSize,
    );
  }

  Future<List<ConsentTemplateModel>> getTemplates() {
    return _remote.getTemplates();
  }

  Future<PatientConsentModel> getConsent(int id) async {
    try {
      final result = await _remote.getConsentById(id);
      await _local.cacheConsent(result);
      return result;
    } catch (e) {
      final cached = await _local.getCachedConsent(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<PatientConsentModel>> getByAppointment(int appointmentId) {
    return _remote.getByAppointment(appointmentId);
  }

  Future<PatientConsentModel> sign(ConsentSignRequest request) async {
    final result = await _remote.sign(request);
    await _local.cacheConsent(result);
    return result;
  }

  Future<PatientConsentModel> voidConsent(int id, String reason) async {
    final result = await _remote.voidConsent(id, reason);
    await _local.cacheConsent(result);
    return result;
  }

  /// Fetches PDF bytes via authenticated Dio.
  /// Use with `PdfViewerPage(bytes: ...)` to render in-app.
  Future<Uint8List> getConsentPdfBytes(int id) {
    return _remote.getPdfBytes(id);
  }
}