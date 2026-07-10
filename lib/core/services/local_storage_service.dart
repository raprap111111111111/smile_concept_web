import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

class LocalStorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // User Preferences
  Future<void> setUserPreferences(Map<String, dynamic> preferences) async {
    await _prefs.setString('user_preferences', preferences.toString());
  }

  Map<String, dynamic>? getUserPreferences() {
    final data = _prefs.getString('user_preferences');
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  // Theme
  Future<void> setTheme(String theme) async {
    await _prefs.setString('app_theme', theme);
  }

  String? getTheme() => _prefs.getString('app_theme');

  // Language
  Future<void> setLanguage(String language) async {
    await _prefs.setString('app_language', language);
  }

  String? getLanguage() => _prefs.getString('app_language');

  // Last Selected Branch
  Future<void> setLastSelectedBranch(String branchId) async {
    await _prefs.setString('last_branch', branchId);
  }

  String? getLastSelectedBranch() => _prefs.getString('last_branch');

  // Clear all
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}