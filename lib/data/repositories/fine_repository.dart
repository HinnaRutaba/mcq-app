import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../models/fine.dart';
import '../../models/fine_request.dart';

/// Imposing a fine on a unit — and sealing it in the same request.
abstract class FineRepository {
  /// Imposes a fine on the unit [propertyId].
  ///
  /// One call posts the receivable, raises a payable challan, issues a payment
  /// link and texts the person fined, all in one transaction. Two things the UI
  /// has to get right afterwards:
  ///
  /// * **The fine stands even if the seal is refused.** When
  ///   `FineRequest.seal` was sent and `Fine.sealApplied` comes back false, show
  ///   the fine as imposed and the seal as a separate notice. Do not present
  ///   the whole thing as failed.
  /// * A fine is a separate debt from the rent. Never add `Fine.challan`'s
  ///   balance to the unit's rent arrears, and never merge the two payment
  ///   links into one figure.
  ///
  /// Set `FineRequest.offender` to fine somebody who is not on the register —
  /// `UnitCard.needsOffenderDetails` is the server saying it must be. The unit
  /// must still be one of MCQ's own; the units search returns the vacant ones.
  ///
  /// Retry with the same [request] instance, never a rebuilt one: its
  /// `client_action_uuid` is what stops a resend becoming a second fine.
  Future<Fine> impose({required int propertyId, required FineRequest request});
}

class ApiFineRepository implements FineRepository {
  ApiFineRepository({required this._api});

  final ApiService _api;

  @override
  Future<Fine> impose({
    required int propertyId,
    required FineRequest request,
  }) async {
    final response = await _api.post(
      ApiPaths.propertyFines(propertyId),
      body: request.toJson(),
    );
    return Fine.fromJson(response.dataMap);
  }
}
