import '../core/utils/json_parse.dart';

/// An uploaded photograph, and the server-side [path] to attach to the write
/// it backs.
///
/// Upload first, write second. That order is what lets a fine or a seal be
/// retried on a weak signal without the image going up a second time.
///
/// The published spec does not capture this response, so [path] is read from
/// the likely keys and the untouched payload is kept in [raw].
class EvidenceUpload {
  const EvidenceUpload({
    this.path,
    this.kind,
    this.url,
    this.raw = const <String, dynamic>{},
  });

  /// What to send as `photo_path`, `signature_path` or `seal_photo_path`.
  final String? path;

  /// The kind that was uploaded, echoed back.
  final String? kind;

  /// A viewable URL, when the server returns one.
  final String? url;

  final Map<String, dynamic> raw;

  factory EvidenceUpload.fromJson(Map<String, dynamic> json) => EvidenceUpload(
    path: Json.string(
      Json.pick(json, <String>['path', 'photo_path', 'file_path', 'evidence_path']),
    ),
    kind: Json.string(json['kind']),
    url: Json.string(Json.pick(json, <String>['url', 'public_url'])),
    raw: json,
  );

  bool get hasPath => path != null;
}
