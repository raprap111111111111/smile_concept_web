// lib/presentation/providers/setting/setting_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/setting_repository.dart';

// ═══════════════════════════════════════════════════════════════
// State
// ═══════════════════════════════════════════════════════════════

class SettingState {
  final List<Map<String, dynamic>> settings;
  final bool isLoading;
  final bool isUpdating;
  final String? error;

  const SettingState({
    this.settings = const [],
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
  });

  SettingState copyWith({
    List<Map<String, dynamic>>? settings,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    bool clearError = false,
  }) {
    return SettingState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Notifier
// ═══════════════════════════════════════════════════════════════

class SettingNotifier extends StateNotifier<SettingState> {
  final SettingRepository _repository;

  SettingNotifier(this._repository) : super(const SettingState()) {
    load();
  }

  /// Load all settings from backend.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final settings = await _repository.getSettings(limit: 200);
      state = state.copyWith(
        settings: settings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Update a single setting by key.
  Future<void> updateSetting(String key, String value) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      // Call backend
      final updated = await _repository.updateSetting(key, {'value': value});

      // ✅ Optimistically update the local list
      final newSettings = state.settings.map((s) {
        if (s['key'] == key) {
          return {...s, ...updated};
        }
        return s;
      }).toList();

      state = state.copyWith(
        settings: newSettings,
        isUpdating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Refresh from server.
  Future<void> refresh() => load();

  /// Filter settings by group(s).
  List<Map<String, dynamic>> filterByGroups(List<String> groups) {
    return state.settings.where((s) {
      final group = s['group']?.toString().toLowerCase() ?? 'general';
      return groups.contains(group);
    }).toList();
  }
}

// ═══════════════════════════════════════════════════════════════
// Provider
// ═══════════════════════════════════════════════════════════════

final settingNotifierProvider =
    StateNotifierProvider<SettingNotifier, SettingState>((ref) {
  final repo = ref.watch(settingRepositoryProvider);
  return SettingNotifier(repo);
});