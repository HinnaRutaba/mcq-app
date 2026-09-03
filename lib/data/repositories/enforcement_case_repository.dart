import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../models/api_response.dart';
import '../../models/enforcement_action.dart';
import '../../models/enforcement_action_request.dart';
import '../../models/enforcement_case.dart';
import '../../models/field_case_request.dart';
import '../../models/field_seal.dart';
import '../../models/seal_requests.dart';

/// Enforcement cases, their visit timelines, and the writes an officer makes
/// against them from the field.
abstract class EnforcementCaseRepository {
  /// The case list, paged.
  ///
  /// [assignedToMe] narrows to the cases the taxation branch put in this
  /// officer's name (`magistrate_id=me`).
  Future<Paginated<EnforcementCase>> cases({
    int? page,
    int? perPage,
    bool assignedToMe,
  });

  /// The visit timeline for one case, oldest first.
  Future<List<EnforcementAction>> actions(int caseId);

  /// Opens a case from the handset.
  ///
  /// Two kinds, and the server refuses to guess between them — build it with
  /// `FieldCaseRequest.recovery` for arrears or `FieldCaseRequest.conduct` for
  /// what is happening at a unit. Sending both a tenancy and a unit is
  /// rejected rather than resolved, because either precedence would open a
  /// different kind of case from the one the officer meant.
  ///
  /// On a recovery case the server derives the priority from what is owed, so
  /// leaving `priority` null is usually right.
  Future<EnforcementCase> openCase(FieldCaseRequest request);

  /// Records a visit, a warning, a notice or a promise.
  ///
  /// On a weak signal, retry with **the same [request] instance**: its
  /// `client_action_uuid` is what makes the resend land as the same record
  /// rather than a second one.
  Future<EnforcementAction> recordAction(
    int caseId,
    EnforcementActionRequest request,
  );

  /// Seals the unit on a case, when the seal does not accompany a fine. To do
  /// both in one transaction, use `FineRepository.impose` with
  /// `FineRequest.seal`.
  ///
  /// Check `EnforcementCase.canSeal` first — sealing has preconditions the app
  /// cannot see.
  ///
  /// The published spec does not capture this response, so it is read
  /// leniently; the untouched payload is on `FieldSeal.raw`.
  Future<FieldSeal> seal(int caseId, CaseSealRequest request);
}

class ApiEnforcementCaseRepository implements EnforcementCaseRepository {
  ApiEnforcementCaseRepository({required this._api});

  final ApiService _api;

  @override
  Future<Paginated<EnforcementCase>> cases({
    int? page,
    int? perPage,
    bool assignedToMe = false,
  }) async {
    final response = await _api.get(
      ApiPaths.cases,
      query: <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'magistrate_id': assignedToMe ? 'me' : null,
      },
    );
    return Paginated<EnforcementCase>.fromResponse(
      response,
      EnforcementCase.fromJson,
    );
  }

  @override
  Future<List<EnforcementAction>> actions(int caseId) async {
    final response = await _api.get(ApiPaths.caseActions(caseId));
    return response.dataList.map(EnforcementAction.fromJson).toList();
  }

  @override
  Future<EnforcementCase> openCase(FieldCaseRequest request) async {
    final response = await _api.post(
      ApiPaths.fieldCases,
      body: request.toJson(),
    );
    return EnforcementCase.fromJson(response.dataMap);
  }

  @override
  Future<EnforcementAction> recordAction(
    int caseId,
    EnforcementActionRequest request,
  ) async {
    final response = await _api.post(
      ApiPaths.caseActions(caseId),
      body: request.toJson(),
    );
    return EnforcementAction.fromJson(response.dataMap);
  }

  @override
  Future<FieldSeal> seal(int caseId, CaseSealRequest request) async {
    final response = await _api.post(
      ApiPaths.caseSeal(caseId),
      body: request.toJson(),
    );
    return FieldSeal.fromJson(response.dataMap);
  }
}
