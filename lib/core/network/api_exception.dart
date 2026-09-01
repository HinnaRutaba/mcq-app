import 'package:dio/dio.dart';

import '../utils/json_parse.dart';

/// What went wrong, in terms a caller can branch on without reading strings.
enum ApiFailure {
  /// No route to the server — aeroplane mode, dead bazaar signal.
  network,
  timeout,

  /// 401. The stored token is dead; the keychain has already been cleared.
  unauthorized,

  /// 403. Signed in, but this officer may not do that — most often a unit
  /// outside their posted bazaars.
  forbidden,
  notFound,

  /// 422, with per-field messages in [ApiException.errors].
  validation,
  conflict,
  server,
  cancelled,
  unknown,
}

/// A failed call, decoded from the API's failure envelope:
/// `{"message": "…", "code": "…", "errors": {"field": ["…"]}}` — flat, with no
/// nested `error` object.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.failure,
    this.code,
    this.statusCode,
    this.errors = const <String, List<String>>{},
  });

  final String message;
  final ApiFailure failure;

  /// The server's machine-readable code, when it sent one.
  final String? code;
  final int? statusCode;

  /// Field name -> messages, straight from `errors`. Feed these back onto the
  /// form fields they name rather than showing [message] alone.
  final Map<String, List<String>> errors;

  factory ApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final failure = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ApiFailure.timeout,
      DioExceptionType.connectionError => ApiFailure.network,
      DioExceptionType.cancel => ApiFailure.cancelled,
      _ => _failureForStatus(statusCode),
    };

    String? message;
    String? code;
    final errors = <String, List<String>>{};

    final body = error.response?.data;
    if (body is Map) {
      final json = Map<String, dynamic>.from(body);
      message = Json.string(json['message']);
      code = Json.string(json['code']);
      final raw = json['errors'];
      if (raw is Map) {
        raw.forEach((Object? field, Object? messages) {
          errors['$field'] = messages is List
              ? messages.map((Object? m) => '$m').toList()
              : <String>['$messages'];
        });
      }
    }

    return ApiException(
      message: message ?? _messageForFailure(failure),
      failure: failure,
      code: code,
      statusCode: statusCode,
      errors: errors,
    );
  }

  bool get isUnauthorized => failure == ApiFailure.unauthorized;
  bool get isValidation => failure == ApiFailure.validation;

  /// Whether retrying the same request could plausibly succeed. Field writes
  /// carry a `client_action_uuid` precisely so that retry is safe.
  bool get isRetryable =>
      failure == ApiFailure.network ||
      failure == ApiFailure.timeout ||
      failure == ApiFailure.server;

  /// The first message the server attached to [field], if any.
  String? errorFor(String field) {
    final messages = errors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  static ApiFailure _failureForStatus(int? statusCode) => switch (statusCode) {
    401 => ApiFailure.unauthorized,
    403 => ApiFailure.forbidden,
    404 => ApiFailure.notFound,
    409 => ApiFailure.conflict,
    422 => ApiFailure.validation,
    final int code when code >= 500 => ApiFailure.server,
    _ => ApiFailure.unknown,
  };

  static String _messageForFailure(ApiFailure failure) => switch (failure) {
    ApiFailure.network => 'No connection. The record is not saved yet.',
    ApiFailure.timeout => 'The server took too long to answer.',
    ApiFailure.unauthorized => 'Your session has ended. Please sign in again.',
    ApiFailure.forbidden => 'You do not have access to this.',
    ApiFailure.notFound => 'That record no longer exists.',
    ApiFailure.validation => 'Please check the details and try again.',
    ApiFailure.conflict => 'That has already been recorded.',
    ApiFailure.server => 'The server could not complete the request.',
    ApiFailure.cancelled => 'The request was cancelled.',
    ApiFailure.unknown => 'Something went wrong.',
  };

  @override
  String toString() =>
      'ApiException(${statusCode ?? failure.name}${code == null ? '' : ', $code'}): $message';
}
