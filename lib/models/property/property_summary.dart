import '../../core/utils/json_reader.dart';
import '../common/api_enum.dart';
import '../common/can_flags.dart';
import '../common/entity_refs.dart';
import '../common/money.dart';

/// One revenue-earning unit — shop, stall, kiosk, cycle stand, parking
/// stand, public washroom, plaza unit.
class PropertySummary {
  const PropertySummary({
    required this.id,
    required this.propertyCode,
    required this.shopNo,
    required this.areaName,
    required this.category,
    required this.status,
    required this.flags,
    this.marketName,
    this.monthlyRent,
    this.allottee = AllotteeRef.none,
    this.allotment = AllotmentRef.none,
    this.isSealed = false,
  });

  final int id;
  final String propertyCode;
  final String shopNo;
  final String areaName;
  final ApiEnum category;
  final ApiEnum status;
  final CanFlags flags;
  final String? marketName;
  final Money? monthlyRent;
  final AllotteeRef allottee;
  final AllotmentRef allotment;
  final bool isSealed;

  factory PropertySummary.fromJson(Map<String, dynamic> json) {
    final allotment = AllotmentRef.fromJson(
      json.child('allotment') ?? json.child('current_allotment'),
    );
    return PropertySummary(
      id: json.intOr('id'),
      propertyCode: json.strOr('property_code'),
      shopNo: json.strOr('shop_no'),
      areaName: json.str('area_name') ?? json.child('area')?.strOr('name') ?? '',
      category: json.apiEnum('category'),
      status: json.apiEnum('status'),
      flags: CanFlags.fromJson(json),
      marketName:
          json.str('market_name') ?? json.child('market')?.str('name'),
      monthlyRent: json.moneyOrNull('monthly_rent') ?? allotment.monthlyRent,
      allottee: AllotteeRef.fromJson(json.child('allottee')),
      allotment: allotment,
      isSealed: json.boolean('sealed') || json.boolean('is_sealed'),
    );
  }

  String get label => shopNo.isNotEmpty ? shopNo : propertyCode;

  /// Whether anybody holds the unit. The fine form asks for the offender's
  /// name and mobile number the moment this is false, because the server
  /// refuses a fine on an unlet unit with nobody named.
  bool get hasLiveAllotment => allotment.isLive || allottee.exists;

  PropertyRef get ref => PropertyRef(
        id: id,
        propertyCode: propertyCode,
        shopNo: shopNo,
        areaName: areaName,
        marketName: marketName,
        category: category,
      );
}

/// `GET /reporting/properties/{property}/profile` — the richest single call
/// for a "what am I standing in front of" screen: property, allotment,
/// allottee, balance and history in one response. Prefer it over three
/// round trips on a mobile connection.
///
/// The documents do not pin every member of this payload down, so anything
/// not modelled is kept in [extra] rather than dropped — regenerate the
/// typed fields from a real response before release.
class PropertyProfile {
  const PropertyProfile({
    required this.property,
    required this.balances,
    required this.extra,
    this.liveStayOrder = false,
  });

  final PropertySummary property;

  /// Every amount on the profile, keyed exactly as the server sent it.
  /// Displayed as-is; nothing here is ever added up.
  final Map<String, Money> balances;

  final Map<String, dynamic> extra;

  /// A live stay order stops enforcement. If a property shows one, the app
  /// must not offer to seal it — the server will refuse, but the officer
  /// should not be walking to the shop in the first place.
  final bool liveStayOrder;

  factory PropertyProfile.fromJson(Map<String, dynamic> json) {
    final propertyJson = json.child('property') ?? json;
    final balanceJson =
        json.child('balance') ?? json.child('balances') ?? const {};
    final legal = json.child('legal') ?? json.child('legal_case');
    return PropertyProfile(
      property: PropertySummary.fromJson({
        ...propertyJson,
        if (json.child('allottee') != null) 'allottee': json.child('allottee'),
        if (json.child('allotment') != null)
          'allotment': json.child('allotment'),
      }),
      balances: balanceJson.moneyMap(),
      extra: json,
      liveStayOrder: json.boolean('has_live_stay') ||
          json.boolean('stay_order_active') ||
          (legal?.boolean('has_live_stay') ?? false),
    );
  }

  Money? balance(String key) => balances[key];

  Money? get outstanding =>
      balances['outstanding'] ?? balances['owed'] ?? balances['balance'];
}
