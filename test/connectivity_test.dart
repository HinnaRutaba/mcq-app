import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mcq_app/core/network/connectivity_interceptor.dart';

/// [PlatformNetworkProbe] asks two questions and the order matters: the OS
/// only ever settles a "no", never a "yes".
void main() {
  late _FakeConnectivityPlatform platform;
  late _CountingReachability reachability;
  late PlatformNetworkProbe probe;

  setUp(() {
    platform = _FakeConnectivityPlatform();
    ConnectivityPlatform.instance = platform;
    reachability = _CountingReachability();
    probe = PlatformNetworkProbe(
      connectivity: Connectivity(),
      reachability: reachability,
    );
  });

  tearDown(() => platform.dispose());

  test('no interface at all settles it without a lookup', () async {
    platform.results = <ConnectivityResult>[ConnectivityResult.none];

    expect(await probe.hasRouteOut(), isFalse);
    expect(
      reachability.calls,
      0,
      reason: 'aeroplane mode needs no DNS round trip to confirm',
    );
  });

  test('an empty answer is also no interface', () async {
    platform.results = <ConnectivityResult>[];

    expect(await probe.hasRouteOut(), isFalse);
    expect(reachability.calls, 0);
  });

  test('an interface is not proof, so the host is still resolved', () async {
    platform.results = <ConnectivityResult>[ConnectivityResult.wifi];

    expect(await probe.hasRouteOut(), isTrue);
    expect(reachability.calls, 1);
  });

  test('wifi with no upstream is offline, whatever the radio says', () async {
    // The case the plugin cannot see on its own, and the reason it is not
    // trusted alone: joined to a bazaar access point that goes nowhere.
    platform.results = <ConnectivityResult>[ConnectivityResult.wifi];
    reachability.online = false;

    expect(await probe.hasRouteOut(), isFalse);
  });

  test('a missing plugin is not an answer about the network', () async {
    // Exactly what a build that has not been rebuilt for the new dependency
    // throws. Refusing every call on the strength of that would be worse than
    // the problem it is meant to solve.
    platform.failure = MissingPluginException('no implementation found');

    expect(await probe.hasRouteOut(), isTrue);
    expect(reachability.calls, 1);
  });

  test('a plugin that errors falls back the same way', () async {
    platform.failure = PlatformException(code: 'unavailable');

    expect(await probe.hasRouteOut(), isTrue);
    expect(reachability.calls, 1);
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

class _CountingReachability implements NetworkProbe {
  bool online = true;
  int calls = 0;

  @override
  Stream<void>? get changes => null;

  @override
  Future<bool> hasRouteOut() async {
    calls++;
    return online;
  }
}
