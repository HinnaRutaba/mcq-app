import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/read_cache.dart';
import '../../../models/common/fetched.dart';
import '../../../models/common/pagination_meta.dart';
import '../../../models/common/write_outcome.dart';
import '../../../models/enforcement/enforcement_case.dart';
import '../../../models/enforcement/field_evidence.dart';
import '../../../models/enforcement/fine.dart';
import '../../../models/enforcement/seal.dart';

/// The `/enforcement` module: cases, their timeline, seals, fines, and the
/// evidence upload that every field write hangs off.
///
/// All four field writes are idempotent on `client_action_uuid`, which
/// [FieldEvidence] always carries. That is what makes retrying on a flaky
/// connection safe — it cannot double-seal a shop or fine a shopkeeper
/// twice.
class EnforcementRepository {
  EnforcementRepository({required ApiClient client, required ReadCache cache})
      : _client = client,
        _cache = cache;

  final ApiClient _client;
  final ReadCache _cache;

  // --- Cases ------------------------------------------------------------

  Future<Fetched<Paginated<EnforcementCase>>> cases({
    String? status,
    String? search,
    String? sort,
    int? propertyId,
    bool assignedToMe = false,
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
  }) async {
    final query = {
      ApiConstants.qStatus: status,
      ApiConstants.qSearch: search,
      ApiConstants.qSort: sort,
      ApiConstants.qPropertyId: propertyId,
      // Cases can be assigned to a magistrate by the taxation branch. The
      // server resolves "me" from the token; the app never sends a user id.
      if (assignedToMe) ApiConstants.qMagistrateId: ApiConstants.magistrateMe,
      ApiConstants.qPage: page,
      ApiConstants.qPerPage: perPage,
    };
    try {
      final envelope = await _client.get(ApiConstants.cases, query: query);
      if (page == 1 &&
          status == null &&
          search == null &&
          propertyId == null &&
          !assignedToMe) {
        await _cache.write(ReadCache.cases, {
          'data': envelope.list,
          'meta': envelope.meta,
        });
      }
      return Fetched(
        value: Paginated(
          items: _casesFrom(envelope.list),
          meta: PaginationMeta.fromJson(envelope.meta),
        ),
        fetchedAt: DateTime.now(),
      );
    } on ApiException catch (error) {
      final cached = error.isNetwork && page == 1
          ? _cache.readMap(ReadCache.cases)
          : null;
      if (cached == null) rethrow;
      return Fetched(
        value: Paginated(
          items: _casesFrom(cached.value['data'] as List? ?? const []),
          meta: PaginationMeta.fromJson(
            (cached.value['meta'] as Map?)?.cast<String, dynamic>(),
          ),
        ),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }
  }

  List<EnforcementCase> _casesFrom(List<dynamic> raw) => raw
      .whereType<Map<String, dynamic>>()
      .map(EnforcementCase.fromJson)
      .toList();

  Future<EnforcementCase> caseById(int caseId) async {
    final envelope = await _client.get(ApiConstants.caseById(caseId));
    return EnforcementCase.fromJson(envelope.map);
  }

  /// The timeline, newest first. Sorting is asked of the server so the app
  /// and the web application agree on the order.
  Future<Paginated<CaseAction>> caseActions(
    int caseId, {
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
  }) async {
    final envelope = await _client.get(
      ApiConstants.caseActions(caseId),
      query: {
        ApiConstants.qSort: '-action_date',
        ApiConstants.qPage: page,
        ApiConstants.qPerPage: perPage,
      },
    );
    return Paginated(
      items: envelope.list
          .whereType<Map<String, dynamic>>()
          .map(CaseAction.fromJson)
          .toList(),
      meta: PaginationMeta.fromJson(envelope.meta),
    );
  }

  /// `POST /enforcement/cases/{case}/actions` — recording a visit or a
  /// notice served. The first write, and the pattern every other write
  /// follows: no optimistic UI, spinner on the button, 422 binds to the
  /// fields, 409 opens a dialog with the server's sentence, success
  /// refreshes the timeline.
  Future<WriteOutcome<CaseAction>> recordAction({
    required int caseId,
    required String actionType,
    required FieldEvidence evidence,
    DateTime? promisedPaymentDate,
    DateTime? nextVisitDate,
  }) async {
    final envelope = await _client.post(
      ApiConstants.caseActions(caseId),
      body: {
        'action_type': actionType,
        // A promise and a revisit are the same write with one extra date
        // on it. That date is what puts the shop back in front of the
        // officer — on its card, and in the follow-ups queue — so it is
        // sent as a real field and never buried in the remarks.
        if (promisedPaymentDate != null)
          'promised_payment_date': FieldEvidence.apiDate(promisedPaymentDate),
        if (nextVisitDate != null)
          'next_visit_date': FieldEvidence.apiDate(nextVisitDate),
        ...evidence.toJson(),
      },
    );
    return WriteOutcome(
      value: CaseAction.fromJson(envelope.map),
      wasCreated: envelope.wasCreated,
      message: envelope.message,
    );
  }

  /// `POST /enforcement/cases/{case}/seal`. Confirmed before it is called,
  /// naming the shop and the allottee — sealing closes somebody's
  /// livelihood.
  Future<WriteOutcome<Seal>> sealShop({
    required int caseId,
    required String reason,
    required FieldEvidence evidence,
  }) async {
    final json = evidence.toJson();
    final envelope = await _client.post(
      ApiConstants.caseSeal(caseId),
      body: {
        // Two documents name this field two ways — the contract-derived
        // client sent `reason` and `action_date`; the build brief names
        // `seal_reason`, `sealed_on` and `seal_photo_path`. Both go until
        // MCQ says which is real, because a seal refused by a 422 on a
        // field name is an officer standing at a shutter with nothing to
        // show for it. Filed in QUESTIONS.md.
        'reason': reason,
        'seal_reason': reason,
        'sealed_on': json['action_date'],
        if (json['photo_path'] != null) 'seal_photo_path': json['photo_path'],
        ...json,
      },
    );
    return WriteOutcome(
      value: Seal.fromJson(envelope.map),
      wasCreated: envelope.wasCreated,
      message: envelope.message,
    );
  }

  /// `POST /enforcement/cases/{case}/close`.
  Future<WriteOutcome<EnforcementCase>> closeCase({
    required int caseId,
    required String closingRemarks,
  }) async {
    final envelope = await _client.post(
      ApiConstants.caseClose(caseId),
      body: {'closing_remarks': closingRemarks},
    );
    return WriteOutcome(
      value: EnforcementCase.fromJson(envelope.map),
      wasCreated: envelope.wasCreated,
      message: envelope.message,
    );
  }

  /// `POST /enforcement/allotments/{allotment}/cases` — open a file against
  /// a property whose allottee is behind.
  Future<WriteOutcome<EnforcementCase>> openCase({
    required int allotmentId,
    String? remarks,
  }) async {
    final envelope = await _client.post(
      ApiConstants.openCaseForAllotment(allotmentId),
      body: {if ((remarks ?? '').isNotEmpty) 'remarks': remarks},
    );
    return WriteOutcome(
      value: EnforcementCase.fromJson(envelope.map),
      wasCreated: envelope.wasCreated,
      message: envelope.message,
    );
  }

  // --- Seals ------------------------------------------------------------

  Future<Fetched<Paginated<Seal>>> seals({
    String? status,
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
  }) async {
    final query = {
      ApiConstants.qStatus: status,
      ApiConstants.qPage: page,
      ApiConstants.qPerPage: perPage,
    };
    try {
      final envelope = await _client.get(ApiConstants.seals, query: query);
      if (page == 1 && status == null) {
        await _cache.write(ReadCache.seals, {
          'data': envelope.list,
          'meta': envelope.meta,
        });
      }
      return Fetched(
        value: Paginated(
          items: _sealsFrom(envelope.list),
          meta: PaginationMeta.fromJson(envelope.meta),
        ),
        fetchedAt: DateTime.now(),
      );
    } on ApiException catch (error) {
      final cached =
          error.isNetwork && page == 1 ? _cache.readMap(ReadCache.seals) : null;
      if (cached == null) rethrow;
      return Fetched(
        value: Paginated(
          items: _sealsFrom(cached.value['data'] as List? ?? const []),
          meta: PaginationMeta.fromJson(
            (cached.value['meta'] as Map?)?.cast<String, dynamic>(),
          ),
        ),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }
  }

  List<Seal> _sealsFrom(List<dynamic> raw) =>
      raw.whereType<Map<String, dynamic>>().map(Seal.fromJson).toList();

  Future<Seal> sealById(int sealId) async {
    final envelope = await _client.get(ApiConstants.sealById(sealId));
    return Seal.fromJson(envelope.map);
  }

  /// `POST /enforcement/seals/{seal}/release`. Refused with a 409 while
  /// dues stand — show the server's sentence in a dialog, not a toast: the
  /// officer has to read it standing in front of a shopkeeper who is
  /// arguing with them.
  Future<WriteOutcome<Seal>> releaseSeal({
    required int sealId,
    required FieldEvidence evidence,
    String? unsealReason,
  }) async {
    final json = evidence.toJson();
    final envelope = await _client.post(
      ApiConstants.sealRelease(sealId),
      body: {
        if ((unsealReason ?? '').trim().isNotEmpty)
          'unseal_reason': unsealReason!.trim(),
        'unsealed_on': json['action_date'],
        ...json,
      },
    );
    return WriteOutcome(
      value: Seal.fromJson(envelope.map),
      wasCreated: envelope.wasCreated,
      message: envelope.message,
    );
  }

  // --- Fines ------------------------------------------------------------

  Future<Fetched<Paginated<Fine>>> fines({
    int? propertyId,
    int page = 1,
    int perPage = ApiConstants.defaultPerPage,
  }) async {
    final query = {
      'property_id': propertyId,
      ApiConstants.qPage: page,
      ApiConstants.qPerPage: perPage,
    };
    try {
      final envelope = await _client.get(ApiConstants.fines, query: query);
      if (page == 1 && propertyId == null) {
        await _cache.write(ReadCache.fines, {
          'data': envelope.list,
          'meta': envelope.meta,
        });
      }
      return Fetched(
        value: Paginated(
          items: _finesFrom(envelope.list),
          meta: PaginationMeta.fromJson(envelope.meta),
        ),
        fetchedAt: DateTime.now(),
      );
    } on ApiException catch (error) {
      final cached =
          error.isNetwork && page == 1 ? _cache.readMap(ReadCache.fines) : null;
      if (cached == null) rethrow;
      return Fetched(
        value: Paginated(
          items: _finesFrom(cached.value['data'] as List? ?? const []),
          meta: PaginationMeta.fromJson(
            (cached.value['meta'] as Map?)?.cast<String, dynamic>(),
          ),
        ),
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }
  }

  List<Fine> _finesFrom(List<dynamic> raw) =>
      raw.whereType<Map<String, dynamic>>().map(Fine.fromJson).toList();

  /// `POST /enforcement/properties/{property}/fines`.
  ///
  /// Two cases, and the app handles both. With a live agreement the server
  /// finds the holder itself — `allotment_id` is not computed client-side
  /// and the offender fields are refused as unnecessary. With no live
  /// agreement, [offenderName] and [offenderMobileNo] are required: a fine
  /// nobody can be asked to pay is refused by the database itself.
  Future<FineOutcome> imposeFine({
    required int propertyId,
    required String fineType,
    required String fineAmount,
    required String legalProvision,
    required FieldEvidence evidence,
    String? offenderName,
    String? offenderMobileNo,
    String? offenderCnic,
  }) async {
    final json = evidence.toJson();
    final envelope = await _client.post(
      ApiConstants.propertyFines(propertyId),
      body: {
        'fine_type': fineType,
        // The amount is passed through as the string the officer typed —
        // never parsed to a double on the way out either.
        'fine_amount': fineAmount,
        // Required even though the column is nullable: a fine with no
        // provision named is unenforceable in front of a magistrate's own
        // court.
        'legal_provision': legalProvision,
        'imposed_on': json['action_date'],
        // Case 2 — nobody holds the unit. A penalty nobody can be asked to
        // pay is not a penalty, and a database constraint says so.
        if ((offenderName ?? '').isNotEmpty) 'offender_name': offenderName,
        if ((offenderMobileNo ?? '').isNotEmpty)
          'offender_mobile_no': offenderMobileNo,
        if ((offenderCnic ?? '').isNotEmpty) 'offender_cnic': offenderCnic,
        ...json,
      },
    );
    return FineOutcome.fromJson(
      envelope.map,
      wasCreated: envelope.wasCreated,
      message: envelope.message,
    );
  }

  // --- Evidence ---------------------------------------------------------

  /// `POST /enforcement/evidence` — upload the image, get a path back, then
  /// send that path with the action.
  ///
  /// Two steps on purpose: on a weak signal the image uploads once and the
  /// action can be retried as often as the handset likes without
  /// re-sending two megabytes, and a failed action does not lose the
  /// photograph — the file is already stored under a name the client holds.
  ///
  /// Throttled to 60 uploads a minute. The stored name is a fresh ULID and
  /// the sniffed type is validated, so the filename and declared content
  /// type do not matter. SVG is rejected.
  Future<EvidenceUpload> uploadEvidence({
    required File file,
    String kind = EvidenceUpload.kindPhoto,
    void Function(int sent, int total)? onProgress,
  }) async {
    final envelope = await _client.postMultipart(
      ApiConstants.evidence,
      fields: {'kind': kind},
      files: {'file': file},
      onSendProgress: onProgress,
    );
    return EvidenceUpload.fromJson(envelope.map);
  }
}
