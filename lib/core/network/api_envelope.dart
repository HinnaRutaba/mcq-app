import 'package:dio/dio.dart';

/// Every successful response is wrapped:
///
/// ```json
/// { "data": {…} | […], "meta": {…}, "message": "…" }
/// ```
///
/// Unwrap once, here, so no repository reaches for `['data']` itself.
class ApiEnvelope {
  const ApiEnvelope({
    required this.data,
    required this.statusCode,
    this.meta,
    this.message,
  });

  final Object? data;
  final int statusCode;
  final Map<String, dynamic>? meta;

  /// Present on writes. The server's own sentence — show it verbatim.
  final String? message;

  factory ApiEnvelope.fromResponse(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return ApiEnvelope(
        data: body.containsKey('data') ? body['data'] : body,
        statusCode: response.statusCode ?? 200,
        meta: body['meta'] is Map<String, dynamic>
            ? body['meta'] as Map<String, dynamic>
            : null,
        message: body['message'] is String ? body['message'] as String : null,
      );
    }
    return ApiEnvelope(data: body, statusCode: response.statusCode ?? 200);
  }

  Map<String, dynamic> get map =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : const {};

  List<dynamic> get list => data is List ? data as List<dynamic> : const [];

  /// **201 means created; 200 means "you already sent that".**
  ///
  /// On a create, a 200 is the server telling you the retry worked and
  /// there is nothing new: the queue must mark the item done rather than
  /// retrying it, and the UI must not say "fine imposed" a second time.
  bool get wasCreated => statusCode == 201;
  bool get wasReplay => statusCode == 200;
}
