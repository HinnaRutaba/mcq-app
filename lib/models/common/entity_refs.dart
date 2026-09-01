import '../../core/utils/json_reader.dart';
import 'api_enum.dart';
import 'money.dart';

/// The `property` block that rides along on a case, a seal and a fine.
///
/// The vocabulary is fixed: a **property** is one revenue-earning unit and
/// has a `property_code` and usually a shop number. Do not rename it to a
/// generic software term in the UI.
class PropertyRef {
  const PropertyRef({
    required this.id,
    required this.propertyCode,
    required this.shopNo,
    required this.areaName,
    this.marketName,
    this.category = ApiEnum.unknown,
  });

  final int id;
  final String propertyCode;
  final String shopNo;
  final String areaName;
  final String? marketName;
  final ApiEnum category;

  static const PropertyRef unknown = PropertyRef(
    id: 0,
    propertyCode: '',
    shopNo: '',
    areaName: '',
  );

  factory PropertyRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return unknown;
    return PropertyRef(
      id: json.intOr('id'),
      propertyCode: json.strOr('property_code'),
      shopNo: json.strOr('shop_no'),
      areaName: json.strOr('area_name'),
      marketName: json.str('market_name'),
      category: json.apiEnum('category'),
    );
  }

  /// What the officer reads on a confirmation dialog: the shop number if
  /// there is one, otherwise the property code.
  String get label => shopNo.isNotEmpty ? shopNo : propertyCode;
}

/// The agreement between MCQ and an allottee for one unit.
class AllotmentRef {
  const AllotmentRef({
    required this.id,
    this.allotmentNo,
    this.monthlyRent,
    this.status = ApiEnum.unknown,
  });

  final int id;
  final String? allotmentNo;
  final Money? monthlyRent;
  final ApiEnum status;

  static const AllotmentRef none = AllotmentRef(id: 0);

  factory AllotmentRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return none;
    return AllotmentRef(
      id: json.intOr('id'),
      allotmentNo: json.str('allotment_no'),
      monthlyRent: json.moneyOrNull('monthly_rent'),
      status: json.apiEnum('status'),
    );
  }

  /// Whether anybody currently holds the unit. Drives the fine form: with
  /// no live agreement the officer must name the offender, because a fine
  /// nobody can be asked to pay is refused by the database itself.
  bool get isLive => id != 0;
}

/// The citizen holding a unit. A shopkeeper. Not a "customer" or "tenant".
class AllotteeRef {
  const AllotteeRef({required this.id, required this.name, this.mobileNo});

  final int id;
  final String name;
  final String? mobileNo;

  static const AllotteeRef none = AllotteeRef(id: 0, name: '');

  factory AllotteeRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return none;
    return AllotteeRef(
      id: json.intOr('id'),
      name: json.str('name') ?? json.strOr('allottee_name'),
      mobileNo: json.str('mobile_no'),
    );
  }

  bool get exists => id != 0 || name.isNotEmpty;
  bool get isCallable => (mobileNo ?? '').trim().isNotEmpty;
}
