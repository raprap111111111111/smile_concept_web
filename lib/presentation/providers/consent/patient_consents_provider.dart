// lib/presentation/providers/consent/patient_consents_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/consent/paginated_consent_result.dart';
import '../../../data/models/consent/patient_consent_model.dart';
import '../../../data/repositories/consent_repository.dart';

class PatientConsentsParams {
  final int page;
  final int pageSize;
  final int? userId;
  final int? appointmentId;
  final int? consentTemplateId;
  final String? search;
  final String? status; // 'valid' | 'voided' | null

  const PatientConsentsParams({
    this.page = 1,
    this.pageSize = 15,
    this.userId,
    this.appointmentId,
    this.consentTemplateId,
    this.search,
    this.status,
  });

  PatientConsentsParams copyWith({
    int? page,
    int? pageSize,
    int? userId,
    int? appointmentId,
    int? consentTemplateId,
    String? search,
    String? status,
    bool clearSearch = false,
    bool clearStatus = false,
  }) {
    return PatientConsentsParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      userId: userId ?? this.userId,
      appointmentId: appointmentId ?? this.appointmentId,
      consentTemplateId: consentTemplateId ?? this.consentTemplateId,
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientConsentsParams &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          pageSize == other.pageSize &&
          userId == other.userId &&
          appointmentId == other.appointmentId &&
          consentTemplateId == other.consentTemplateId &&
          search == other.search &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
        page,
        pageSize,
        userId,
        appointmentId,
        consentTemplateId,
        search,
        status,
      );
}

/// Filter state for the consent list page (search + status).
final consentFilterProvider =
    StateProvider.autoDispose<PatientConsentsParams>((ref) {
  return const PatientConsentsParams();
});

/// Backend-scoped paginated consents.
final patientConsentsProvider = FutureProvider.autoDispose
    .family<PaginatedConsentResult, PatientConsentsParams>((ref, params) async {
  return ref.watch(consentRepositoryProvider).getSignedConsents(
        page: params.page,
        pageSize: params.pageSize,
        userId: params.userId,
        appointmentId: params.appointmentId,
        consentTemplateId: params.consentTemplateId,
        search: params.search,
        status: params.status,
      );
});

/// Consents for a specific appointment — used on appointment detail page.
final appointmentConsentsProvider = FutureProvider.autoDispose
    .family<List<PatientConsentModel>, int>((ref, appointmentId) async {
  return ref.watch(consentRepositoryProvider).getByAppointment(appointmentId);
});