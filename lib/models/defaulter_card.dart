import '../core/utils/json_parse.dart';
import 'api_refs.dart';

/// One row of the defaulter list, and the stops on today's round.
///
/// Everything needed to decide is on the card — the app never makes a second
/// call to draw a row.
///
/// [outstanding] is rent arrears. A fine is a separate debt on a separate
/// challan: one person can hold a live rent link and a live fine link at once,
/// and the two are never added together.
class DefaulterCard {
  const DefaulterCard({
    this.allotmentId,
    this.allotmentNo,
    this.propertyId,
    this.propertyCode,
    this.shopNo,
    this.areaId,
    this.areaName,
    this.marketName,
    this.allotteeId,
    this.allotteeName,
    this.mobileNo,
    this.cnic,
    required this.outstanding,
    this.monthsBehind,
    this.daysOverdue,
    this.neverPaid = false,
    this.lastPaymentDate,
    this.commitment,
    this.nextVisitDate,
    this.openCaseId,
    this.sealNo,
    this.isSealed = false,
    this.map,
  });

  final int? allotmentId;
  final String? allotmentNo;
  final int? propertyId;
  final String? propertyCode;

  /// e.g. `F-3`, `S-22`.
  final String? shopNo;

  final int? areaId;

  /// The bazaar's official area, e.g. "Prince Road".
  final String? areaName;

  /// The market within it, e.g. "Prince Road Market".
  final String? marketName;

  final int? allotteeId;
  final String? allotteeName;
  final String? mobileNo;
  final String? cnic;

  /// Rent arrears owed, as a string. Never parsed, never summed in Dart.
  final String outstanding;

  final int? monthsBehind;
  final int? daysOverdue;

  /// Has never paid anything at all — a different problem from having fallen
  /// behind, and worth saying so on the card.
  final bool neverPaid;

  final DateTime? lastPaymentDate;

  /// A promise to pay, when one is on record. Kept as the raw payload: the
  /// published spec never captured a non-null commitment, so its shape is not
  /// pinned down yet.
  final Map<String, dynamic>? commitment;

  final DateTime? nextVisitDate;

  /// The live enforcement case on this unit, when there is one.
  final int? openCaseId;

  final String? sealNo;
  final bool isSealed;

  /// Where the shop is, for a map pin or a walking route.
  final GeoPoint? map;

  factory DefaulterCard.fromJson(Map<String, dynamic> json) => DefaulterCard(
    allotmentId: Json.integer(json['allotment_id']),
    allotmentNo: Json.string(json['allotment_no']),
    propertyId: Json.integer(json['property_id']),
    propertyCode: Json.string(json['property_code']),
    shopNo: Json.string(json['shop_no']),
    areaId: Json.integer(json['area_id']),
    areaName: Json.string(json['area_name']),
    marketName: Json.string(json['market_name']),
    allotteeId: Json.integer(json['allottee_id']),
    allotteeName: Json.string(json['allottee_name']),
    mobileNo: Json.string(json['mobile_no']),
    cnic: Json.string(json['cnic']),
    outstanding: Json.moneyOr(json['outstanding']),
    monthsBehind: Json.integer(json['months_behind']),
    daysOverdue: Json.integer(json['days_overdue']),
    neverPaid: Json.booleanOr(json['never_paid']),
    lastPaymentDate: Json.dateTime(json['last_payment_date']),
    commitment: Json.mapOrNull(json['commitment']),
    nextVisitDate: Json.dateTime(json['next_visit_date']),
    openCaseId: Json.integer(json['open_case_id']),
    sealNo: Json.string(json['seal_no']),
    isSealed: Json.booleanOr(json['is_sealed']),
    map: GeoPoint.maybe(json['map']),
  );

  bool get hasOpenCase => openCaseId != null;

  bool get hasCommitment => commitment != null && commitment!.isNotEmpty;
}
