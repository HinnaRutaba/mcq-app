import '../core/utils/json_parse.dart';
import 'api_refs.dart';
import 'field_beat.dart';

/// Every trade with its price in one bazaar, grouped for a picker.
///
/// Cache it — MCQ reprices a zone a few times a year, not a few times a day.
/// An unpriced trade comes back with a null [TradeCategory.annualFee] and is
/// counted in [unpriced]; never render that as `0.00`, and do not let it be
/// picked as though it were free.
class TradeTariff {
  const TradeTariff({
    this.area,
    this.zone,
    this.areas = const <FieldArea>[],
    this.terms = const TradeTerms(),
    this.groups = const <TradeCategoryGroup>[],
    this.priced = 0,
    this.unpriced = 0,
    this.generatedAt,
  });

  /// The bazaar these prices are for.
  final FieldArea? area;

  /// The zone the price actually hangs off — MCQ prices a trade per zone, and
  /// [area] inherits it.
  final TradeZone? zone;

  /// The bazaars this officer may quote for, for a picker that lets them
  /// switch. The same list the enforcement beat sends.
  final List<FieldArea> areas;

  /// How long a licence may be taken for.
  final TradeTerms terms;

  final List<TradeCategoryGroup> groups;

  /// The server's own tally of how many trades carry a price in this zone.
  final int priced;

  /// How many do not. When this is above zero, some rows in [groups] cannot be
  /// quoted and the picker has to say so rather than show a blank fee.
  final int unpriced;

  final DateTime? generatedAt;

  factory TradeTariff.fromJson(Map<String, dynamic> json) => TradeTariff(
    area: json['area'] is Map
        ? FieldArea.fromJson(Json.map(json['area']))
        : null,
    zone: TradeZone.maybe(json['zone']),
    areas: Json.list(json['areas']).map(FieldArea.fromJson).toList(),
    terms: TradeTerms.fromJson(Json.map(json['terms'])),
    groups: Json.list(json['groups']).map(TradeCategoryGroup.fromJson).toList(),
    priced: Json.integerOr(json['priced']),
    unpriced: Json.integerOr(json['unpriced']),
    generatedAt: Json.dateTime(json['generated_at']),
  );

  /// Every category across every group, flattened — for a search box over the
  /// picker rather than the grouped list itself.
  List<TradeCategory> get categories => <TradeCategory>[
    for (final group in groups) ...group.categories,
  ];

  /// The category with this id, for turning a stored `trade_category_id` back
  /// into something printable.
  TradeCategory? category(int id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  bool get hasUnpriced => unpriced > 0;
}

/// A zone — the level MCQ actually sets a trade's price at.
class TradeZone {
  const TradeZone({this.id, this.zoneCode, this.zoneName});

  final int? id;

  /// e.g. `Z1`.
  final String? zoneCode;

  /// e.g. "Zone 1 - Zarghoon".
  final String? zoneName;

  factory TradeZone.fromJson(Map<String, dynamic> json) => TradeZone(
    id: Json.integer(json['id']),
    zoneCode: Json.string(json['zone_code']),
    zoneName: Json.string(json['zone_name']),
  );

  static TradeZone? maybe(Object? source) =>
      source is Map ? TradeZone.fromJson(Json.map(source)) : null;
}

/// How many years a licence may be taken for. Bound the years field to these
/// rather than to a constant of your own.
class TradeTerms {
  const TradeTerms({this.minYears = 1, this.maxYears = 10});

  final int minYears;
  final int maxYears;

  factory TradeTerms.fromJson(Map<String, dynamic> json) => TradeTerms(
    minYears: Json.integerOr(json['min_years'], 1),
    maxYears: Json.integerOr(json['max_years'], 10),
  );

  bool allows(int years) => years >= minYears && years <= maxYears;
}

/// One heading in the trade picker, e.g. "Food and hospitality".
class TradeCategoryGroup {
  const TradeCategoryGroup({
    this.group,
    this.categories = const <TradeCategory>[],
  });

  /// Labelled and toned by the server, like every other vocabulary.
  final LabelledValue? group;

  final List<TradeCategory> categories;

  factory TradeCategoryGroup.fromJson(Map<String, dynamic> json) =>
      TradeCategoryGroup(
        group: LabelledValue.maybe(json['group']),
        categories: Json.list(
          json['categories'],
        ).map(TradeCategory.fromJson).toList(),
      );

  /// What to print as the heading.
  String get label => group?.label ?? 'Other';
}

/// One trade, at this zone's price.
class TradeCategory {
  const TradeCategory({
    this.id,
    this.categoryCode,
    required this.categoryName,
    this.categoryNameUr,
    this.annualFee,
    this.isPriced = false,
  });

  /// What to send as `trade_category_id`.
  final int? id;

  /// e.g. `NAAN_SHOP`.
  final String? categoryCode;

  /// e.g. "Naan Shop / Tandoor".
  final String categoryName;

  /// The Urdu wording, for an officer whose `locale` is `ur`.
  final String? categoryNameUr;

  /// The yearly fee as a string, or null when MCQ has not priced this trade in
  /// this zone. Null is not zero — show "not priced" and do not offer it.
  final String? annualFee;

  /// The server's own answer to whether [annualFee] can be quoted.
  final bool isPriced;

  factory TradeCategory.fromJson(Map<String, dynamic> json) => TradeCategory(
    id: Json.integer(json['id']),
    categoryCode: Json.string(json['category_code']),
    categoryName: Json.stringOr(
      json['category_name'],
      Json.stringOr(json['category_code']),
    ),
    // The published document renders this key both ways round; read both.
    categoryNameUr: Json.string(
      Json.pick(json, <String>['category_name_ur', 'ur_name_category']),
    ),
    annualFee: Json.money(json['annual_fee']),
    isPriced: Json.booleanOr(json['is_priced']),
  );

  /// Whether this trade can be captured in the field at all. A trade with no
  /// price cannot raise a challan, so the picker must not offer it.
  bool get canQuote => isPriced && annualFee != null;
}
