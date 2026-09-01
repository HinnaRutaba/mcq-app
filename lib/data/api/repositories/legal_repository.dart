import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../models/common/pagination_meta.dart';
import '../../../models/legal/legal_case.dart';

/// The `/legal` module — read-only for a magistrate.
///
/// A stay order stops enforcement. If a property's case shows a live stay,
/// the app must not offer to seal it: the server will refuse, but the
/// officer should not be walking to the shop in the first place.
class LegalRepository {
  LegalRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<Paginated<LegalCase>> cases({
    String? status,
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
  }) async {
    final envelope = await _client.get(
      ApiConstants.legalCases,
      query: {
        ApiConstants.qStatus: status,
        ApiConstants.qPage: page,
        ApiConstants.qPerPage: perPage,
      },
    );
    return Paginated(
      items: envelope.list
          .whereType<Map<String, dynamic>>()
          .map(LegalCase.fromJson)
          .toList(),
      meta: PaginationMeta.fromJson(envelope.meta),
    );
  }

  Future<LegalCase> caseById(int caseId) async {
    final envelope = await _client.get(ApiConstants.legalCaseById(caseId));
    return LegalCase.fromJson(envelope.map);
  }

  Future<List<Hearing>> hearings(int caseId) async {
    final envelope = await _client.get(ApiConstants.legalCaseHearings(caseId));
    return envelope.list
        .whereType<Map<String, dynamic>>()
        .map(Hearing.fromJson)
        .toList();
  }

  /// The hearing diary — what is coming up.
  Future<List<Hearing>> diary() async {
    final envelope = await _client.get(ApiConstants.legalDiary);
    return envelope.list
        .whereType<Map<String, dynamic>>()
        .map(Hearing.fromJson)
        .toList();
  }

  /// Whether enforcement on [propertyId] is suspended by a live stay.
  /// Consulted before the seal button is offered.
  Future<bool> hasLiveStay(int propertyId) async {
    final page = await cases(perPage: 100);
    return page.items.any(
      (legalCase) => legalCase.hasLiveStay && legalCase.property.id == propertyId,
    );
  }
}
