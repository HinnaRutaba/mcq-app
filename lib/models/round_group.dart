import '../core/utils/json_parse.dart';
import 'defaulter_card.dart';

/// Today's round, one entry per bazaar: the same defaulters as the flat list,
/// grouped by market with broken promises first and a handful of stops each.
class RoundGroup {
  RoundGroup({
    this.marketName,
    this.areaName,
    this.areaId,
    this.shops = 0,
    this.brokenPromises = 0,
    this.neverPaid = 0,
    this.sealed = 0,
    required this.outstanding,
    this.stops = const <DefaulterCard>[],
    int? shortlisted,
  }) : shortlisted = shortlisted ?? stops.length;

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

  /// How many stops the server picked out — [stops] as it arrived. Kept apart
  /// because a search narrows [stops] and does not change what the server
  /// shortlisted, and the head says which of the two figures it is quoting.
  final int shortlisted;

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

  /// Distinct per market: two markets can share a bazaar, so the bazaar alone
  /// would collide. What a folded market and a section's element are keyed by.
  String get key => '${areaId ?? 0}-${marketName ?? areaName ?? ''}';

  /// The same market carrying [stops] instead — how a search narrows a group
  /// to the shops it matched without touching what the market owes.
  RoundGroup withStops(List<DefaulterCard> stops) => RoundGroup(
    marketName: marketName,
    areaName: areaName,
    areaId: areaId,
    shops: shops,
    brokenPromises: brokenPromises,
    neverPaid: neverPaid,
    sealed: sealed,
    outstanding: outstanding,
    stops: stops,
    shortlisted: shortlisted,
  );
}
