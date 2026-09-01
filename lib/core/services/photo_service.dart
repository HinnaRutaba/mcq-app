import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Capturing and compressing field photographs.
///
/// Compress before sending: the server's ceiling is 10 MB, but a
/// 12-megapixel photo over bazaar mobile data is a failed upload and a
/// wasted visit. Target under 1 MB.
class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const int targetBytes = 1024 * 1024;

  /// Takes a photograph with the camera and returns a compressed copy.
  ///
  /// The caller shows the officer a thumbnail of the result before they
  /// submit: a photograph of a thumb is worse than no photograph, and
  /// nobody finds out until somebody opens the file months later.
  Future<File?> capture({
    ImageSource source = ImageSource.camera,
  }) async {
    final shot = await _picker.pickImage(
      source: source,
      // A first pass in the picker itself, so the compressor is not handed
      // a 12-megapixel frame on a cheap handset.
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (shot == null) return null;
    return compress(File(shot.path));
  }

  /// Squeezes [file] under [targetBytes], stepping quality down rather than
  /// resizing further — a legible shutter number matters more than a small
  /// file, up to a point.
  Future<File> compress(File file) async {
    var quality = 80;
    File best = file;

    final directory = await getTemporaryDirectory();
    for (var attempt = 0; attempt < 3; attempt++) {
      final target =
          '${directory.path}/mcq_evidence_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        target,
        quality: quality,
        minWidth: 1280,
        minHeight: 720,
        // JPEG on purpose. SVG is rejected by the server because it can
        // carry script, and the sniffed type is what gets validated.
        format: CompressFormat.jpeg,
      );
      if (result == null) break;
      best = File(result.path);
      if (await best.length() <= targetBytes) break;
      quality -= 20;
    }
    return best;
  }
}
