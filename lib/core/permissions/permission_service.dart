import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

/// What the officer actually needs the OS to allow, named by the job rather
/// than by the underlying OS permission.
enum AppPermission {
  /// Photographing a shopfront as evidence for a fine, a seal or a visit —
  /// `photo_path`, `seal_photo_path`, `signature_path` all start here.
  camera,

  /// Picking an already-taken photograph out of the library.
  gallery,

  /// Being told about follow-ups falling due and cases assigned by the
  /// taxation branch. The officer's server-side `notification.view` permission
  /// governs the data; this governs whether the handset may show it.
  notifications,

  /// Stamping a field write with `latitude` / `longitude` /
  /// `location_accuracy_m`, which is what turns a recorded visit into evidence
  /// that somebody stood in front of the shop.
  location,
}

/// The answer, with enough detail for a caller to know what to do next.
enum PermissionOutcome {
  granted,

  /// iOS "limited" photo access, and provisional notifications. Enough to get
  /// on with the job.
  partial,

  /// Refused this once; asking again later is allowed.
  denied,

  /// Refused for good. The OS will not prompt again — the only way back is
  /// [PermissionService.openSystemSettings].
  permanentlyDenied,

  /// Blocked by device policy, not by the officer. Do not offer a retry.
  restricted;

  /// Whether the feature can proceed.
  bool get isUsable =>
      this == PermissionOutcome.granted || this == PermissionOutcome.partial;

  /// Whether the only remaining route is the system settings screen.
  bool get needsSettings => this == PermissionOutcome.permanentlyDenied;
}

/// Asks the OS for the permissions the field-write endpoints imply.
///
/// Kept in the core layer with no Flutter UI and no controller dependency: a
/// controller calls [request] before opening a camera or attaching a location
/// fix, and decides what to show from the [PermissionOutcome] it gets back.
class PermissionService {
  const PermissionService();

  /// Current state without prompting — safe to call while building a screen.
  Future<PermissionOutcome> status(AppPermission permission) async =>
      _outcome(await _permissionFor(permission).status);

  /// Prompts if the OS still allows prompting, and reports where things stand.
  Future<PermissionOutcome> request(AppPermission permission) async {
    final outcome = _outcome(await _permissionFor(permission).request());

    // Android below 13 has no READ_MEDIA_IMAGES, so `Permission.photos`
    // resolves to nothing there; fall back to the legacy storage read.
    if (permission == AppPermission.gallery &&
        !outcome.isUsable &&
        Platform.isAndroid) {
      return _outcome(await Permission.storage.request());
    }

    return outcome;
  }

  /// Convenience for the common "carry on only if allowed" call site.
  Future<bool> ensure(AppPermission permission) async =>
      (await request(permission)).isUsable;

  /// Requests several at once — e.g. camera plus location before an officer
  /// starts a round, so they are not interrupted mid-visit.
  Future<Map<AppPermission, PermissionOutcome>> requestAll(
    List<AppPermission> permissions,
  ) async {
    final results = <AppPermission, PermissionOutcome>{};
    for (final permission in permissions) {
      results[permission] = await request(permission);
    }
    return results;
  }

  /// Whether the device's location services are switched on at all. A granted
  /// location permission still yields no fix while the OS setting is off.
  Future<bool> isLocationServiceEnabled() =>
      Permission.location.serviceStatus.isEnabled;

  /// Opens the app's page in system settings, for a permanently denied
  /// permission.
  Future<bool> openSystemSettings() => openAppSettings();

  Permission _permissionFor(AppPermission permission) => switch (permission) {
    AppPermission.camera => Permission.camera,
    AppPermission.gallery => Permission.photos,
    AppPermission.notifications => Permission.notification,
    // When-in-use only: the app records a fix while the officer is looking at
    // it, and never tracks them in the background.
    AppPermission.location => Permission.locationWhenInUse,
  };

  PermissionOutcome _outcome(PermissionStatus status) => switch (status) {
    PermissionStatus.granted => PermissionOutcome.granted,
    PermissionStatus.limited ||
    PermissionStatus.provisional => PermissionOutcome.partial,
    PermissionStatus.permanentlyDenied => PermissionOutcome.permanentlyDenied,
    PermissionStatus.restricted => PermissionOutcome.restricted,
    PermissionStatus.denied => PermissionOutcome.denied,
  };
}
