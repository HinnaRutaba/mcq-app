import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../models/field_seal.dart';
import '../../models/seal_requests.dart';

/// The officer's sealed shops, and the queue of seals now clear to come off.
///
/// One list read two ways: everything sealed, and the ones the server considers
/// settled.
abstract class FieldSealRepository {
  /// [readyOnly] returns the unseal queue — the seals where no fine on the unit
  /// is outstanding and at least one has actually been paid.
  Future<List<FieldSeal>> seals({bool readyOnly});

  /// Takes a seal off once the fine behind it is settled.
  ///
  /// Releasing one the queue has not cleared needs
  /// `SealReleaseRequest.overrideReason` — that is the record of why a shop
  /// still owing money was opened.
  ///
  /// The published spec does not capture this response, so it is read
  /// leniently; the untouched payload is on `FieldSeal.raw`.
  Future<FieldSeal> release(int sealId, SealReleaseRequest request);
}

class ApiFieldSealRepository implements FieldSealRepository {
  ApiFieldSealRepository({required this._api});

  final ApiService _api;

  @override
  Future<List<FieldSeal>> seals({bool readyOnly = false}) async {
    final response = await _api.get(
      ApiPaths.seals,
      query: <String, dynamic>{'ready': readyOnly ? 1 : null},
    );
    return response.dataList.map(FieldSeal.fromJson).toList();
  }

  @override
  Future<FieldSeal> release(int sealId, SealReleaseRequest request) async {
    final response = await _api.post(
      ApiPaths.sealRelease(sealId),
      body: request.toJson(),
    );
    return FieldSeal.fromJson(response.dataMap);
  }
}
