import '../core/utils/json_parse.dart';
import 'api_refs.dart';

/// A sealed shop, as the officer's seal list and unseal queue return it.
///
/// [readyToRelease] is the server's own judgement, and the only thing that
/// should gate the release button: it is true when no fine on the unit is
/// outstanding *and* at least one has actually been paid. Releasing a seal that
/// is not ready needs an override reason — see `SealReleaseRequest`.
///
/// A caution on the field names: the published spec captured this list only
/// while it was empty, so the keys below are read leniently and the untouched
/// payload is kept in [raw]. If a field you need is missing here, read it from
/// [raw] and then add it properly rather than guessing at a getter.
class FieldSeal {
  const FieldSeal({
    this.id,
    this.sealNo,
    this.status,
    this.sealedOn,
    this.sealReason,
    this.readyToRelease = false,
    this.isSealed = true,
    this.releasedOn,
    this.unsealReason,
    this.propertyId,
    this.propertyCode,
    this.shopNo,
    this.areaId,
    this.areaName,
    this.marketName,
    this.allotmentId,
    this.allotmentNo,
    this.allotteeId,
    this.allotteeName,
    this.mobileNo,
    this.outstanding,
    this.enforcementCaseId,
    this.caseNo,
    this.sealedBy,
    this.raw = const <String, dynamic>{},
  });

  final int? id;

  /// The number written on the seal itself.
  final String? sealNo;

  /// Read from either a labelled object or a bare string, whichever the server
  /// sends.
  final LabelledValue? status;

  final DateTime? sealedOn;
  final String? sealReason;

  /// The unseal queue's condition: every fine on the unit settled, and at least
  /// one of them actually paid.
  final bool readyToRelease;

  final bool isSealed;
  final DateTime? releasedOn;
  final String? unsealReason;

  final int? propertyId;
  final String? propertyCode;
  final String? shopNo;
  final int? areaId;
  final String? areaName;
  final String? marketName;

  final int? allotmentId;
  final String? allotmentNo;
  final int? allotteeId;
  final String? allotteeName;
  final String? mobileNo;

  /// Owed on the unit, as a string.
  final String? outstanding;

  final int? enforcementCaseId;
  final String? caseNo;
  final UserRef? sealedBy;

  /// The response exactly as it arrived, for fields not surfaced above.
  final Map<String, dynamic> raw;

  factory FieldSeal.fromJson(Map<String, dynamic> json) => FieldSeal(
    id: Json.integer(json['id']),
    sealNo: Json.string(json['seal_no']),
    status: LabelledValue.maybe(
      Json.pick(json, <String>['seal_status', 'status']),
    ),
    sealedOn: Json.dateTime(json['sealed_on']),
    sealReason: Json.string(json['seal_reason']),
    readyToRelease: Json.booleanOr(
      Json.pick(json, <String>['ready_to_release', 'ready']),
    ),
    isSealed: Json.booleanOr(json['is_sealed'], true),
    releasedOn: Json.dateTime(
      Json.pick(json, <String>['released_on', 'unsealed_on']),
    ),
    unsealReason: Json.string(json['unseal_reason']),
    propertyId: Json.integer(json['property_id']),
    propertyCode: Json.string(json['property_code']),
    shopNo: Json.string(json['shop_no']),
    areaId: Json.integer(json['area_id']),
    areaName: Json.string(json['area_name']),
    marketName: Json.string(json['market_name']),
    allotmentId: Json.integer(json['allotment_id']),
    allotmentNo: Json.string(json['allotment_no']),
    allotteeId: Json.integer(json['allottee_id']),
    allotteeName: Json.string(json['allottee_name']),
    mobileNo: Json.string(json['mobile_no']),
    outstanding: Json.money(json['outstanding']),
    enforcementCaseId: Json.integer(json['enforcement_case_id']),
    caseNo: Json.string(json['case_no']),
    sealedBy: UserRef.maybe(
      Json.pick(json, <String>['sealed_by', 'performed_by']),
    ),
    raw: json,
  );
}
