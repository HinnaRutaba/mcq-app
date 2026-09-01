import 'dart:io';

import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';
import '../storage/secure_token_store.dart';
import 'api_constants.dart';
import 'api_envelope.dart';
import 'api_exception.dart';

/// The single Dio client. Build this first and get it right, and every
/// screen afterwards is straightforward.
///
/// The four responses that matter are handled here, once:
///
/// * **401** — the token is dead. Clear the keychain, go to login, remember
///   where the officer was so they come back to it. This is the *only*
///   status that signs them out.
/// * **403** — a refusal of one action. Do not navigate, do not clear
///   anything; show the server's own sentence. Page-level authorisation is
///   already handled by hiding actions the officer lacks permission for, so
///   a 403 reaching here is always an action — and this system uses 403 for
///   domain controls as well as missing permissions, so a navigating 403
///   would fire on perfectly ordinary refusals every officer will hit.
/// * **409** — a domain refusal. Left for the screen: it usually needs a
///   dialog, not a toast.
/// * **422** — validation. [ApiException.errors] binds onto the form.
class ApiClient {
  ApiClient({required SecureTokenStore tokenStore, Dio? dio})
      : _tokenStore = tokenStore,
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                headers: {'Accept': 'application/json'},
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
                sendTimeout: ApiConstants.sendTimeout,
              ),
            ) {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: _onRequest,
            onError: _onError,
          ),
        );
  }

  final Dio dio;
  final SecureTokenStore _tokenStore;

  /// Called on a 401 — the session controller clears the keychain and sends
  /// the officer to login, once, with an explanation.
  void Function(ApiException error)? onUnauthenticated;

  /// Called on a 403 — show [ApiException.message] as a toast/snackbar.
  /// Never navigate.
  void Function(ApiException error)? onForbidden;

  bool _expiring = false;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = _tokenStore.cachedToken ?? await _tokenStore.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    // The server returns enum labels, validation messages and domain
    // refusals already translated into this language. Never translate a
    // server string on the client — it drifts from the web application.
    options.headers['Accept-Language'] = AppTranslations.active.code;
    handler.next(options);
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) {
    final failure = ApiException.fromDio(error);

    switch (failure.kind) {
      case ApiFailureKind.unauthenticated:
        // The token is gone, expired or revoked — a password change, an
        // administrator reset, a deactivation, or 30 days elapsed. Fire
        // once however many requests were in flight.
        if (!_expiring) {
          _expiring = true;
          onUnauthenticated?.call(failure);
        }
        break;
      case ApiFailureKind.forbidden:
        onForbidden?.call(failure);
        break;
      case ApiFailureKind.conflict:
      case ApiFailureKind.validation:
        // Deliberately untouched: the screen handles these.
        break;
      default:
        break;
    }

    handler.next(error.copyWith(error: failure));
  }

  /// Lets the session controller re-arm the 401 handler after a fresh sign
  /// in, so a later expiry is reported again.
  void resetExpiryLatch() => _expiring = false;

  // --- Verbs ------------------------------------------------------------

  /// A GET, retried twice on a connection timeout with a short backoff.
  /// Bazaar mobile data is slow; 15 seconds to connect is not generous, it
  /// is realistic.
  Future<ApiEnvelope> get(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        final response = await dio.get<dynamic>(
          path,
          queryParameters: _clean(query),
          cancelToken: cancelToken,
        );
        return ApiEnvelope.fromResponse(response);
      } on DioException catch (error) {
        final failure = _failureOf(error);
        final retryable = failure.isNetwork &&
            error.type != DioExceptionType.receiveTimeout &&
            attempt < ApiConstants.getRetryCount;
        if (!retryable) throw failure;
        attempt++;
        await Future<void>.delayed(ApiConstants.getRetryBackoff * attempt);
      }
    }
  }

  /// A POST. **Never retried by the transport** — the retry path for a
  /// field write is the offline queue, which carries `client_action_uuid`
  /// so the server replays the record it already made instead of creating
  /// a second one.
  Future<ApiEnvelope> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.post<dynamic>(
        path,
        data: body,
        queryParameters: _clean(query),
        cancelToken: cancelToken,
        options: Options(contentType: Headers.jsonContentType),
      );
      return ApiEnvelope.fromResponse(response);
    } on DioException catch (error) {
      throw _failureOf(error);
    }
  }

  Future<ApiEnvelope> put(String path, {Object? body}) async {
    try {
      final response = await dio.put<dynamic>(
        path,
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );
      return ApiEnvelope.fromResponse(response);
    } on DioException catch (error) {
      throw _failureOf(error);
    }
  }

  /// A `multipart/form-data` POST — the evidence upload and an inspection.
  ///
  /// The server renames the file to a fresh ULID and validates the sniffed
  /// type, so the filename and declared content type are not worth
  /// setting carefully. SVG is rejected deliberately.
  Future<ApiEnvelope> postMultipart(
    String path, {
    required Map<String, dynamic> fields,
    Map<String, File> files = const {},
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final form = FormData.fromMap({
      ..._clean(fields) ?? const {},
      for (final entry in files.entries)
        entry.key: await MultipartFile.fromFile(entry.value.path),
    });
    try {
      final response = await dio.post<dynamic>(
        path,
        data: form,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
      return ApiEnvelope.fromResponse(response);
    } on DioException catch (error) {
      throw _failureOf(error);
    }
  }

  ApiException _failureOf(DioException error) =>
      error.error is ApiException
          ? error.error as ApiException
          : ApiException.fromDio(error);

  /// Drops null entries so an optional filter is simply absent rather than
  /// sent as the string "null".
  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final cleaned = <String, dynamic>{};
    query.forEach((key, value) {
      if (value != null) cleaned[key] = value;
    });
    return cleaned;
  }
}
