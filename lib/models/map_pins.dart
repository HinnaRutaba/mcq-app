import '../core/utils/json_parse.dart';

/// Map pins for the officer's bazaars, with the server's own count of how many
/// units it could not place.
class MapPins {
  const MapPins({this.pins = const <MapPin>[], this.meta = const MapPinsMeta()});

  final List<MapPin> pins;
  final MapPinsMeta meta;

  factory MapPins.fromJson(Map<String, dynamic> json) => MapPins(
    pins: Json.list(json['pins']).map(MapPin.fromJson).toList(),
    meta: MapPinsMeta.fromJson(Json.map(json['meta'])),
  );
}

class MapPin {
  const MapPin({
    this.propertyId,
    this.propertyCode,
    this.shopNo,
    this.latitude,
    this.longitude,
    this.categoryName,
    this.areaName,
    this.marketName,
    this.occupancyStatus,
    this.physicalStatus,
    required this.outstanding,
    this.unpaidMonths = 0,
    this.sealed = false,
    this.severity,
  });

  final int? propertyId;
  final String? propertyCode;
  final String? shopNo;

  /// Sent as `lat` / `lng`; kept as strings exactly as received.
  final String? latitude;
  final String? longitude;

  /// e.g. "Shop", "Kiosk / Cabin", "Stall / Khokha", "Building / Plaza Unit".
  final String? categoryName;

  final String? areaName;
  final String? marketName;

  /// e.g. `allotted`, `vacant`.
  final String? occupancyStatus;

  /// e.g. `open`, `closed`.
  final String? physicalStatus;

  /// Owed on the unit, as a string.
  final String outstanding;

  final int unpaidMonths;
  final bool sealed;

  /// How the server wants the pin coloured, e.g. `owing`.
  final String? severity;

  factory MapPin.fromJson(Map<String, dynamic> json) => MapPin(
    propertyId: Json.integer(json['property_id']),
    propertyCode: Json.string(json['property_code']),
    shopNo: Json.string(json['shop_no']),
    latitude: Json.string(Json.pick(json, <String>['lat', 'latitude'])),
    longitude: Json.string(Json.pick(json, <String>['lng', 'longitude'])),
    categoryName: Json.string(json['category_name']),
    areaName: Json.string(json['area_name']),
    marketName: Json.string(json['market_name']),
    occupancyStatus: Json.string(json['occupancy_status']),
    physicalStatus: Json.string(json['physical_status']),
    outstanding: Json.moneyOr(json['outstanding']),
    unpaidMonths: Json.integerOr(json['unpaid_months']),
    sealed: Json.booleanOr(json['sealed']),
    severity: Json.string(json['severity']),
  );

  double? get latitudeValue => Json.decimal(latitude);
  double? get longitudeValue => Json.decimal(longitude);

  bool get hasFix => latitudeValue != null && longitudeValue != null;
}

class MapPinsMeta {
  const MapPinsMeta({
    this.returned = 0,
    this.total = 0,
    this.truncated = false,
    this.limit = 0,
    this.unmapped = 0,
  });

  final int returned;
  final int total;

  /// True when [limit] cut the list short — say so rather than letting the map
  /// imply it is showing everything.
  final bool truncated;

  final int limit;

  /// Units in scope that have no coordinates and so cannot be pinned.
  final int unmapped;

  factory MapPinsMeta.fromJson(Map<String, dynamic> json) => MapPinsMeta(
    returned: Json.integerOr(json['returned']),
    total: Json.integerOr(json['total']),
    truncated: Json.booleanOr(json['truncated']),
    limit: Json.integerOr(json['limit']),
    unmapped: Json.integerOr(json['unmapped']),
  );
}
