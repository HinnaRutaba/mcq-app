import 'package:geolocator/geolocator.dart';

import '../permissions/permission_service.dart';

/// How a request for a GPS fix ended.
enum LocationOutcome {
  fixed,

  /// Refused this once; the button may be offered again.
  refused,

  /// Refused for good — only the system settings screen will change it.
  needsSettings,

  /// The permission is there but the handset's location switch is off.
  serviceOff,

  /// Inside a covered bazaar, or under a tin roof. Common, and not an error
  /// the officer caused: the fine can still be recorded without it.
  unavailable,
}

/// Where the officer was standing, as the OS reported it.
///
/// Both coordinates or neither — a fix with one of them is not a fix, and the
/// API refuses a write carrying half of one.
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
  });

  final double latitude;
  final double longitude;

  /// The radius the OS says the fix is good to, in metres. Shown to the
  /// officer, because "fixed to 5 m" and "fixed to 800 m" are very different
  /// pieces of evidence and only one of them puts somebody at a shopfront.
  final double accuracyM;
}

class LocationResult {
  const LocationResult(this.outcome, [this.fix]);

  final LocationOutcome outcome;
  final LocationFix? fix;
}

/// Takes the GPS fix that turns a recorded fine into evidence somebody stood
/// in front of the shop.
class LocationCapture {
  const LocationCapture({PermissionService? permissions})
    : _permissions = permissions ?? const PermissionService();

  final PermissionService _permissions;

  /// Long enough for a cold fix under a bazaar roof, short enough that an
  /// officer is not left holding a spinner in front of a shopkeeper. A miss is
  /// reported as [LocationOutcome.unavailable], never as a failure of the fine.
  static const Duration _limit = Duration(seconds: 12);

  Future<LocationResult> fix() async {
    final outcome = await _permissions.request(AppPermission.location);
    if (!outcome.isUsable) {
      return LocationResult(
        outcome.needsSettings
            ? LocationOutcome.needsSettings
            : LocationOutcome.refused,
      );
    }

    if (!await _permissions.isLocationServiceEnabled()) {
      return const LocationResult(LocationOutcome.serviceOff);
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _limit,
        ),
      );
      return LocationResult(
        LocationOutcome.fixed,
        LocationFix(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyM: position.accuracy,
        ),
      );
    } on Exception {
      // A timeout, a location error, a handset that simply will not say. All
      // of them mean the same thing to the officer: no fix this time, try the
      // refresh or carry on without one.
      return const LocationResult(LocationOutcome.unavailable);
    }
  }
}
