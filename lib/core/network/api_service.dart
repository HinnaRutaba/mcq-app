import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/api_response.dart';
import '../storage/secure_storage_service.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'api_file.dart';
import 'api_log_interceptor.dart';
import 'auth_interceptor.dart';
import 'connectivity_interceptor.dart';

/// The single HTTP door out of the app.
///
/// Every repository goes through here and nowhere else, which puts five things
/// in exactly one place: failing fast when the handset has no route out (via
/// [ConnectivityInterceptor]), the bearer token (via [AuthInterceptor]),
/// unwrapping the `{"data": …, "message": "…"}` envelope, turning a failure
/// into an [ApiException] carrying the server's per-field `errors`, and
/// building multipart bodies for the writes that carry a photograph.
///
/// Nothing above the data layer should ever hold a [Dio] instance.
class ApiService {
  ApiService({
    required SecureStorageService storage,
    Dio? client,
    VoidCallback? onUnauthorized,
    ApiLogLevel logLevel = ApiLogLevel.full,
    NetworkProbe? networkProbe,
  }) : dio = client ?? Dio(defaultOptions()) {
    // First in the chain. A call with nowhere to go should not reach the
    // keychain, and the officer should not wait out the connect timeout to be
    // told what the handset already knew.
    dio.interceptors.add(
      ConnectivityInterceptor(probe: networkProbe ?? PlatformNetworkProbe()),
    );
    dio.interceptors.add(
      AuthInterceptor(storage: storage, onUnauthorized: onUnauthorized),
    );
    // Debug only, and not merely silenced in release — not installed at all.
    // The logs are unredacted: bearer tokens, passwords and shopkeepers' CNICs
    // go to the console verbatim, which is useful at a desk and unacceptable on
    // a handset in the field. `kDebugMode` is a const, so this whole call is
    // compiled out of a release build.
    if (kDebugMode) {
      // Drop to [ApiLogLevel.summary] where full bodies would drown the output
      // — a test run, mostly.
      dio.interceptors.add(ApiLogInterceptor(level: logLevel));
    }
  }

  final Dio dio;

  /// The options every call runs under. Public so that a caller injecting its
  /// own [Dio] — a test with a stub adapter, say — starts from the real
  /// configuration rather than a second copy of it that can drift.
  static BaseOptions defaultOptions() => BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    sendTimeout: ApiConfig.sendTimeout,
    responseType: ResponseType.json,
    // Without this the server answers HTML on a validation failure and the
    // per-field `errors` are lost.
    headers: <String, String>{'Accept': 'application/json'},
  );

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? query,
    bool requiresAuth = true,
    CancelToken? cancelToken,
  }) => _send(
    'GET',
    path,
    query: query,
    requiresAuth: requiresAuth,
    cancelToken: cancelToken,
  );

  /// Sends JSON, or multipart when [files] is non-empty.
  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    List<ApiFile> files = const <ApiFile>[],
    bool requiresAuth = true,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) => _send(
    'POST',
    path,
    body: body,
    query: query,
    files: files,
    requiresAuth: requiresAuth,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
  );

  Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    List<ApiFile> files = const <ApiFile>[],
    bool requiresAuth = true,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) => _send(
    'PUT',
    path,
    body: body,
    query: query,
    files: files,
    requiresAuth: requiresAuth,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
  );

  Future<ApiResponse> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    List<ApiFile> files = const <ApiFile>[],
    bool requiresAuth = true,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) => _send(
    'PATCH',
    path,
    body: body,
    query: query,
    files: files,
    requiresAuth: requiresAuth,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
  );

  Future<ApiResponse> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool requiresAuth = true,
    CancelToken? cancelToken,
  }) => _send(
    'DELETE',
    path,
    body: body,
    query: query,
    requiresAuth: requiresAuth,
    cancelToken: cancelToken,
  );

  Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    List<ApiFile> files = const <ApiFile>[],
    bool requiresAuth = true,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final fields = _compact(body);
    final parameters = _compact(query);

    try {
      final response = await dio.request<dynamic>(
        path,
        data: files.isEmpty
            ? (fields.isEmpty ? null : fields)
            : await _multipart(fields, files),
        queryParameters: parameters.isEmpty ? null : parameters,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: Options(
          method: method,
          contentType: files.isEmpty
              ? Headers.jsonContentType
              : Headers.multipartFormDataContentType,
          extra: <String, dynamic>{
            AuthInterceptor.requiresAuthKey: requiresAuth,
          },
        ),
      );
      return ApiResponse.fromBody(
        response.data,
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<FormData> _multipart(
    Map<String, dynamic> fields,
    List<ApiFile> files,
  ) async {
    final form = FormData();
    _flatten(fields).forEach((String key, String value) {
      form.fields.add(MapEntry<String, String>(key, value));
    });
    for (final file in files) {
      form.files.add(
        MapEntry<String, MultipartFile>(file.field, await file.toMultipartFile()),
      );
    }
    return form;
  }

  /// Drops nulls, at every depth.
  ///
  /// The write endpoints declare most fields `nullable`, so a field the officer
  /// left blank should simply not be sent. Sending an explicit null instead
  /// risks a "must be a string" rejection on a field nobody filled in.
  static Map<String, dynamic> _compact(Map<String, dynamic>? source) {
    if (source == null) return const <String, dynamic>{};
    final result = <String, dynamic>{};
    source.forEach((String key, Object? value) {
      if (value == null) return;
      if (value is Map<String, dynamic>) {
        final nested = _compact(value);
        if (nested.isNotEmpty) result[key] = nested;
        return;
      }
      result[key] = value;
    });
    return result;
  }

  /// Flattens a nested body into the bracket notation a multipart request
  /// needs: `{'seal': {'seal_reason': 'x'}}` becomes `seal[seal_reason]=x`,
  /// which is how the API's `seal.seal_reason` rule reads it.
  ///
  /// Booleans go over as `1`/`0` — the string `"false"` is truthy to some
  /// form-data parsers.
  static Map<String, String> _flatten(
    Map<String, dynamic> source, [
    String prefix = '',
  ]) {
    final result = <String, String>{};
    source.forEach((String key, Object? value) {
      final name = prefix.isEmpty ? key : '$prefix[$key]';
      if (value == null) return;
      if (value is Map<String, dynamic>) {
        result.addAll(_flatten(value, name));
      } else if (value is Iterable) {
        var index = 0;
        for (final item in value) {
          if (item == null) continue;
          if (item is Map<String, dynamic>) {
            result.addAll(_flatten(item, '$name[$index]'));
          } else {
            result['$name[$index]'] = _scalar(item);
          }
          index++;
        }
      } else {
        result[name] = _scalar(value);
      }
    });
    return result;
  }

  static String _scalar(Object value) {
    if (value is bool) return value ? '1' : '0';
    return '$value';
  }
}
