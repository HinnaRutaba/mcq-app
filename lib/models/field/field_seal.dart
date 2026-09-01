import '../../core/utils/json_reader.dart';
import '../common/money.dart';

/// One row of `GET /enforcement/field/seals`.
///
/// **One list, two readings**, and that is deliberate. MCQ asked both for
/// "what have I sealed" and "what now needs unsealing"; splitting them into
/// two endpoints would let them drift and leave a seal in neither.
/// `?ready=1` filters the same list rather than fetching a different one.
class FieldSeal {
  const FieldSeal({
    required this.sealId,
    required this.sealNo,
    required this.propertyId,
    required this.propertyCode,
    required this.shopNo,
    required this.areaName,
    required this.allotteeName,
    required this.finesUnpaid,
    required this.finesPaid,
    required this.readyToRelease,
    this.sealedOn,
    this.sealReason,
    this.caseId,
    this.caseNo,
    this.allotmentNo,
    this.mobileNo,
    this.outstandingAtSeal,
    this.outstandingNow,
  });

  final int sealId;
  final String sealNo;
  final DateTime? sealedOn;
  final String? sealReason;

  final int propertyId;
  final String propertyCode;
  final String shopNo;
  final String areaName;

  final int? caseId;
  final String? caseNo;
  final String? allotmentNo;
  final String allotteeName;
  final String? mobileNo;

  final Money? outstandingAtSeal;

  /// Shown, but it **does not gate the release**. Sealing answers the
  /// offence the fine names; holding the shutter closed until the whole
  /// arrears history is cleared is a much heavier decision, and not one the
  /// app should quietly make on the officer's behalf.
  final Money? outstandingNow;

  final int finesUnpaid;
  final int finesPaid;

  /// The server's rule, in MCQ's own words: *"after the allottee submits
  /// and pays that challan of fine, magistrate is responsible to unseal
  /// it"*. True when no fine on the unit is still outstanding **and** at
  /// least one has actually been paid. Never recomputed here.
  final bool readyToRelease;

  factory FieldSeal.fromJson(Map<String, dynamic> json) => FieldSeal(
        sealId: json.intOr('seal_id') ,
        sealNo: json.strOr('seal_no'),
        sealedOn: json.date('sealed_on'),
        sealReason: json.str('seal_reason'),
        propertyId: json.intOr('property_id'),
        propertyCode: json.strOr('property_code'),
        shopNo: json.strOr('shop_no'),
        areaName: json.strOr('area_name'),
        caseId: json.integer('case_id'),
        caseNo: json.str('case_no'),
        allotmentNo: json.str('allotment_no'),
        allotteeName: json.strOr('allottee_name'),
        mobileNo: json.str('mobile_no'),
        outstandingAtSeal: json.moneyOrNull('outstanding_at_seal'),
        outstandingNow: json.moneyOrNull('outstanding_now'),
        finesUnpaid: json.intOr('fines_unpaid'),
        finesPaid: json.intOr('fines_paid'),
        readyToRelease: json.boolean('ready_to_release'),
      );

  static List<FieldSeal> listFrom(List<dynamic> raw) => raw
      .whereType<Map<String, dynamic>>()
      .map(FieldSeal.fromJson)
      .toList(growable: false);

  String get unitLabel =>
      shopNo.isEmpty ? propertyCode : '$propertyCode · $shopNo';

  bool get isCallable => (mobileNo ?? '').trim().isNotEmpty;
}
