import '../core/utils/json_parse.dart';
import 'api_refs.dart';

/// A trade licence, and the shop it was issued to.
///
/// A different register from everything in the enforcement module. These are
/// the businesses MCQ licenses but is not landlord to: nothing here has an
/// allotment, an allottee or a property, and a licence is keyed on a CNIC and a
/// mobile number. Do not try to join the two registers in the app.
class TradeLicence {
  const TradeLicence({
    this.id,
    this.licenceNo,
    this.verificationCode,
    this.holderName,
    this.fatherName,
    this.cnic,
    this.mobileNo,
    this.businessName,
    this.shopAddress,
    this.trade,
    this.areaName,
    this.zoneName,
    this.status,
    this.issuedOn,
    this.validFrom,
    this.validTo,
    this.daysRemaining,
    this.isValid = false,
    this.mapPin,
    this.raw = const <String, dynamic>{},
  });

  final int? id;

  /// e.g. `MCQ-TL-000001`.
  final String? licenceNo;

  /// What a shopkeeper shows and an officer checks, e.g. `TL-1W8J-QKIP`.
  final String? verificationCode;

  final String? holderName;
  final String? fatherName;
  final String? cnic;
  final String? mobileNo;

  /// e.g. "Quetta Kabab House".
  final String? businessName;

  final String? shopAddress;

  /// The licensed trade, e.g. "Restaurant".
  final String? trade;

  final String? areaName;
  final String? zoneName;

  /// e.g. `active`. Read [isValid] rather than comparing this string.
  final String? status;

  final DateTime? issuedOn;
  final DateTime? validFrom;
  final DateTime? validTo;

  /// The server's own count of days left. Negative on a lapsed licence, so do
  /// not assume it is positive.
  final int? daysRemaining;

  /// The server's answer to "may this shop trade today". The only thing that
  /// should gate the officer's decision — never a date comparison of your own.
  final bool isValid;

  /// Where the shop is, when the licence carries a pin. Often null: this
  /// register is not the property register and most rows were never surveyed.
  final GeoPoint? mapPin;

  /// The response exactly as it arrived. The lapsed and expiring lists were
  /// captured empty, so if a field you need is missing above, read it from
  /// here and then add it properly rather than guessing at a getter.
  final Map<String, dynamic> raw;

  factory TradeLicence.fromJson(Map<String, dynamic> json) => TradeLicence(
    id: Json.integer(json['id']),
    licenceNo: Json.string(json['licence_no']),
    verificationCode: Json.string(json['verification_code']),
    holderName: Json.string(
      Json.pick(json, <String>['holder_name', 'applicant_name', 'name']),
    ),
    fatherName: Json.string(json['father_name']),
    cnic: Json.string(json['cnic']),
    mobileNo: Json.string(json['mobile_no']),
    businessName: Json.string(json['business_name']),
    shopAddress: Json.string(json['shop_address']),
    trade: Json.string(
      Json.pick(json, <String>['trade', 'category_name', 'trade_category']),
    ),
    areaName: Json.string(json['area_name']),
    zoneName: Json.string(json['zone_name']),
    status: Json.string(json['status']),
    issuedOn: Json.dateTime(json['issued_on']),
    validFrom: Json.dateTime(json['valid_from']),
    validTo: Json.dateTime(json['valid_to']),
    daysRemaining: Json.integer(json['days_remaining']),
    isValid: Json.booleanOr(json['is_valid']),
    mapPin: GeoPoint.maybe(json['map_pin']),
    raw: json,
  );

  /// Ran out and was not renewed.
  bool get hasLapsed => !isValid && validTo != null;
}

/// The answer to the doorway question: is this shop licensed?
///
/// Deliberately not area-scoped — a licence issued in the next bazaar is still
/// valid. Read [hasValidLicence], never [found] alone: found-and-lapsed and
/// never-licensed are different conversations to have with a shopkeeper.
class TradeLicenceLookup {
  const TradeLicenceLookup({
    this.searched,
    this.found = false,
    this.hasValidLicence = false,
    this.licences = const <TradeLicence>[],
  });

  /// What was searched for, echoed back — a CNIC, a mobile, a licence number
  /// or a verification code.
  final String? searched;

  /// Whether the register holds anything at all against [searched].
  final bool found;

  /// Whether any of [licences] is live today.
  final bool hasValidLicence;

  final List<TradeLicence> licences;

  factory TradeLicenceLookup.fromJson(Map<String, dynamic> json) =>
      TradeLicenceLookup(
        searched: Json.string(json['searched']),
        found: Json.booleanOr(json['found']),
        hasValidLicence: Json.booleanOr(json['has_valid_licence']),
        licences: Json.list(
          json['licences'],
        ).map(TradeLicence.fromJson).toList(),
      );

  /// On the register, but nothing live — the shopkeeper needs to renew, not to
  /// apply.
  bool get isLapsed => found && !hasValidLicence;

  /// Nothing on the register at all. This is the one that becomes a field
  /// capture.
  bool get isUnlicensed => !found;

  /// The live licence to show, when there is one.
  TradeLicence? get liveLicence {
    for (final licence in licences) {
      if (licence.isValid) return licence;
    }
    return null;
  }
}
