import 'package:geolocator/geolocator.dart';

/// A GPS fix, or none.
///
/// Latitude and longitude are both or neither — half a coordinate looks
/// like proof of presence on a screen and locates nothing, and the server
/// refuses it. [accuracyM] travels with them so a reader months later knows
/// whether the pin means anything.
class GpsFix {
  const GpsFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
  });

  final double latitude;
  final double longitude;
  final double accuracyM;
}

/// Why there is no fix — so the screen can say something true rather than
/// spinning.
enum GpsFailure { serviceDisabled, permissionDenied, permanentlyDenied, timeout }

class LocationService {
  /// Tries for a fix, giving up after [timeout] rather than holding an
  /// officer at a shop front.
  ///
  /// Never throws. A handset with location switched off, permission
  /// refused, or a GPS that will not answer inside a covered bazaar is a
  /// normal outcome: the write goes ahead carrying no coordinates, and the
  /// form says so. Failing the whole action over a missing pin would be
  /// worse than a record with no pin.
  Future<GpsFix?> currentFix({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    lastFailure = null;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        lastFailure = GpsFailure.serviceDisabled;
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        lastFailure = GpsFailure.permanentlyDenied;
        return null;
      }
      if (permission == LocationPermission.denied) {
        lastFailure = GpsFailure.permissionDenied;
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return GpsFix(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyM: position.accuracy,
      );
    } on Object {
      lastFailure = GpsFailure.timeout;
      return null;
    }
  }

  GpsFailure? lastFailure;
}
