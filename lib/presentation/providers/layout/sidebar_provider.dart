// lib/presentation/providers/layout/sidebar_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the main-layout sidebar is collapsed to an icon rail.
///
/// Lives outside the widget tree because two widgets drive it: the sidebar
/// itself renders from it and the topbar toggle writes to it. Not autoDispose —
/// MainLayout is rebuilt on every go_router transition and the choice must
/// survive those.
final sidebarCollapsedProvider =
    StateNotifierProvider<SidebarCollapsedNotifier, bool>((ref) {
  return SidebarCollapsedNotifier();
});

class SidebarCollapsedNotifier extends StateNotifier<bool> {
  /// Starts expanded and widens/narrows once the stored value arrives. Reading
  /// prefs is async, so a synchronous default is unavoidable; expanded is the
  /// safer one to flash because it is the state that shows labels.
  SidebarCollapsedNotifier() : super(false) {
    _restore();
  }

  static const _prefsKey = 'sidebar_collapsed';

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefsKey);
      if (saved != null && mounted) state = saved;
    } catch (_) {
      // Storage unavailable (private browsing, quota). Stay expanded.
    }
  }

  void toggle() => _set(!state);

  void collapse() => _set(true);

  void expand() => _set(false);

  void _set(bool value) {
    if (state == value) return;
    state = value;
    _persist(value);
  }

  Future<void> _persist(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {
      // A failed write only costs the preference on next load.
    }
  }
}
