import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/consent/consent_sign_request.dart';
import '../../../data/models/consent/patient_consent_model.dart';
import '../../../data/repositories/consent_repository.dart';
import 'patient_consents_provider.dart';

class ConsentActionState {
  final bool isSubmitting;
  final String? error;
  final PatientConsentModel? lastResult;

  const ConsentActionState({
    this.isSubmitting = false,
    this.error,
    this.lastResult,
  });

  ConsentActionState copyWith({
    bool? isSubmitting,
    String? error,
    PatientConsentModel? lastResult,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return ConsentActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
    );
  }
}

class ConsentActionNotifier extends StateNotifier<ConsentActionState> {
  final Ref _ref;
  ConsentActionNotifier(this._ref) : super(const ConsentActionState());

  Future<PatientConsentModel?> sign(ConsentSignRequest request) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await _ref.read(consentRepositoryProvider).sign(request);
      state = state.copyWith(isSubmitting: false, lastResult: result);
      _invalidateLists(request.appointmentId);
      return result;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _readable(e));
      return null;
    }
  }

  Future<PatientConsentModel?> voidConsent(int id, String reason) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result =
          await _ref.read(consentRepositoryProvider).voidConsent(id, reason);
      state = state.copyWith(isSubmitting: false, lastResult: result);
      _invalidateLists(null);
      return result;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _readable(e));
      return null;
    }
  }

  void reset() => state = const ConsentActionState();

  void _invalidateLists(int? appointmentId) {
    _ref.invalidate(patientConsentsProvider);
    if (appointmentId != null) {
      _ref.invalidate(appointmentConsentsProvider(appointmentId));
    }
  }

  String _readable(Object e) => e
      .toString()
      .replaceAll('Exception: ', '')
      .replaceAll('DioException: ', '');
}

final consentActionProvider =
    StateNotifierProvider<ConsentActionNotifier, ConsentActionState>((ref) {
  return ConsentActionNotifier(ref);
});