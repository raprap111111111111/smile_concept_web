import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Lightweight logger that survives the VS Code Dart debugger.
///
/// Why not `logger` package?
///   PrettyPrinter walks the stack + formats via toString(),
///   which crashes the Dart VM under DDC when the message is large
///   (e.g. base64 signatures, PDF blobs).
///
/// This logger just forwards short strings to dart:developer.log(),
/// which is safe for the debugger and shows nicely in DevTools.
class AppLogger {
  /// Global switch. Set to false to silence all non-error logs.
  static bool enabled = kDebugMode;

  /// Max chars per log message. Anything longer is truncated so the
  /// debugger never chokes on huge payloads.
  static const int _maxLen = 500;

  // ─── Public API (drop-in replacement for logger package) ────────────────

  static void verbose(String message) => _log('TRACE', message);
  static void debug(String message)   => _log('DEBUG', message);
  static void info(String message)    => _log('INFO',  message);
  static void warning(String message) => _log('WARN',  message);
  static void wtf(String message)     => _log('FATAL', message);

  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    // Errors always log, even when disabled
    final msg = error == null ? message : '$message → $error';
    if (kDebugMode) {
      developer.log(
        _clip(msg),
        name: 'ERROR',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  static void _log(String level, String message) {
    if (!enabled) return;
    if (!kDebugMode) return;
    developer.log(_clip(message), name: level);
  }

  static String _clip(String s) {
    if (s.length <= _maxLen) return s;
    return '${s.substring(0, _maxLen)}… [+${s.length - _maxLen} chars]';
  }
}