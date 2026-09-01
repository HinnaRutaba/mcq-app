import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../models/common/pagination_meta.dart';
import '../../../models/common/write_outcome.dart';
import '../../../models/property/inspection.dart';
import '../../../models/property/property_summary.dart';

/// The `/property` module.
///
/// Note the doubled path segment — the module is `property` and the
/// resource is `properties`. Getting that wrong is a 404, which looks like
/// an auth problem and is not.
///
/// Named [PropertyApiRepository] to sit alongside the demo
/// `PropertyRepository` in `lib/data/repositories/` without a clash.
class PropertyApiRepository {
  PropertyApiRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// `GET /property/properties?q=…` — "what am I standing in front of".
  ///
  /// A barcode or QR scanner against `property_code` would be a genuine
  /// improvement if MCQ ever labels units.
  Future<Paginated<PropertySummary>> search({
    String? query,
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
  }) async {
    final envelope = await _client.get(
      ApiConstants.properties,
      query: {
        ApiConstants.qSearch: (query ?? '').trim().isEmpty ? null : query!.trim(),
        ApiConstants.qPage: page,
        ApiConstants.qPerPage: perPage,
      },
    );
    return Paginated(
      items: envelope.list
          .whereType<Map<String, dynamic>>()
          .map(PropertySummary.fromJson)
          .toList(),
      meta: PaginationMeta.fromJson(envelope.meta),
    );
  }

  Future<PropertySummary> byId(int propertyId) async {
    final envelope = await _client.get(ApiConstants.propertyById(propertyId));
    return PropertySummary.fromJson(envelope.map);
  }

  Future<List<Map<String, dynamic>>> documents(int propertyId) async {
    final envelope =
        await _client.get(ApiConstants.propertyDocuments(propertyId));
    return envelope.list.whereType<Map<String, dynamic>>().toList();
  }

  Future<Paginated<Inspection>> inspections({
    int? propertyId,
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
  }) async {
    final envelope = await _client.get(
      ApiConstants.inspections,
      query: {
        'property_id': propertyId,
        ApiConstants.qPage: page,
        ApiConstants.qPerPage: perPage,
      },
    );
    return Paginated(
      items: envelope.list
          .whereType<Map<String, dynamic>>()
          .map(Inspection.fromJson)
          .toList(),
      meta: PaginationMeta.fromJson(envelope.meta),
    );
  }

  /// `POST /property/properties/{property}/inspections` — the one field
  /// write that takes the image directly, as `multipart/form-data` with an
  /// optional `photo` part. One step, unlike the two-step evidence flow.
  Future<WriteOutcome<Inspection>> recordInspection({
    required int propertyId,
    required String inspectionType,
    required String findings,
    File? photo,
    Map<String, dynamic> extraFields = const {},
  }) async {
    final envelope = await _client.postMultipart(
      ApiConstants.propertyInspections(propertyId),
      fields: {
        'inspection_type': inspectionType,
        'findings': findings,
        ...extraFields,
      },
      files: {'photo': ?photo},
    );
    return WriteOutcome(
      value: Inspection.fromJson(envelope.map),
      wasCreated: envelope.wasCreated,
      message: envelope.message,
    );
  }

  Future<WriteOutcome<Inspection>> resolveInspection({
    required int inspectionId,
    required String remarks,
  }) async {
    final envelope = await _client.post(
      ApiConstants.inspectionResolve(inspectionId),
      body: {'remarks': remarks},
    );
    return WriteOutcome(
      value: Inspection.fromJson(envelope.map),
      wasCreated: envelope.wasCreated,
      message: envelope.message,
    );
  }

  /// The absolute URL of an inspection photograph, for an authenticated
  /// image request.
  String photoUrl(int inspectionId) =>
      '${ApiConstants.baseUrl}${ApiConstants.inspectionPhoto(inspectionId)}';
}
