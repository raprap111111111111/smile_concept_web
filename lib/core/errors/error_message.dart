// lib/core/errors/error_message.dart

import 'package:dio/dio.dart';

import 'exceptions.dart';

/// Turns whatever a provider threw into a line worth showing the user.
///
/// Widgets that render a bare "Failed to load X" hide the one fact that
/// explains the failure — a 403 from a missing permission and a dead API port
/// look identical. Everything here comes off [ApiException], which
/// `ErrorInterceptor` already attaches to every rejected request.
String describeError(Object? error) {
  final api = _asApiException(error);

  if (api == null) return error?.toString() ?? 'Unknown error';

  // Laravel answers a failed FormRequest::authorize() with a flat
  // "This action is unauthorized." — true but useless when several dropdowns
  // on one form each hit a different endpoint.
  if (api.statusCode == 403) {
    return 'Not permitted (403). Your role is missing the permission for '
        'this data — ask an admin to grant it.';
  }

  if (api.statusCode == 401) {
    return 'Session expired (401). Sign in again.';
  }

  return api.message;
}

/// True when the failure is an authorization refusal rather than a transport
/// or server fault — callers use this to offer "ask an admin" instead of
/// a retry button that can never succeed.
bool isPermissionError(Object? error) =>
    _asApiException(error)?.statusCode == 403;

ApiException? _asApiException(Object? error) {
  if (error is ApiException) return error;
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException) return inner;
  }
  return null;
}
