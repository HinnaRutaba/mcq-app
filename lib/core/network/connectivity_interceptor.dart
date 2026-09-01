import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'api_config.dart';

/// Whether the handset has any route off itself.
abstract class NetworkProbe {
  Future<bool> hasRouteOut();

  /// Fires when the answer may have changed, so a cached result can be thrown
  /// away at the moment the radio changes rather than when a timer says so.
  /// Null for a probe that can only be asked.
  Stream<void>? get changes => null;
}

/// Resolves the API's own host — the reachability half of
/// [PlatformNetworkProbe], and usable on its own where the plugin is not.
///
/// It asks the resolver exactly what Dio would ask it, so it cannot refuse a
/// call that would otherwise have succeeded — with one exception: behind an
/// HTTP proxy the proxy resolves the origin host, not the handset. A build
/// that needs to work there should pass a different [NetworkProbe] to
/// `ApiService`, not delete the interceptor.
class DnsNetworkProbe implements NetworkProbe {
  DnsNetworkProbe({String? host, this.timeout = const Duration(seconds: 2)})
    : host = host ?? Uri.parse(ApiConfig.baseUrl).host;

  final String host;

  /// Short. The probe exists to save the officer a twenty-second wait, so it
  /// must not become a wait of its own.
  final Duration timeout;

  /// A DNS lookup can only be asked, never subscribed to.
  @override
  Stream<void>? get changes => null;

  @override
  Future<bool> hasRouteOut() async {
    try {
      final addresses = await InternetAddress.lookup(host).timeout(timeout);
      return addresses.isNotEmpty && addresses.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      // Slow DNS is not proof of no signal. A probe must never be the reason a
      // call does not go out, so ambiguity lets the request through and the
      // request's own timeout gives the honest answer.
      return true;
    }
  }
}

/// The OS's own view of the network, with a reachability check behind it.
///
/// Two questions, because neither answers on its own:
///
/// * `connectivity_plus` knows instantly and for certain when there is **no**
///   interface at all — aeroplane mode, no SIM, wifi off. That is a definitive
///   no, and it costs nothing to ask.
/// * It cannot tell you there **is** internet. A handset joined to a bazaar
///   wifi with no upstream, or parked on a cell with no data, reports
///   "connected" while every call fails. The plugin's own documentation says
///   as much.
///
/// So a "no" from the platform ends it, and a "yes" is only a reason to ask
/// [DnsNetworkProbe] whether the API's host actually resolves.
class PlatformNetworkProbe implements NetworkProbe {
  PlatformNetworkProbe({Connectivity? connectivity, NetworkProbe? reachability})
    : _connectivity = connectivity ?? Connectivity(),
      _reachability = reachability ?? DnsNetworkProbe();

  final Connectivity _connectivity;
  final NetworkProbe _reachability;

  @override
  Stream<void> get changes => _connectivity.onConnectivityChanged;

  @override
  Future<bool> hasRouteOut() async {
    final List<ConnectivityResult> interfaces;
    try {
      interfaces = await _connectivity.checkConnectivity();
    } on MissingPluginException {
      // The plugin is missing from this build, which says nothing about the
      // network. Fall through to the check that needs no plugin rather than
      // refusing every call on the strength of a broken dependency.
      return _reachability.hasRouteOut();
    } on PlatformException {
      return _reachability.hasRouteOut();
    }

    final noInterface =
        interfaces.isEmpty ||
        interfaces.every((ConnectivityResult r) => r == ConnectivityResult.none);
    if (noInterface) return false;

    return _reachability.hasRouteOut();
  }
}

/// Fails a call fast when there is no route out, instead of letting it sit on
/// the connect timeout.
///
/// Rejects as [DioExceptionType.connectionError], which is what a dead socket
/// would have produced anyway — so it arrives at the caller as the
/// [ApiFailure.network] every controller already handles, and nothing above
/// the network layer has to learn a new failure.
///
/// Installed first, ahead of the auth interceptor: a request that cannot leave
/// the handset has no business reading the keychain.
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor({
    NetworkProbe? probe,
    this.onlineFor = const Duration(seconds: 5),
    this.offlineFor = const Duration(seconds: 1),
  }) : _probe = probe ?? PlatformNetworkProbe() {
    // The OS says the moment the radio changes, which beats waiting out a TTL:
    // an officer who steps back into signal gets their next call sent, not
    // refused because a cached "no" has a second left on it.
    //
    // `onError` because the change signal is a convenience — a platform that
    // cannot deliver it leaves the TTLs below doing the job on their own.
    _probe.changes?.listen(
      (void _) => _checkedAt = null,
      onError: (Object _) {},
    );
  }

  final NetworkProbe _probe;

  /// How long a "yes" is trusted, so a screen firing six calls at once probes
  /// once rather than six times.
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
