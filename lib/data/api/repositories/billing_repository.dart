import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../models/billing/challan.dart';
import '../../../models/common/pagination_meta.dart';

/// The `/billing` module — read-only for a magistrate: they hold
/// `billing.challan.view` and no billing writes at all.
class BillingRepository {
  BillingRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// What a shop owes. A unit can hold a live rent challan and a live fine
  /// challan at once, with different due dates and different payment
  /// links — return them all and let the screen show two obligations
  /// rather than one total.
  Future<Paginated<Challan>> challans({
    int? allotmentId,
    String? status,
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
  }) async {
    final envelope = await _client.get(
      ApiConstants.challans,
      query: {
        ApiConstants.qAllotmentId: allotmentId,
        ApiConstants.qStatus: status,
        ApiConstants.qPage: page,
        ApiConstants.qPerPage: perPage,
      },
    );
    return _page(envelope.list, envelope.meta);
  }

  Future<Paginated<Challan>> allotteeChallans(
    int allotteeId, {
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
  }) async {
    final envelope = await _client.get(
      ApiConstants.allotteeChallans(allotteeId),
      query: {ApiConstants.qPage: page, ApiConstants.qPerPage: perPage},
    );
    return _page(envelope.list, envelope.meta);
  }

  Paginated<Challan> _page(List<dynamic> raw, Map<String, dynamic>? meta) =>
      Paginated(
        items:
            raw.whereType<Map<String, dynamic>>().map(Challan.fromJson).toList(),
        meta: PaginationMeta.fromJson(meta),
      );
}
