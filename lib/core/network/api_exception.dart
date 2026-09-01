import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';

/// How a failed request should be *handled*, which is not the same thing as
/// what went wrong technically.
enum ApiFailureKind {
  /// 401 — the token is gone, expired or revoked. The only status that
  /// signs the officer out.
  unauthenticated,

  /// 403 — a refusal of one action, including domain controls (approving
  /// your own adjustment is a 403 because it is a control, not a state).
  /// Show the message; never navigate, never clear anything.
  forbidden,

  /// 409 — a domain refusal. The request was well-formed, the officer had
  /// permission, the server is healthy; the state of the world is simply
  /// not one where the operation makes sense. Deserves a dialog, not a
  /// toast: the officer has to read it standing in front of a shopkeeper.
  conflict,

  /// 422 — validation. Bind [errors] onto the form.
  validation,

  /// 404 — asked for something that is not there.
  notFound,

  /// 5xx — report it, never retry automatically.
  server,

  /// No usable connection, or the request timed out.
  network,

  other,
}

/// A failed API call, already classified for the UI.
///
/// [message] is the server's own sentence whenever there is one. It is
/// written for the officer to read and is already translated into their
/// language — show it verbatim. Never replace it with "Something went
/// wrong": it names what was refused and usually what to do instead.
class ApiException implements Exception {
  ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.code,
    this.errors = const {},
    this.fromServer = false,
  });

  final ApiFailureKind kind;
  final String message;
  final int? statusCode;

  /// The machine-readable `code` the server sends alongside a 403/409.
  final String? code;

  /// 422 only: `{"field": ["…"]}`, ready to bind onto form fields.
  final Map<String, List<String>> errors;

  /// True when [message] is the server's own sentence (show verbatim),
  /// false when it is one of our own fallbacks for a transport failure.
  final bool fromServer;

  bool get isConflict => kind == ApiFailureKind.conflict;
  bool get isValidation => kind == ApiFailureKind.validation;
  bool get isForbidden => kind == ApiFailureKind.forbidden;
  bool get isUnauthenticated => kind == ApiFailureKind.unauthenticated;
  bool get isNetwork => kind == ApiFailureKind.network;

  /// The first message for [field], if the server rejected it.
  String? errorFor(String field) => errors[field]?.firstOrNull;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final status = response?.statusCode;
    final data = response?.data;
    final body = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final serverMessage = body['message'] is String
        ? body['message'] as String
        : null;
    final code = body['code'] is String ? body['code'] as String : null;

    Map<String, List<String>> parseErrors() {
      final raw = body['errors'];
      if (raw is! Map) return const {};
      return raw.map(
        (key, value) => MapEntry(
          '$key',
          value is List
              ? value.map((entry) => '$entry').toList()
              : <String>['$value'],
        ),
      );
    }

    ApiFailureKind kind;
    switch (status) {
      case 401:
        kind = ApiFailureKind.unauthenticated;
        break;
      case 403:
        kind = ApiFailureKind.forbidden;
        break;
      case 404:
        kind = ApiFailureKind.notFound;
        break;
      case 409:
        kind = ApiFailureKind.conflict;
        break;
      case 422:
        kind = ApiFailureKind.validation;
        break;
      default:
        if (status != null && status >= 500) {
          kind = ApiFailureKind.server;
        } else if (_isTransport(error.type)) {
          kind = ApiFailureKind.network;
        } else {
          kind = ApiFailureKind.other;
        }
    }

    final fallback = switch (kind) {
      ApiFailureKind.unauthenticated => t('error.sessionExpired'),
      ApiFailureKind.forbidden => t('error.notPermitted'),
      ApiFailureKind.server => t('error.server'),
      ApiFailureKind.network => error.type == DioExceptionType.connectionError
          ? t('error.network')
          : t('error.timeout'),
      _ => t('error.unexpected'),
    };

    return ApiException(
      kind: kind,
      message: serverMessage ?? fallback,
      statusCode: status,
      code: code,
      errors: parseErrors(),
      fromServer: serverMessage != null,
    );
  }

  static bool _isTransport(DioExceptionType type) =>
      type == DioExceptionType.connectionTimeout ||
      type == DioExceptionType.sendTimeout ||
      type == DioExceptionType.receiveTimeout ||
      type == DioExceptionType.connectionError;

  @override
  String toString() => 'ApiException(${statusCode ?? kind.name}): $message';
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
