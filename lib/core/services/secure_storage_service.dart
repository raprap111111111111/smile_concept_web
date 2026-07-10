// lib/core/services/secure_storage_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Hybrid storage service:
/// - Web  → SharedPreferences (reliable localStorage persistence)
/// - Mobile → FlutterSecureStorage (encrypted keychain / EncryptedSharedPreferences)
class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _secureStorage;

  SecureStorageService()
      : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ─── Access Token ────────────────────────────────────────
  Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      await prefs.setString(_accessTokenKey, token);
    } else {
      await _secureStorage.write(key: _accessTokenKey, value: token);
    }
    if (kDebugMode) {
      print('Saved token (${token.length} chars) '
          '${kIsWeb ? "[WEB/SharedPrefs]" : "[MOBILE/Secure]"}');
    }
  }

  Future<String?> getToken() async {
    String? token;
    if (kIsWeb) {
      final prefs = await _prefs;
      token = prefs.getString(_accessTokenKey);
    } else {
      token = await _secureStorage.read(key: _accessTokenKey);
    }
    if (kDebugMode) {
      print('🔍 getToken → ${token != null ? "FOUND (${token.length} chars)" : "NULL"}');
    }
    return token;
  }

  Future<void> deleteToken() async {
    if (kIsWeb) {
      final prefs = await _prefs;
      await prefs.remove(_accessTokenKey);
    } else {
      await _secureStorage.delete(key: _accessTokenKey);
    }
  }

  // ─── Refresh Token ───────────────────────────────────────
  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      await prefs.setString(_refreshTokenKey, token);
    } else {
      await _secureStorage.write(key: _refreshTokenKey, value: token);
    }
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await _prefs;
      return prefs.getString(_refreshTokenKey);
    }
    return _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    if (kIsWeb) {
      final prefs = await _prefs;
      await prefs.remove(_refreshTokenKey);
    } else {
      await _secureStorage.delete(key: _refreshTokenKey);
    }
  }

  // ─── Session ─────────────────────────────────────────────
  Future<bool> hasValidSession() async {
    final token = await getToken();
    final valid = token != null && token.isNotEmpty;
    if (kDebugMode) {
      print('🔑 hasValidSession → $valid');
    }
    return valid;
  }

  Future<void> clearAll() async {
    if (kIsWeb) {
      final prefs = await _prefs;
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
    } else {
      await _secureStorage.deleteAll();
    }
    if (kDebugMode) {
      print('All tokens cleared');
    }
  }
}