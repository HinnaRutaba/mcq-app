import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum ApiLogLevel {
  none,

  /// One line per call: method, path, status, duration.
  summary,

  /// Everything — query, headers, request body, response body.
  full,
}

class ApiLogInterceptor extends Interceptor {
  ApiLogInterceptor({this.level = ApiLogLevel.full});

  final ApiLogLevel level;

  static const String _startedAtKey = 'mcq.started_at';

  /// Past this, a body is clipped. A defaulter list is 55 rows deep and a map
  /// call returns hundreds of pins; the whole thing scrolls the useful part off
  /// the console.
  static const int _maxBodyChars = 4000;

  /// Android's logcat drops the tail of a very long line, so output is emitted
  /// in pieces below its limit.
  static const int _maxLineChars = 800;

  static const JsonEncoder _pretty = JsonEncoder.withIndent('  ');

  /// Const in release, so everything behind it is compiled out.
  bool get _enabled => kDebugMode && level != ApiLogLevel.none;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();

    if (_enabled && level == ApiLogLevel.full) {
      final buffer = StringBuffer()
        ..writeln('┌─ REQUEST  ${options.method} ${_uri(options)}');
      _writeSection(buffer, 'headers', _headers(options.headers));
      _writeSection(buffer, 'body', _body(options.data));
      buffer.write('└─');
      _emit(buffer.toString());
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(
      response.requestOptions,
      label: 'RESPONSE',
      status: '${response.statusCode}',
      body: response.data,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      err.requestOptions,
      label: 'FAILED  ',
      status: '${err.response?.statusCode ?? err.type.name}',
      body: err.response?.data ?? err.message,
    );
    handler.next(err);
  }

  void _log(
    RequestOptions options, {
    required String label,
    required String status,
    Object? body,
  }) {
    if (!_enabled) return;

    final elapsed = _elapsed(options);

    if (level == ApiLogLevel.summary) {
      _emit('[api] ${options.method} ${options.path} -> $status$elapsed');
      return;
    }

    final buffer = StringBuffer()
      ..writeln(
        '┌─ $label $status  ${options.method} ${_uri(options)}$elapsed',
      );
    _writeSection(buffer, 'body', _body(body));
    buffer.write('└─');
    _emit(buffer.toString());
  }

  String _uri(RequestOptions options) {
    final query = options.queryParameters;
    if (query.isEmpty) return options.path;
    final pairs = query.entries
        .map((MapEntry<String, dynamic> e) => '${e.key}=${e.value}')
        .join('&');
    return '${options.path}?$pairs';
  }

  String _elapsed(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    if (startedAt is! DateTime) return '';
    return '  (${DateTime.now().difference(startedAt).inMilliseconds}ms)';
  }

  void _writeSection(StringBuffer buffer, String label, String? content) {
    if (content == null || content.isEmpty) return;
    buffer.writeln('│ $label:');
    for (final line in content.split('\n')) {
      buffer.writeln('│   $line');
    }
  }

  String? _headers(Map<String, dynamic> headers) {
    if (headers.isEmpty) return null;
    return headers.entries
        .map((MapEntry<String, dynamic> e) => '${e.key}: ${e.value}')
        .join('\n');
  }

  String? _body(Object? body) {
    if (body == null) return null;

    if (body is FormData) {
      final fields = body.fields
          .map((MapEntry<String, String> f) => '${f.key}: ${f.value}')
          .join('\n');
      // Never the bytes — just enough to see the right file went up.
      final files = body.files
          .map(
            (MapEntry<String, MultipartFile> f) =>
                '${f.key}: ${f.value.filename} (${f.value.length} bytes)',
          )
          .join('\n');
      return <String>[
        '(multipart)',
        if (fields.isNotEmpty) fields,
        if (files.isNotEmpty) files,
      ].join('\n');
    }

    final text = _encode(body);
    return text.length <= _maxBodyChars
        ? text
        : '${text.substring(0, _maxBodyChars)}\n… clipped, '
              '${text.length - _maxBodyChars} more characters';
  }

  String _encode(Object? value) {
    try {
      return _pretty.convert(value);
    } catch (_) {
      // Anything the encoder cannot walk — a stream, an error object.
      return '$value';
    }
  }

  /// `debugPrint` throttles rather than truncates, but the platform log behind
  /// it does not, so long content goes out in pieces.
  void _emit(String message) {
    for (final line in message.split('\n')) {
      if (line.length <= _maxLineChars) {
        log(line);
        continue;
      }
      for (var i = 0; i < line.length; i += _maxLineChars) {
        final end = (i + _maxLineChars).clamp(0, line.length);
        log(line.substring(i, end));
      }
    }
  }
}
