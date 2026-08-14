import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../data/models/settings/appointment_settings_model.dart';
import '../../../data/repositories/appointment_settings_repository.dart';

/// State for the appointment-settings form.
///
/// [saved] is the last server-confirmed model; [draft] is what the form is
/// editing. isDirty compares the two, which drives the Save button.
class AppointmentSettingsState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final Map<String, String> fieldErrors;
  final AppointmentSettingsModel? saved;
  final AppointmentSettingsModel? draft;
  final bool justSaved;

  const AppointmentSettingsState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.fieldErrors = const {},
    this.saved,
    this.draft,
    this.justSaved = false,
  });

  bool get isDirty => saved != null && draft != null && saved != draft;

  AppointmentSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    Map<String, String>? fieldErrors,
    AppointmentSettingsModel? saved,
    AppointmentSettingsModel? draft,
    bool? justSaved,
    bool clearError = false,
  }) {
    return AppointmentSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      fieldErrors: fieldErrors ?? this.fieldErrors,
      saved: saved ?? this.saved,
      draft: draft ?? this.draft,
      justSaved: justSaved ?? this.justSaved,
    );
  }
}

class AppointmentSettingsNotifier
    extends StateNotifier<AppointmentSettingsState> {
  final AppointmentSettingsRepository _repository;

  AppointmentSettingsNotifier(this._repository)
      : super(const AppointmentSettingsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true, fieldErrors: {});
    try {
      final settings = await _repository.getSettings();
      state = state.copyWith(
        isLoading: false,
        saved: settings,
        draft: settings,
      );
    } on Failure catch (f) {
      state = state.copyWith(isLoading: false, error: f.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// The form pushes every field change through here.
  void updateDraft(AppointmentSettingsModel draft) {
    state = state.copyWith(draft: draft, justSaved: false);
  }

  Future<bool> save() async {
    final draft = state.draft;
    if (draft == null || state.isSaving) return false;

    state = state.copyWith(isSaving: true, clearError: true, fieldErrors: {});
    try {
      final fresh = await _repository.updateSettings(draft);
      state = state.copyWith(
        isSaving: false,
        saved: fresh,
        draft: fresh,
        justSaved: true,
      );
      return true;
    } on ApiFailure catch (f) {
      state = state.copyWith(
        isSaving: false,
        error: f.message,
        fieldErrors: f.fieldErrors,
      );
      return false;
    } on Failure catch (f) {
      state = state.copyWith(isSaving: false, error: f.message);
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  void discardChanges() {
    final saved = state.saved;
    if (saved != null) {
      state = state.copyWith(draft: saved, fieldErrors: {}, clearError: true, justSaved: false);
    }
  }
}

final appointmentSettingsProvider = StateNotifierProvider<
    AppointmentSettingsNotifier, AppointmentSettingsState>((ref) {
  return AppointmentSettingsNotifier(
    ref.watch(appointmentSettingsRepositoryProvider),
  );
});
