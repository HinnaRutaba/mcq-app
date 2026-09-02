import 'package:image_picker/image_picker.dart';

import '../permissions/permission_service.dart';

/// How a request for a photograph ended.
enum PhotoOutcome {
  taken,

  /// The officer backed out of the camera. Not a failure — say nothing.
  cancelled,

  /// Refused this once. Asking again is allowed, so offer the button again.
  refused,

  /// Refused for good. The only way back is the system settings screen.
  needsSettings,
}

class PhotoCaptureResult {
  const PhotoCaptureResult(this.outcome, [this.path]);

  final PhotoOutcome outcome;

  /// A file on the handset, set only when [outcome] is [PhotoOutcome.taken].
  /// It is uploaded through `EvidenceRepository` before any write is sent.
  final String? path;

  static const PhotoCaptureResult cancelled = PhotoCaptureResult(
    PhotoOutcome.cancelled,
  );
}

/// Takes the photograph that backs a fine, a seal or a visit.
///
/// Shrunk on the way out of the camera rather than after the fact: a modern
/// handset produces a 6 MB frame, the endpoint caps at 10 MB, and a bazaar's
/// uplink will not carry either before the officer gives up. [_maxEdge] and
/// [_quality] together land a shopfront comfortably under a megabyte while
/// leaving a shutter, a number plate or a notice legible, which is the whole
/// point of the evidence.
class PhotoCapture {
  PhotoCapture({PermissionService? permissions, ImagePicker? picker})
    : _permissions = permissions ?? const PermissionService(),
      _picker = picker ?? ImagePicker();

  final PermissionService _permissions;
  final ImagePicker _picker;

  static const double _maxEdge = 1600;
  static const int _quality = 70;

  Future<PhotoCaptureResult> fromCamera() =>
      _pick(ImageSource.camera, AppPermission.camera);

  /// For the shop photographed a minute ago, before the officer opened the
  /// form — and for the handsets whose camera the OS will not hand over.
  Future<PhotoCaptureResult> fromGallery() =>
      _pick(ImageSource.gallery, AppPermission.gallery);

  Future<PhotoCaptureResult> _pick(
    ImageSource source,
    AppPermission permission,
  ) async {
    final outcome = await _permissions.request(permission);
    if (!outcome.isUsable) {
      return PhotoCaptureResult(
        outcome.needsSettings
            ? PhotoOutcome.needsSettings
            : PhotoOutcome.refused,
      );
    }

    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: _maxEdge,
      maxHeight: _maxEdge,
      imageQuality: _quality,
    );
    if (file == null) return PhotoCaptureResult.cancelled;
    return PhotoCaptureResult(PhotoOutcome.taken, file.path);
  }
}
