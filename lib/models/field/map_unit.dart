import '../../core/utils/json_reader.dart';
import '../common/money.dart';
import 'field_card.dart';

/// What a pin on the map is doing there.
enum MapUnitState { owing, sealed, current, vacant }

/// One pin from `GET /reporting/map`.
///
/// A unit with no coordinates simply does not appear. That is a fact the
/// map has to **say** — "12 shops have no location recorded" — rather than
/// silently omit, because a bazaar that looks empty on the map is not the
/// same as a bazaar with nothing in it.
class MapUnit {
  const MapUnit({
    required this.propertyId,
    required this.propertyCode,
    required this.shopNo,
    required this.areaName,
    required this.point,
    required this.state,
    this.marketName,
    this.allotteeName,
    this.mobileNo,
    this.outstanding,
    this.sealNo,
  });

  final int propertyId;
  final String propertyCode;
  final String shopNo;
  final String areaName;
  final String? marketName;
  final String? allotteeName;
  final String? mobileNo;
  final Money? outstanding;
  final String? sealNo;
  final MapPoint point;
  final MapUnitState state;

  /// Returns null when the unit has no usable coordinate — the caller
  /// counts those and prints the footnote.
  static MapUnit? fromJson(Map<String, dynamic> json) {
    final point = MapPoint.fromJson(json.child('map')) ??
        MapPoint.fromJson(json);
    if (point == null) return null;

    final sealed = json.boolean('is_sealed');
    final vacant = json.boolean('is_vacant');
    final owed = json.moneyOrNull('outstanding');

    return MapUnit(
      propertyId: json.intOr('property_id') ,
      propertyCode: json.strOr('property_code'),
      shopNo: json.strOr('shop_no'),
      areaName: json.strOr('area_name'),
      marketName: json.str('market_name'),
      allotteeName: json.str('allottee_name'),
      mobileNo: json.str('mobile_no'),
      outstanding: owed,
      sealNo: json.str('seal_no'),
      point: point,
      state: sealed
          ? MapUnitState.sealed
          : vacant
              ? MapUnitState.vacant
              : (owed != null && !owed.isZero)
                  ? MapUnitState.owing
                  : MapUnitState.current,
    );
  }

  String get unitLabel =>
      shopNo.isEmpty ? propertyCode : '$propertyCode · $shopNo';
}

/// The map's answer: the pins it can draw, and how many it could not.
class MapUnits {
  const MapUnits({required this.units, required this.withoutLocation});

  final List<MapUnit> units;

  /// Counted, and printed as a footnote. Never silently dropped.
  final int withoutLocation;

  static const MapUnits empty = MapUnits(units: [], withoutLocation: 0);

  factory MapUnits.fromList(List<dynamic> raw) {
    final rows = raw.whereType<Map<String, dynamic>>().toList();
    final units = <MapUnit>[];
    var missing = 0;
    for (final row in rows) {
      final unit = MapUnit.fromJson(row);
      if (unit == null) {
        missing++;
      } else {
        units.add(unit);
      }
    }
    return MapUnits(units: units, withoutLocation: missing);
  }
}
