import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Whether the handset currently has a network at all.
///
/// This is a hint, not a guarantee — a bar of signal in a bazaar can still
/// time out. Writes are queued on failure regardless of what this says;
/// this only drives the offline banner and the moment the queue tries to
/// drain again.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  /// Fires whenever the handset gains or loses a network. The offline queue
  /// listens for the gain and drains.
  Stream<bool> get onChanged =>
      _connectivity.onConnectivityChanged.map(_isOnline).distinct();

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
