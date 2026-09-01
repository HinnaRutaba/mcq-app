import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:mcq_app/core/network/api_log_interceptor.dart';
import 'package:mcq_app/core/network/api_service.dart';
import 'package:mcq_app/core/storage/secure_storage_service.dart';

/// Answers from memory instead of the network, and keeps the request that was
/// sent so a test can assert on the wire format.
class ApiStub implements HttpClientAdapter {
  RequestOptions? lastOptions;

  /// Called before each reply, for a flow that makes more than one call and
  /// needs a different answer to each — a password change followed by the
  /// re-sign-in it forces. Set the next reply from inside it.
  void Function(RequestOptions options)? onRequest;

  Map<String, dynamic> _body = <String, dynamic>{};
  int _statusCode = 200;
  DioExceptionType? _failWith;

  void reply(Map<String, dynamic> body, {int statusCode = 200}) {
    _body = body;
    _statusCode = statusCode;
    _failWith = null;
  }

  void fail(DioExceptionType type) => _failWith = type;

  /// The JSON body that was sent, for a request that sent one.
  Map<String, dynamic> get sentBody =>
      Map<String, dynamic>.from(lastOptions!.data as Map);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    onRequest?.call(options);

    final failWith = _failWith;
    if (failWith != null) {
      throw DioException(requestOptions: options, type: failWith);
    }

    return ResponseBody.fromString(
      jsonEncode(_body),
      _statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Swaps the platform keychain for an in-memory one.
///
/// A real `flutter_secure_storage` call goes over a platform channel, which in
/// a widget test only completes inside `tester.runAsync` — so anything awaiting
/// a keychain read (the splash screen deciding where to send the officer) would
/// simply hang. Returns the backing map, so a test can seed or inspect it.
Map<String, String> installInMemoryKeychain() {
  final data = <String, String>{};
  FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(data);
  return data;
}

/// Swaps in a keychain that refuses every write, keeping [data] as its reads.
void installUnwritableKeychain(Map<String, String> data) {
  FlutterSecureStoragePlatform.instance = UnwritableSecureStoragePlatform(data);
}

/// A keychain that refuses every write, the way a handset does when the
/// keystore has been invalidated or the plugin is missing from the build.
///
/// Reads still work, so a test can prove that what the service kept in memory
/// is what later calls get.
class UnwritableSecureStoragePlatform extends TestFlutterSecureStoragePlatform {
  UnwritableSecureStoragePlatform(super.data);

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async => throw PlatformException(
    code: 'Exception encountered',
    message: 'write failed',
  );
}

/// An [ApiService] wired to an [ApiStub], over an in-memory keychain.
///
/// Everything here is real except the socket and the platform keychain, so a
/// test exercises the actual interceptors, envelope handling and error mapping.
class StubbedApi {
  StubbedApi() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      keychain,
    );
    storage = SecureStorageService();
    service = ApiService(
      storage: storage,
      client: Dio(ApiService.defaultOptions())..httpClientAdapter = stub,
      // A test asserts on behaviour, not on log output, and the captured
      // payloads here are long enough to bury the results.
      logLevel: ApiLogLevel.summary,
    );
  }

  final ApiStub stub = ApiStub();

  /// What the keychain holds, readable by a test.
  final Map<String, String> keychain = <String, String>{};

  late final SecureStorageService storage;
  late final ApiService service;
}
