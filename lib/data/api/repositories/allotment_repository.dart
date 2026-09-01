import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/utils/json_reader.dart';
import '../../../models/common/entity_refs.dart';
import '../../../models/common/pagination_meta.dart';

/// The `/allotment` module: agreements and the citizens holding them.
/// Read-only for a magistrate.
class AllotmentRepository {
  AllotmentRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<Paginated<AllotmentRef>> allotments({
    String? search,
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
  }) async {
    final envelope = await _client.get(
      ApiConstants.allotments,
      query: {
        ApiConstants.qSearch: search,
        ApiConstants.qPage: page,
        ApiConstants.qPerPage: perPage,
      },
    );
    return Paginated(
      items: envelope.list
          .whereType<Map<String, dynamic>>()
          .map((json) => AllotmentRef.fromJson(json))
          .toList(),
      meta: PaginationMeta.fromJson(envelope.meta),
    );
  }

  /// The full agreement payload, kept raw: the app only needs a handful of
  /// its fields today and dropping the rest would hide a change.
  Future<Map<String, dynamic>> allotmentById(int allotmentId) async {
    final envelope = await _client.get(ApiConstants.allotmentById(allotmentId));
    return envelope.map;
  }

  Future<Paginated<AllotteeRef>> allottees({
    String? search,
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
  }) async {
    final envelope = await _client.get(
      ApiConstants.allottees,
      query: {
        ApiConstants.qSearch: search,
        ApiConstants.qPage: page,
        ApiConstants.qPerPage: perPage,
      },
    );
    return Paginated(
      items: envelope.list
          .whereType<Map<String, dynamic>>()
          .map(AllotteeRef.fromJson)
          .toList(),
      meta: PaginationMeta.fromJson(envelope.meta),
    );
  }

  Future<AllotteeRef> allotteeById(int allotteeId) async {
    final envelope = await _client.get(ApiConstants.allotteeById(allotteeId));
    return AllotteeRef.fromJson(envelope.map);
  }

  /// Whether a unit currently has somebody to bill — what the fine form
  /// needs to know before it decides to ask for the offender's details.
  Future<bool> hasLiveAgreement(int allotmentId) async {
    final json = await allotmentById(allotmentId);
    final status = json.apiEnum('status').value;
    return status == 'active' || status == 'suspended';
  }
}
