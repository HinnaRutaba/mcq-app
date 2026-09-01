import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mcq_app/core/network/connectivity_interceptor.dart';

/// [PlatformNetworkProbe] reports what the OS says about the interface, and
/// never refuses a call on anything less than a definite "no".
void main() {
  late _FakeConnectivityPlatform platform;
  late PlatformNetworkProbe probe;

  setUp(() {
    platform = _FakeConnectivityPlatform();
    ConnectivityPlatform.instance = platform;
    probe = PlatformNetworkProbe(connectivity: Connectivity());
  });

  tearDown(() => platform.dispose());

  test('no interface at all is offline', () async {
    platform.results = <ConnectivityResult>[ConnectivityResult.none];

    expect(await probe.hasRouteOut(), isFalse);
  });

  test('an empty answer is also no interface', () async {
    platform.results = <ConnectivityResult>[];

    expect(await probe.hasRouteOut(), isFalse);
  });

  test('any interface at all is online', () async {
    for (final ConnectivityResult result in <ConnectivityResult>[
      ConnectivityResult.wifi,
      ConnectivityResult.mobile,
      ConnectivityResult.ethernet,
      ConnectivityResult.vpn,
    ]) {
      platform.results = <ConnectivityResult>[result];
      expect(await probe.hasRouteOut(), isTrue, reason: result.name);
    }
  });

  test('one live interface beside a dead one is online', () async {
    platform.results = <ConnectivityResult>[
      ConnectivityResult.none,
      ConnectivityResult.wifi,
    ];

    expect(await probe.hasRouteOut(), isTrue);
  });

  test('a missing plugin is not an answer about the network', () async {
    // Exactly what a build that has not been rebuilt for the new dependency
    // throws. Refusing every call on the strength of that would be worse than
    // the wait the interceptor saves.
    platform.failure = MissingPluginException('no implementation found');

    expect(await probe.hasRouteOut(), isTrue);
  });

  test('a plugin that errors lets the call through the same way', () async {
    platform.failure = PlatformException(code: 'unavailable');

    expect(await probe.hasRouteOut(), isTrue);
  });

  test('the radio stream is passed through as the change signal', () async {
    expectLater(probe.changes, emits(anything));
    platform.announce(<ConnectivityResult>[ConnectivityResult.mobile]);
  });
}

class _FakeConnectivityPlatform extends ConnectivityPlatform {
  List<ConnectivityResult> results = <ConnectivityResult>[
    ConnectivityResult.wifi,
  ];

  /// Thrown instead of answering, for the cases where the plugin is the thing
  /// that is broken.
  Object? failure;

  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  void announce(List<ConnectivityResult> value) => _controller.add(value);

  Future<void> dispose() => _controller.close();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    if (failure != null) throw failure!;
    return results;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;
}
