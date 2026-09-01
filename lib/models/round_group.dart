import '../core/utils/json_parse.dart';
import 'defaulter_card.dart';

/// Today's round, one entry per bazaar: the same defaulters as the flat list,
/// grouped by market with broken promises first and a handful of stops each.
class RoundGroup {
  const RoundGroup({
    this.marketName,
    this.areaName,
    this.areaId,
    this.shops = 0,
    this.brokenPromises = 0,
    this.neverPaid = 0,
    this.sealed = 0,
    required this.outstanding,
    this.stops = const <DefaulterCard>[],
  });

  final String? marketName;
  final String? areaName;
  final int? areaId;

  /// How many units in this market are behind — not how many [stops] the
  /// server picked out.
  final int shops;

  /// Promised to pay and did not. The reason this group sorts where it does.
  final int brokenPromises;

  final int neverPaid;
  final int sealed;

  /// Total owed across the market, as a string.
  final String outstanding;

  /// The stops the server suggests making here, worst first.
  final List<DefaulterCard> stops;

  factory RoundGroup.fromJson(Map<String, dynamic> json) => RoundGroup(
    marketName: Json.string(json['market_name']),
    areaName: Json.string(json['area_name']),
    areaId: Json.integer(json['area_id']),
    shops: Json.integerOr(json['shops']),
    brokenPromises: Json.integerOr(json['broken_promises']),
    neverPaid: Json.integerOr(json['never_paid']),
    sealed: Json.integerOr(json['sealed']),
    outstanding: Json.moneyOr(json['outstanding']),
    stops: Json.list(json['stops']).map(DefaulterCard.fromJson).toList(),
  );
}
