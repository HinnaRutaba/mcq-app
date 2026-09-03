import '../core/utils/json_parse.dart';
import 'api_refs.dart';

/// One entry on a case's visit timeline: a visit, a warning, a notice, a
/// promise to pay, a fine, a seal.
class EnforcementAction {
  const EnforcementAction({
    this.id,
    this.enforcementCaseId,
    this.actionType,
    this.actionTypeId,
    this.actionDate,
    required this.amounts,
    this.promisedPaymentDate,
    this.nextVisitDate,
    this.sealNo,
    required this.location,
    this.photoPath,
    this.signaturePath,
    this.witnessName,
    this.remarks,
    required this.sync,
    this.performedBy,
  });

  final int? id;
  final int? enforcementCaseId;

  /// Already labelled for display, e.g. "Visited the shop", "Notice handed
  /// over", "Fine imposed". The response set is wider than what can be posted:
  /// `fine_imposed` appears here but is created by the fine endpoint, not by
  /// recording an action.
  final LabelledValue? actionType;

  /// The definitions row behind [actionType] — `ActionTypeDefinition.id`. The
  /// id to match on when the server has renamed the label since the app cached
  /// the definitions.
  final int? actionTypeId;

  final DateTime? actionDate;
  final ActionAmounts amounts;

  /// When the shopkeeper said they would pay.
  final DateTime? promisedPaymentDate;

  final DateTime? nextVisitDate;

  /// Set on the action that applied a seal.
  final String? sealNo;

  final ActionLocation location;

  /// Server-side paths returned by the evidence upload.
  final String? photoPath;
  final String? signaturePath;

  final String? witnessName;
  final String? remarks;

  /// How and when this reached the server — the audit trail for a record made
  /// offline in a bazaar and synced later.
  final ActionSync sync;

  final UserRef? performedBy;

  factory EnforcementAction.fromJson(Map<String, dynamic> json) =>
      EnforcementAction(
        id: Json.integer(json['id']),
        enforcementCaseId: Json.integer(json['enforcement_case_id']),
        actionType: LabelledValue.maybe(json['action_type']),
        actionTypeId: Json.integer(json['action_type_id']),
        actionDate: Json.dateTime(json['action_date']),
        amounts: ActionAmounts.fromJson(Json.map(json['amounts'])),
        promisedPaymentDate: Json.dateTime(json['promised_payment_date']),
        nextVisitDate: Json.dateTime(json['next_visit_date']),
        sealNo: Json.string(json['seal_no']),
        location: ActionLocation.fromJson(Json.map(json['location'])),
        photoPath: Json.string(json['photo_path']),
        signaturePath: Json.string(json['signature_path']),
        witnessName: Json.string(json['witness_name']),
        remarks: Json.string(json['remarks']),
        sync: ActionSync.fromJson(Json.map(json['sync'])),
        performedBy: UserRef.maybe(json['performed_by']),
      );

  bool get hasPhoto => photoPath != null;
}

class ActionAmounts {
  const ActionAmounts({this.outstandingAtAction, this.fineAmount});

  /// What was owed at the moment of the visit, as a string — the figure quoted
  /// to the shopkeeper on the day.
  final String? outstandingAtAction;

  /// Set on a fine action.
  final String? fineAmount;

  factory ActionAmounts.fromJson(Map<String, dynamic> json) => ActionAmounts(
    outstandingAtAction: Json.money(json['outstanding_at_action']),
    fineAmount: Json.money(json['fine_amount']),
  );
}

/// Where the officer was standing. [hasFix] is the server's own answer to
/// "was a location actually recorded" — trust it over checking for nulls.
class ActionLocation {
  const ActionLocation({
    this.latitude,
    this.longitude,
    this.accuracyM,
    this.hasFix = false,
  });

  final String? latitude;
  final String? longitude;

  /// Reported accuracy of the fix, in metres.
  final double? accuracyM;

  final bool hasFix;

  factory ActionLocation.fromJson(Map<String, dynamic> json) => ActionLocation(
    latitude: Json.string(json['latitude']),
    longitude: Json.string(json['longitude']),
    accuracyM: Json.decimal(json['accuracy_m']),
    hasFix: Json.booleanOr(json['has_fix']),
  );

  GeoPoint get point => GeoPoint(latitude: latitude, longitude: longitude);
}

/// The offline/sync audit trail on a record.
class ActionSync {
  const ActionSync({
    this.recordedOffline = false,
    this.deviceRecordedAt,
    this.syncedAt,
    this.lagMinutes,
    this.clientActionUuid,
  });

  /// Written on the handset with no signal, and sent later.
  final bool recordedOffline;

  /// When the officer actually recorded it.
  final DateTime? deviceRecordedAt;

  /// When the server received it.
  final DateTime? syncedAt;

  /// The gap between the two.
  final int? lagMinutes;

  /// The handset's idempotency key for this write. Its presence is what made a
  /// retry safe.
  final String? clientActionUuid;

  factory ActionSync.fromJson(Map<String, dynamic> json) => ActionSync(
    recordedOffline: Json.booleanOr(json['recorded_offline']),
    deviceRecordedAt: Json.dateTime(json['device_recorded_at']),
    syncedAt: Json.dateTime(json['synced_at']),
    lagMinutes: Json.integer(json['lag_minutes']),
    clientActionUuid: Json.string(json['client_action_uuid']),
  );
}
