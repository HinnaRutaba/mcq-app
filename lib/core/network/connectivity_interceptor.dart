import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

abstract class NetworkProbe {
  Future<bool> hasRouteOut();

  Stream<void>? get changes => null;
}

class PlatformNetworkProbe implements NetworkProbe {
  PlatformNetworkProbe({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<void> get changes => _connectivity.onConnectivityChanged;

  @override
  Future<bool> hasRouteOut() async {
    final List<ConnectivityResult> interfaces;
    try {
      interfaces = await _connectivity.checkConnectivity();
    } on MissingPluginException {
      // The plugin is missing from this build, which says nothing about the
      // network. Let the call through: refusing every request on the strength
      // of a broken dependency would be worse than the wait it saves.
      return true;
    } on PlatformException {
      return true;
    }

    return interfaces.any(
      (ConnectivityResult result) => result != ConnectivityResult.none,
    );
  }
}

class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor({
    NetworkProbe? probe,
    this.onlineFor = const Duration(seconds: 5),
    this.offlineFor = const Duration(seconds: 1),
  }) : _probe = probe ?? PlatformNetworkProbe() {
    _probe.changes?.listen(
      (void _) => _checkedAt = null,
      onError: (Object _) {},
    );
  }

  final NetworkProbe _probe;

  /// How long a "yes" is trusted, so a screen firing six calls at once asks
  /// the platform once rather than six times.
  final Duration onlineFor;

  /// How long a "no" is trusted. Much shorter: an officer who walks ten metres
  /// for signal should not be told they are offline for another five seconds.
  final Duration offlineFor;

  DateTime? _checkedAt;
  bool _lastResult = true;
  Future<bool>? _inFlight;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (await _isOnline()) return handler.next(options);

    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: const SocketException('No route out of this handset'),
      ),
    );
  }

  Future<bool> _isOnline() {
    final checkedAt = _checkedAt;
    if (checkedAt != null) {
      final age = DateTime.now().difference(checkedAt);
      if (age < (_lastResult ? onlineFor : offlineFor)) {
        return Future<bool>.value(_lastResult);
      }
    }
    // Concurrent callers share one probe rather than each starting their own.
    return _inFlight ??= _probeOnce();
  }

  Future<bool> _probeOnce() async {
    try {
      _lastResult = await _probe.hasRouteOut();
      _checkedAt = DateTime.now();
      return _lastResult;
    } finally {
      _inFlight = null;
    }
  }
}
