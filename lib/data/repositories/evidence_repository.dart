import 'package:dio/dio.dart' show ProgressCallback;

import '../../core/network/api_config.dart';
import '../../core/network/api_file.dart';
import '../../core/network/api_service.dart';
import '../../models/evidence_upload.dart';

/// Uploads the photograph that backs a visit, a fine or a seal.
///
/// Upload first, write second. The returned `path` goes onto the action, fine
/// or seal as `photo_path` / `signature_path` / `seal_photo_path` — which means
/// that on a bazaar's signal the image goes up once, and the write behind it can
/// be retried as many times as it takes without re-sending the picture.
abstract class EvidenceRepository {
  /// [filePath] is a file on the handset — the camera's output, or a picked
  /// image. Max 10 MB.
  ///
  /// Ask for the camera or gallery permission before getting here:
  /// `PermissionService.ensure(AppPermission.camera)`.
  Future<EvidenceUpload> upload({
    required String filePath,
    String kind,
    String? mimeType,
    ProgressCallback? onProgress,
  });

  /// A photograph of the shop, the seal, or the offence.
  static const String kindPhoto = 'photo';

  /// A captured signature. The server's accepted set is not published beyond
  /// `photo`, which the API uses by example.
  static const String kindSignature = 'signature';
}

class ApiEvidenceRepository implements EvidenceRepository {
  ApiEvidenceRepository({required this._api});

  final ApiService _api;

  @override
  Future<EvidenceUpload> upload({
    required String filePath,
    String kind = EvidenceRepository.kindPhoto,
    String? mimeType,
    ProgressCallback? onProgress,
  }) async {
    final response = await _api.post(
      ApiPaths.evidence,
      body: <String, dynamic>{'kind': kind},
      files: <ApiFile>[
        ApiFile(path: filePath, mimeType: mimeType),
      ],
      onSendProgress: onProgress,
    );
    return EvidenceUpload.fromJson(response.dataMap);
  }
}
