import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile_concept_web/core/errors/error_message.dart';
import 'package:smile_concept_web/core/errors/exceptions.dart';
import 'package:smile_concept_web/core/errors/failures.dart';

DioException _dioWith({int? status, dynamic body, DioExceptionType? type}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: type ?? DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  group('describeError', () {
    test('never leaks the "Instance of" default toString', () {
      final failure = ApiFailure(message: 'x', code: 'C');
      expect(describeError(failure), isNot(contains('Instance of')));
      expect('$failure', 'x');
    });

    test('replaces a stack trace or SQL error with a plain sentence', () {
      const sql = ApiException(
        message: "SQLSTATE[23000]: Integrity constraint violation: 1452",
        code: 'SERVER_ERROR',
        statusCode: 500,
      );
      final text = describeError(sql);
      expect(text, isNot(contains('SQLSTATE')));
      expect(text, contains('our end'));
    });

    test('overrides boilerplate 403 text with actionable wording', () {
      const denied = ApiException(
        message: 'This action is unauthorized.',
        code: 'SERVER_ERROR',
        statusCode: 403,
      );
      expect(describeError(denied), contains('permission'));
      expect(isPermissionError(denied), isTrue);
      expect(isRetryable(denied), isFalse);
    });

    test('keeps validation text, which is the actionable part of a 422', () {
      final e = _dioWith(status: 422, body: {
        'message': 'The given data was invalid.',
        'errors': {
          'email': ['The email has already been taken.'],
        },
      });
      expect(describeError(e), contains('email has already been taken'));
    });

    test('summarises more than two validation messages', () {
      final e = _dioWith(status: 422, body: {
        'errors': {
          'a': ['A failed.'],
          'b': ['B failed.'],
          'c': ['C failed.'],
          'd': ['D failed.'],
        },
      });
      expect(describeError(e), contains('(+2 more)'));
    });

    test('explains a connection failure without naming Laravel or CORS', () {
      final e = _dioWith(type: DioExceptionType.connectionError);
      final text = describeError(e);
      expect(text, contains('internet connection'));
      expect(text.toLowerCase(), isNot(contains('cors')));
      expect(isRetryable(e), isTrue);
    });

    test('falls back to the caller phrasing when the body is an HTML page', () {
      final e = _dioWith(status: 404, body: '<!DOCTYPE html><html>...');
      expect(describeError(e), contains("couldn't find"));
    });

    test('uses the caller fallback when there is nothing else to say', () {
      expect(
        describeError(Exception(), fallback: 'Could not load doctors'),
        'Could not load doctors',
      );
    });

    test('strips the "Exception: " prefix Dart adds', () {
      expect(
        describeError(Exception('That time slot is already booked.')),
        'That time slot is already booked.',
      );
    });

    test('reads the status through every wrapper', () {
      final wrapped = DioException(
        requestOptions: RequestOptions(path: '/x'),
        error: const ApiException(message: 'm', code: 'C', statusCode: 401),
      );
      expect(errorStatusCode(wrapped), 401);
      expect(isSessionExpired(wrapped), isTrue);
      expect(describeError(wrapped), contains('sign in again'));
    });
  });

  group('humanizeMessage', () {
    test('passes ordinary sentences through', () {
      expect(humanizeMessage('Patient saved.'), 'Patient saved.');
    });

    test('swaps a bare class name for the fallback', () {
      expect(
        humanizeMessage('_TypeError', fallback: 'Could not save'),
        'Could not save',
      );
    });
  });
}
