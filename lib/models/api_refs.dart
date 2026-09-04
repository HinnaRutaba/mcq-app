import '../core/utils/json_parse.dart';

class LabelledValue {
  const LabelledValue({required this.value, required this.label, this.tone});

  /// The machine value, e.g. `warned`, `site_visit`, `fine`.
  final String value;

  /// What to show the officer, e.g. "Notice handed over".
  final String label;

  /// `danger` | `warning` | `info` | `neutral` | `primary`, as the server sends
  /// it. Map it to a colour at the edge of the UI.
  final String? tone;

  factory LabelledValue.fromJson(Map<String, dynamic> json) {
    final value = Json.stringOr(json['value']);
    return LabelledValue(
      value: value,
      label: Json.stringOr(json['label'], value),
      tone: Json.string(json['tone']),
    );
  }

  /// Accepts either the full object or a bare string — some endpoints send
  /// `"seal_status": "applied"` where others send a labelled object.
  static LabelledValue? maybe(Object? source) {
    if (source is Map) return LabelledValue.fromJson(Json.map(source));
    final value = Json.string(source);
    return value == null ? null : LabelledValue(value: value, label: value);
  }
}

/// A staff member: the magistrate on a case, whoever performed an action,
/// whoever imposed a fine.
class UserRef {
  const UserRef({this.id, required this.name});

  final int? id;
  final String name;

  factory UserRef.fromJson(Map<String, dynamic> json) =>
      UserRef(id: Json.integer(json['id']), name: Json.stringOr(json['name']));

  static UserRef? maybe(Object? source) =>
      source is Map ? UserRef.fromJson(Json.map(source)) : null;
}

/// A unit, as referenced from a case, a fine or a challan.
class PropertyRef {
  const PropertyRef({
    this.id,
    this.propertyCode,
    this.displayName,
    this.physicalStatus,
    this.location,
  });

  final int? id;
  final String? propertyCode;

  /// e.g. "Shop S-19, Liaquat Bazaar" — already assembled by the server.
  final String? displayName;

  /// Present on a case's property, absent on a challan's.
  final LabelledValue? physicalStatus;

  /// Where the unit stands, when the reference carries a fix.
  ///
  /// Read from a nested block or from the reference itself, because the
  /// endpoints that do send coordinates disagree on where to put them —
  /// `billing/challans` sends none at all today, and this is null there until
  /// it does. [GeoPoint.maybe] answers null unless there is a real fix, so
  /// every one of these lookups is safe to try.
  final GeoPoint? location;

  factory PropertyRef.fromJson(Map<String, dynamic> json) => PropertyRef(
    id: Json.integer(json['id']),
    propertyCode: Json.string(json['property_code']),
    displayName: Json.string(json['display_name']),
    physicalStatus: LabelledValue.maybe(json['physical_status']),
    location:
        GeoPoint.maybe(json['location']) ??
        GeoPoint.maybe(json['map']) ??
        GeoPoint.maybe(json),
  );

  static PropertyRef? maybe(Object? source) =>
      source is Map ? PropertyRef.fromJson(Json.map(source)) : null;
}

/// The tenancy a unit is held under. Null wherever nobody holds the unit.
class AllotmentRef {
  const AllotmentRef({this.id, this.allotmentNo, this.allotmentType});

  final int? id;
  final String? allotmentNo;

  /// Rent or lease — the terms the unit is held on, which is where that
  /// distinction actually lives. A challan's own `challan_type` is about what
  /// the bill covers (`combined`, `fine`), not how the shop is held.
  final LabelledValue? allotmentType;

  factory AllotmentRef.fromJson(Map<String, dynamic> json) => AllotmentRef(
    id: Json.integer(json['id']),
    allotmentNo: Json.string(json['allotment_no']),
    allotmentType: LabelledValue.maybe(json['allotment_type']),
  );

  static AllotmentRef? maybe(Object? source) =>
      source is Map ? AllotmentRef.fromJson(Json.map(source)) : null;
}

/// The person holding the tenancy. Null on a vacant unit, and on a fine
/// raised against somebody who is not on the register.
///
/// Spelled `full_name` where a case or a challan references the holder and
/// `name` on the person lookup, which also carries [fatherName] and [status];
/// both are read here so one class serves every place a holder appears.
class AllotteeRef {
  const AllotteeRef({
    this.id,
    this.allotteeCode,
    this.fullName,
    this.fatherName,
    this.mobileNo,
    this.cnic,
    this.status,
  });

  final int? id;
  final String? allotteeCode;
  final String? fullName;

  /// Present on the person lookup. Null wherever the holder is referenced from
  /// a case, a challan or a profile.
  final String? fatherName;

  final String? mobileNo;
  final String? cnic;

  /// e.g. `active`. Present on the person lookup only.
  final String? status;

  factory AllotteeRef.fromJson(Map<String, dynamic> json) => AllotteeRef(
    id: Json.integer(json['id']),
    allotteeCode: Json.string(json['allottee_code']),
    fullName: Json.string(Json.pick(json, <String>['full_name', 'name'])),
    fatherName: Json.string(json['father_name']),
    mobileNo: Json.string(json['mobile_no']),
    cnic: Json.string(json['cnic']),
    status: Json.string(json['status']),
  );

  static AllotteeRef? maybe(Object? source) =>
      source is Map ? AllotteeRef.fromJson(Json.map(source)) : null;
}

/// Somebody a case or a fine names who is not on the property register — a
/// hawker, a handcart, whoever is trading out of a unit MCQ has not let.
///
/// A case carries one of these when it is about conduct rather than arrears;
/// see `EnforcementCase.isConductCase`. The published spec only ever captured
/// it null, so the keys are read leniently and the untouched payload is kept in
/// [raw] — read a missing field from there and then add it properly rather than
/// guessing at a getter.
class OffenderRef {
  const OffenderRef({
    this.id,
    this.name,
    this.fatherName,
    this.mobileNo,
    this.cnic,
    this.business,
    this.address,
    this.raw = const <String, dynamic>{},
  });

  final int? id;
  final String? name;
  final String? fatherName;
  final String? mobileNo;
  final String? cnic;

  /// What they trade as, e.g. "Fruit stall, handcart".
  final String? business;

  /// Where they were found.
  final String? address;

  final Map<String, dynamic> raw;

  factory OffenderRef.fromJson(Map<String, dynamic> json) => OffenderRef(
    id: Json.integer(json['id']),
    name: Json.string(
      Json.pick(json, <String>['name', 'full_name', 'offender_name']),
    ),
    fatherName: Json.string(
      Json.pick(json, <String>['father_name', 'offender_father_name']),
    ),
    mobileNo: Json.string(
      Json.pick(json, <String>['mobile_no', 'offender_mobile_no']),
    ),
    cnic: Json.string(Json.pick(json, <String>['cnic', 'offender_cnic'])),
    business: Json.string(
      Json.pick(json, <String>['business', 'offender_business']),
    ),
    address: Json.string(
      Json.pick(json, <String>['address', 'offender_address']),
    ),
    raw: json,
  );

  static OffenderRef? maybe(Object? source) =>
      source is Map ? OffenderRef.fromJson(Json.map(source)) : null;
}

/// A bazaar. Spelled `area_code`/`area_name` on an enforcement case and
/// `code`/`name` on a challan; both read the same here.
class AreaRef {
  const AreaRef({this.id, this.code, this.name});

  final int? id;
  final String? code;
  final String? name;

  factory AreaRef.fromJson(Map<String, dynamic> json) => AreaRef(
    id: Json.integer(json['id']),
    code: Json.string(Json.pick(json, <String>['area_code', 'code'])),
    name: Json.string(Json.pick(json, <String>['area_name', 'name'])),
  );

  static AreaRef? maybe(Object? source) =>
      source is Map ? AreaRef.fromJson(Json.map(source)) : null;
}

/// The enforcement case a fine was raised under, when there is one.
class EnforcementCaseRef {
  const EnforcementCaseRef({this.id, this.caseNo});

  final int? id;
  final String? caseNo;

  factory EnforcementCaseRef.fromJson(Map<String, dynamic> json) =>
      EnforcementCaseRef(
        id: Json.integer(json['id']),
        caseNo: Json.string(json['case_no']),
      );

  static EnforcementCaseRef? maybe(Object? source) =>
      source is Map ? EnforcementCaseRef.fromJson(Json.map(source)) : null;
}

class GeoPoint {
  const GeoPoint({this.latitude, this.longitude});

  final String? latitude;
  final String? longitude;

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
    latitude: Json.string(Json.pick(json, <String>['latitude', 'lat'])),
    longitude: Json.string(Json.pick(json, <String>['longitude', 'lng'])),
  );

  static GeoPoint? maybe(Object? source) {
    if (source is! Map) return null;
    final point = GeoPoint.fromJson(Json.map(source));
    return point.hasFix ? point : null;
  }

  double? get latitudeValue => Json.decimal(latitude);
  double? get longitudeValue => Json.decimal(longitude);

  bool get hasFix => latitudeValue != null && longitudeValue != null;
}
