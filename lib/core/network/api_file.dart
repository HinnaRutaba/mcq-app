import 'package:dio/dio.dart';

/// One file on its way up in a multipart request.
///
/// Evidence photographs go through `POST /enforcement/evidence` first and the
/// returned `path` is then attached to the action, fine or seal — so the image
/// uploads once and the write can be retried without re-sending it.
class ApiFile {
  const ApiFile({
    required this.path,
    this.field = 'file',
    this.filename,
    this.mimeType,
  });

  /// Absolute path on the handset.
  final String path;

  /// Form field name. `file` for the evidence endpoint.
  final String field;

  /// Defaults to the basename of [path].
  final String? filename;

  /// e.g. `image/jpeg`. Left unset, the server sniffs it.
  final String? mimeType;

  Future<MultipartFile> toMultipartFile() => MultipartFile.fromFile(
    path,
    filename: filename ?? _basename(path),
    contentType: mimeType == null ? null : DioMediaType.parse(mimeType!),
  );

  static String _basename(String path) {
    final segments = path.split(RegExp(r'[/\\]'));
    return segments.isEmpty ? path : segments.last;
  }
}
