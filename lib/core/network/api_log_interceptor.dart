import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// One line per call in debug builds: method, path, status, duration.
///
/// Deliberately logs no headers and no bodies. This app's traffic carries
/// bearer tokens, passwords, CNICs and mobile numbers, none of which belong in
/// a device log — so the interceptor records only what is useful for spotting
/// a slow or failing endpoint.
class ApiLogInterceptor extends Interceptor {
  static const String _startedAtKey = 'mcq.started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log(
      response.requestOptions,
      '${response.statusCode}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      err.requestOptions,
      '${err.response?.statusCode ?? err.type.name} FAILED',
    );
    handler.next(err);
  }

  void _log(RequestOptions options, String outcome) {
    if (!kDebugMode) return;
    final startedAt = options.extra[_startedAtKey];
    final elapsed = startedAt is DateTime
        ? ' ${DateTime.now().difference(startedAt).inMilliseconds}ms'
        : '';
    debugPrint('[api] ${options.method} ${options.path} -> $outcome$elapsed');
  }
}
