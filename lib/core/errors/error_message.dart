// lib/core/errors/error_message.dart

import 'dart:async';

import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Turns whatever was thrown into a sentence a clinic receptionist can act on.
///
/// Every user-facing error string in the app should come through here. Raw
/// `e.toString()` leaks "Instance of 'ApiFailure'", Dart type errors, Laravel
/// stack traces and SQL state codes into snackbars — none of which tell the
/// user what to do next.
///
/// [fallback] is the caller's plain-language description of what was being
/// attempted ("Couldn't load doctors"), used when the failure carries nothing
/// human to say.
String describeError(Object? error, {String? fallback}) {
  final generic = fallback ?? 'Something went wrong. Please try again.';

  if (error == null) return generic;

  // Unwrap Dio's envelope first — ErrorInterceptor hangs our ApiException off
  // `DioException.error`, so the useful part is always one layer down.
  final unwrapped = _unwrap(error);

  final status = _statusOf(unwrapped);
  final raw = _messageOf(unwrapped);

  // Transport-level faults never carry a server message worth showing.
  final transport = _describeTransport(unwrapped);
  if (transport != null) return transport;

  if (status != null) {
    // For these codes the server's own wording is either boilerplate
    // ("This action is unauthorized.") or an internal detail, so ours wins.
    final override = _statusOverride(status);
    if (override != null) return override;

    // 4xx codes the server explains better than we can (validation messages,
    // business-rule violations) — but only if the message is fit to read.
    if (_isHumanReadable(raw)) return _tidy(raw!);

    return _statusFallback(status, generic);
  }

  if (_isHumanReadable(raw)) return _tidy(raw!);

  return generic;
}

/// HTTP status behind a failure, whatever wrapper it arrived in.
///
/// Repositories use this when re-throwing as [ApiFailure]: dropping the status
/// there is what made a 403 and a 500 read identically further up the stack.
int? errorStatusCode(Object? error) => _statusOf(_unwrap(error));

/// True when the failure is an authorization refusal rather than a transport
/// or server fault — callers use this to offer "ask an admin" instead of
/// a retry button that can never succeed.
bool isPermissionError(Object? error) => _statusOf(_unwrap(error)) == 403;

/// True when signing in again is the fix.
bool isSessionExpired(Object? error) {
  final status = _statusOf(_unwrap(error));
  return status == 401 || status == 419;
}

/// True when a retry has a realistic chance of succeeding — network blips and
/// server faults, as opposed to "you typed it wrong" or "you can't do that".
bool isRetryable(Object? error) {
  final unwrapped = _unwrap(error);
  if (_describeTransport(unwrapped) != null) return true;
  final status = _statusOf(unwrapped);
  return status != null && status >= 500;
}

// ─────────────────────────── unwrapping ───────────────────────────

Object? _unwrap(Object? error) {
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException) return inner;
    // Keep the DioException itself: its `type` and `response` still classify
    // the failure even when nothing custom was attached.
    return error;
  }
  return error;
}

int? _statusOf(Object? error) {
  if (error is ApiException) return error.statusCode;
  if (error is ApiFailure) return error.statusCode;
  if (error is DioException) return error.response?.statusCode;
  return null;
}

String? _messageOf(Object? error) {
  if (error is ApiException) return error.message;
  if (error is Failure) return error.message;
  if (error is String) return error;
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final validation = _firstValidationMessage(data);
      if (validation != null) return validation;
      final message = data['message'];
      if (message is String) return message;
    }
    return error.message;
  }
  return error?.toString();
}

/// Laravel returns `{"message": "...", "errors": {"field": ["..."]}}` on 422.
/// The per-field text is the specific one ("The email has already been
/// taken."); the top-level message is often just "The given data was invalid."
String? _firstValidationMessage(Map data) {
  final errors = data['errors'];
  if (errors is! Map || errors.isEmpty) return null;

  final messages = <String>[];
  for (final entry in errors.entries) {
    final value = entry.value;
    if (value is List) {
      messages.addAll(value.whereType<String>());
    } else if (value is String) {
      messages.add(value);
    }
  }
  if (messages.isEmpty) return null;
  // Two is enough for a snackbar; more and the toast scrolls off-screen.
  if (messages.length <= 2) return messages.join(' ');
  return '${messages.take(2).join(' ')} (+${messages.length - 2} more)';
}

// ─────────────────────────── classification ───────────────────────────

/// Failures that happened before any HTTP status existed.
String? _describeTransport(Object? error) {
  if (error is TimeoutException) {
    return 'The server took too long to respond. Please try again.';
  }
  // `dart:io` can't be imported in a web build, so SocketException — which
  // still occurs on desktop/mobile targets — is matched by name.
  if (error.runtimeType.toString() == 'SocketException') {
    return 'Cannot reach the server. Check your internet connection and try '
        'again.';
  }

  if (error is ApiException) {
    switch (error.code) {
      case 'TIMEOUT_ERROR':
        return 'The server took too long to respond. Please try again.';
      case 'API_CONNECTION_ERROR':
        return 'Cannot reach the server. Check your internet connection and '
            'try again.';
    }
    return null;
  }

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your internet connection and '
            'try again.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      default:
        return null;
    }
  }

  return null;
}

/// Codes where our wording beats whatever the server said.
String? _statusOverride(int status) {
  switch (status) {
    case 401:
      return 'Your session has expired. Please sign in again.';
    case 403:
      return "You don't have permission to do this. Ask an administrator to "
          'grant you access.';
    case 404:
      return "We couldn't find that record. It may have been deleted by "
          'someone else.';
    case 419:
      return 'Your session timed out. Refresh the page and try again.';
    case 429:
      return "You're doing that too quickly. Wait a moment and try again.";
    case 500:
      return 'Something went wrong on our end. Please try again in a moment.';
    case 502:
    case 503:
    case 504:
      return 'The server is temporarily unavailable. Please try again in a '
          'few minutes.';
    default:
      return null;
  }
}

/// Used when the server's message for this code was unusable.
String _statusFallback(int status, String generic) {
  switch (status) {
    case 400:
      return "That request wasn't valid. Check the details and try again.";
    case 409:
      return 'This conflicts with existing data. Refresh the page and try '
          'again.';
    case 413:
      return 'That file is too large to upload.';
    case 422:
      return 'Some details are missing or invalid. Check the highlighted '
          'fields.';
    default:
      if (status >= 500) {
        return 'Something went wrong on our end. Please try again in a moment.';
      }
      return generic;
  }
}

/// Rejects strings that are diagnostics rather than sentences. These are the
/// shapes that used to reach users verbatim.
bool _isHumanReadable(String? raw) {
  if (raw == null) return false;
  final text = _tidy(raw);
  if (text.isEmpty) return false;

  const technical = [
    'instance of',
    'sqlstate',
    'stack trace',
    'nosuchmethoderror',
    'null check operator',
    'is not a subtype',
    '_typeerror',
    'rangeerror',
    'formatexception',
    'dioexception',
    'xmlhttprequest',
    'failed host lookup',
    'connection refused',
    'unhandled exception',
    'undefined method',
    'undefined index',
    'call to a member function',
    'syntax error',
    '<!doctype',
    '<html',
    '#0 ',
    'package:',
    'php warning',
    'php fatal',
  ];

  final lower = text.toLowerCase();
  for (final marker in technical) {
    if (lower.contains(marker)) return false;
  }

  // A bare class name ("ApiFailure", "_TypeError") is not a message. Checked
  // by shape rather than by "has no spaces", so a short real message survives.
  // The leading name is optional so a bare `Exception()` — whose toString is
  // just "Exception" — is caught alongside "ApiFailure" and "_TypeError".
  if (!text.contains(' ') &&
      RegExp(r'^_?[A-Za-z]*(Exception|Error|Failure)$').hasMatch(text)) {
    return false;
  }

  return true;
}

/// Sanitizes a string that is already destined for the user — used by toast
/// helpers that receive text rather than a thrown object. Technical noise is
/// swapped for [fallback]; ordinary sentences pass through untouched.
String humanizeMessage(String message, {String? fallback}) =>
    _isHumanReadable(message)
        ? _tidy(message)
        : (fallback ?? 'Something went wrong. Please try again.');

/// Strips the exception prefixes Dart and our own layers bolt on.
String _tidy(String raw) {
  var text = raw.trim();
  for (final prefix in const [
    'Exception: ',
    'ApiFailure: ',
    'ApiException: ',
    'Bad state: ',
    'DioException: ',
  ]) {
    while (text.startsWith(prefix)) {
      text = text.substring(prefix.length).trim();
    }
  }
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
