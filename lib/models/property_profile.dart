import '../core/utils/json_parse.dart';
import 'api_refs.dart';
import 'challan.dart';

/// The full profile of one unit: the holder, the money position, the seal and
/// any open case.
///
/// Opened from a card, so the header can be drawn from the card already in hand
/// and this call only enriches it.
class PropertyProfile {
  const PropertyProfile({
    required this.property,
    this.allotment,
    this.allottee,
    required this.position,
    required this.enforcement,
    this.challans = const <Challan>[],
    this.payments = const <Map<String, dynamic>>[],
    this.arrearsPlan,
  });

  final ProfileProperty property;

  /// Both null on a vacant unit.
  final AllotmentRef? allotment;
  final AllotteeRef? allottee;

  final PropertyPosition position;
  final PropertyEnforcement enforcement;

  final List<Challan> challans;

  /// Payment history. Held as the raw payload: the published spec only ever
  /// captured this empty, so the row shape is not pinned down — model it
  /// properly once a populated response is available.
  final List<Map<String, dynamic>> payments;

  /// An agreed instalment plan, when one exists. Raw for the same reason as
  /// [payments].
  final Map<String, dynamic>? arrearsPlan;

  factory PropertyProfile.fromJson(Map<String, dynamic> json) =>
      PropertyProfile(
        property: ProfileProperty.fromJson(Json.map(json['property'])),
        allotment: AllotmentRef.maybe(json['allotment']),
        allottee: AllotteeRef.maybe(json['allottee']),
        position: PropertyPosition.fromJson(Json.map(json['position'])),
        enforcement: PropertyEnforcement.fromJson(
          Json.map(json['enforcement']),
        ),
        challans: Json.list(json['challans']).map(Challan.fromJson).toList(),
        payments: Json.list(json['payments']),
        arrearsPlan: Json.mapOrNull(json['arrears_plan']),
      );

  bool get isVacant => allotment == null;
}

class ProfileProperty {
  const ProfileProperty({
    this.id,
    this.propertyCode,
    this.categoryName,
    this.zoneName,
    this.areaName,
    this.marketName,
    this.shopNo,
    this.streetAddress,
    this.latitude,
    this.longitude,
    this.hasCoordinates = false,
    this.occupancyStatus,
    this.physicalStatus,
    this.register949Ref,
  });

  final int? id;
  final String? propertyCode;

  /// e.g. "Shop", "Kiosk / Cabin".
  final String? categoryName;

  final String? zoneName;
  final String? areaName;
  final String? marketName;
  final String? shopNo;

  /// Ready to print, e.g. "Shop S-8, Liaquat Bazaar, Jinnah Road, Quetta".
  final String? streetAddress;

  final String? latitude;
  final String? longitude;
  final bool hasCoordinates;

  /// e.g. `allotted`, `vacant`.
  final String? occupancyStatus;

  /// e.g. `open`, `closed`. A plain string here, unlike the labelled object a
  /// case's property carries.
  final String? physicalStatus;

  /// The unit's entry in the corporation's Register 949.
  final String? register949Ref;

  factory ProfileProperty.fromJson(Map<String, dynamic> json) =>
      ProfileProperty(
        id: Json.integer(json['id']),
        propertyCode: Json.string(json['property_code']),
        categoryName: Json.string(json['category_name']),
        zoneName: Json.string(json['zone_name']),
        areaName: Json.string(json['area_name']),
        marketName: Json.string(json['market_name']),
        shopNo: Json.string(json['shop_no']),
        streetAddress: Json.string(json['street_address']),
        latitude: Json.string(json['latitude']),
        longitude: Json.string(json['longitude']),
        hasCoordinates: Json.booleanOr(json['has_coordinates']),
        occupancyStatus: Json.string(json['occupancy_status']),
        physicalStatus: Json.string(json['physical_status']),
        register949Ref: Json.string(json['register_949_ref']),
      );

  GeoPoint get location => GeoPoint(latitude: latitude, longitude: longitude);
}

/// Where the unit stands on money. Every figure is a string.
class PropertyPosition {
  const PropertyPosition({
    this.currentDue,
    this.arrearsDue,
    this.surchargeDue,
    this.totalOutstanding,
    this.totalCollected,
    this.lastPaymentDate,
    this.unpaidMonths = 0,
  });

  /// This period's rent.
  final String? currentDue;

  /// Everything older.
  final String? arrearsDue;

  final String? surchargeDue;

  /// The server's own total of the rent side. Use this rather than adding the
  /// three above together, and never fold a fine into it.
  final String? totalOutstanding;

  /// Everything ever paid on the unit.
  final String? totalCollected;

  final DateTime? lastPaymentDate;
  final int unpaidMonths;

  factory PropertyPosition.fromJson(Map<String, dynamic> json) =>
      PropertyPosition(
        currentDue: Json.money(json['current_due']),
        arrearsDue: Json.money(json['arrears_due']),
        surchargeDue: Json.money(json['surcharge_due']),
        totalOutstanding: Json.money(json['total_outstanding']),
        totalCollected: Json.money(json['total_collected']),
        lastPaymentDate: Json.dateTime(json['last_payment_date']),
        unpaidMonths: Json.integerOr(json['unpaid_months']),
      );

  bool get hasEverPaid => lastPaymentDate != null;
}

/// The enforcement standing of the unit: seal, case, legal proceedings.
class PropertyEnforcement {
  const PropertyEnforcement({
    this.sealNo,
    this.sealedOn,
    this.sealStatus,
    this.isSealed = false,
    this.openCaseNo,
    this.caseStatus,
    this.openLegalCases = 0,
  });

  final String? sealNo;
  final DateTime? sealedOn;

  /// Null when the unit has never been sealed.
  final String? sealStatus;

  final bool isSealed;
  final String? openCaseNo;
  final String? caseStatus;

  /// Matters before a court, as opposed to the corporation's own case.
  final int openLegalCases;

  factory PropertyEnforcement.fromJson(Map<String, dynamic> json) =>
      PropertyEnforcement(
        sealNo: Json.string(json['seal_no']),
        sealedOn: Json.dateTime(json['sealed_on']),
        sealStatus: Json.string(json['seal_status']),
        isSealed: Json.booleanOr(json['is_sealed']),
        openCaseNo: Json.string(json['open_case_no']),
        caseStatus: Json.string(json['case_status']),
        openLegalCases: Json.integerOr(json['open_legal_cases']),
      );

  bool get hasOpenCase => openCaseNo != null;
}
