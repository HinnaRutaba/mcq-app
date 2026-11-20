import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

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

  /// Android's default gallery is the old file chooser, which ignores a
  /// selection limit; the system Photo Picker honours it and needs no storage
  /// permission. Called once at startup.
  static void useSystemPhotoPicker() {
    final ImagePickerPlatform platform = ImagePickerPlatform.instance;
    if (platform is ImagePickerAndroid) platform.useAndroidPhotoPicker = true;
  }

  Future<PhotoCaptureResult> fromCamera() =>
      _pick(ImageSource.camera, AppPermission.camera);

  /// For the shop photographed a minute ago, before the officer opened the
  /// form — and for the handsets whose camera the OS will not hand over.
  /// No permission: the system photo picker hands over only what is chosen.
  Future<PhotoCaptureResult> fromGallery() => _pick(ImageSource.gallery);

  /// Several pictures from the gallery in one go. The picker is told [limit],
  /// but an old chooser can ignore it, so the list comes back untrimmed for
  /// the caller to cap and say so. Empty when the officer backs out.
  Future<List<String>> fromGalleryMany({required int limit}) async {
    if (limit < 1) return const <String>[];
    final List<XFile> files = await _picker.pickMultiImage(
      maxWidth: _maxEdge,
      maxHeight: _maxEdge,
      imageQuality: _quality,
      limit: limit,
    );
    return <String>[for (final XFile f in files) f.path];
  }

  Future<PhotoCaptureResult> _pick(
    ImageSource source, [
    AppPermission? permission,
  ]) async {
    if (permission != null) {
      final outcome = await _permissions.request(permission);
      if (!outcome.isUsable) {
        return PhotoCaptureResult(
          outcome.needsSettings
              ? PhotoOutcome.needsSettings
              : PhotoOutcome.refused,
        );
      }
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
