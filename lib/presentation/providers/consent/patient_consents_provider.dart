import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/consent/paginated_consent_result.dart';
import '../../../data/models/consent/patient_consent_model.dart';
import '../../../data/repositories/consent_repository.dart';

class PatientConsentsParams {
  final int page;
  final int pageSize;
  final int? userId;
  final int? appointmentId;

  const PatientConsentsParams({
    this.page = 1,
    this.pageSize = 10,
    this.userId,
    this.appointmentId,
  });

  PatientConsentsParams copyWith({
    int? page,
    int? pageSize,
    int? userId,
    int? appointmentId,
  }) {
    return PatientConsentsParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      userId: userId ?? this.userId,
      appointmentId: appointmentId ?? this.appointmentId,
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
          appointmentId == other.appointmentId;

  @override
  int get hashCode => Object.hash(page, pageSize, userId, appointmentId);
}

/// Backend scopes results by authenticated user's permissions.
final patientConsentsProvider = FutureProvider.autoDispose
    .family<PaginatedConsentResult, PatientConsentsParams>((ref, params) async {
  return ref.watch(consentRepositoryProvider).getSignedConsents(
        page: params.page,
        pageSize: params.pageSize,
        userId: params.userId,
        appointmentId: params.appointmentId,
      );
});

/// Consents for a specific appointment — used on appointment detail page.
final appointmentConsentsProvider = FutureProvider.autoDispose
    .family<List<PatientConsentModel>, int>((ref, appointmentId) async {
  return ref.watch(consentRepositoryProvider).getByAppointment(appointmentId);
});