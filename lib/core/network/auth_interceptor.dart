import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage_service.dart';

/// Attaches the bearer token to every authenticated call, and reacts to the
/// one answer that ends a session.
///
/// A 401 or 403 means the session is over. The keychain is cleared here, at
/// the single place that sees it, so no caller can carry on holding a token the
/// server has already rejected; [onUnauthorized] is the app's cue to show the
/// sign-in screen.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._storage, this.onUnauthorized});

  /// Set to `false` in `Options.extra` for the sign-in call, which has no
  /// token to send and whose 401 means "wrong password", not "session over".
  static const String requiresAuthKey = 'mcq.requires_auth';

  final SecureStorageService _storage;
  final VoidCallback? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_requiresAuth(options)) {
      final token = await _storage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_requiresAuth(err.requestOptions) &&
        _endsSession(err.response?.statusCode)) {
      await _storage.clearSession();
      onUnauthorized?.call();
    }
    handler.next(err);
  }

  static bool _endsSession(int? statusCode) =>
      statusCode == 401 || statusCode == 403;

  bool _requiresAuth(RequestOptions options) =>
      options.extra[requiresAuthKey] != false;
}
