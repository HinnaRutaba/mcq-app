import '../core/utils/json_parse.dart';
import 'api_refs.dart';

/// One unit from the search list — every unit on the register, not only the
/// defaulters.
///
/// A shop that is fully paid up never appears in the defaulter list, and it is
/// exactly the one the officer is standing in front of. Tenancy fields are null
/// where nobody holds the unit.
class UnitCard {
  const UnitCard({
    this.propertyId,
    this.propertyCode,
    this.shopNo,
    this.occupancyStatus,
    this.areaId,
    this.areaName,
    this.marketName,
    this.isVacant = false,
    this.allotmentId,
    this.allotmentNo,
    this.allotteeId,
    this.allotteeName,
    this.mobileNo,
    this.cnic,
    required this.outstanding,
    this.lastPaymentDate,
    this.openCaseId,
    this.sealNo,
    this.isSealed = false,
    this.canFineHolder = false,
    this.needsOffenderDetails = false,
    this.map,
  });

  final int? propertyId;
  final String? propertyCode;
  final String? shopNo;

  /// e.g. `allotted`, `vacant`.
  final String? occupancyStatus;

  final int? areaId;
  final String? areaName;
  final String? marketName;
  final bool isVacant;

  final int? allotmentId;
  final String? allotmentNo;
  final int? allotteeId;
  final String? allotteeName;
  final String? mobileNo;
  final String? cnic;

  /// Rent arrears owed, as a string.
  final String outstanding;

  final DateTime? lastPaymentDate;
  final int? openCaseId;
  final String? sealNo;
  final bool isSealed;

  /// Whether a fine can be billed to the person holding the unit.
  final bool canFineHolder;

  /// When true the fine form must collect the offender's own name, father's
  /// name and mobile instead of billing a tenant — there is nobody on the
  /// register to bill.
  final bool needsOffenderDetails;

  final GeoPoint? map;

  factory UnitCard.fromJson(Map<String, dynamic> json) => UnitCard(
    propertyId: Json.integer(json['property_id']),
    propertyCode: Json.string(json['property_code']),
    shopNo: Json.string(json['shop_no']),
    occupancyStatus: Json.string(json['occupancy_status']),
    areaId: Json.integer(json['area_id']),
    areaName: Json.string(json['area_name']),
    marketName: Json.string(json['market_name']),
    isVacant: Json.booleanOr(json['is_vacant']),
    allotmentId: Json.integer(json['allotment_id']),
    allotmentNo: Json.string(json['allotment_no']),
    allotteeId: Json.integer(json['allottee_id']),
    allotteeName: Json.string(json['allottee_name']),
    mobileNo: Json.string(json['mobile_no']),
    cnic: Json.string(json['cnic']),
    outstanding: Json.moneyOr(json['outstanding']),
    lastPaymentDate: Json.dateTime(json['last_payment_date']),
    openCaseId: Json.integer(json['open_case_id']),
    sealNo: Json.string(json['seal_no']),
    isSealed: Json.booleanOr(json['is_sealed']),
    canFineHolder: Json.booleanOr(json['can_fine_holder']),
    needsOffenderDetails: Json.booleanOr(json['needs_offender_details']),
    map: GeoPoint.maybe(json['map']),
  );

  bool get hasOpenCase => openCaseId != null;
}
