import '../../core/utils/json_reader.dart';
import '../common/money.dart';
import 'field_card.dart';

/// `GET /enforcement/field/round` — today's round, grouped by market.
///
/// The officer is going to the bazaar anyway. The expensive part of his day
/// is deciding which shops to call on once he is standing there, and this
/// answers it: his defaulters grouped by market and ordered by what is
/// worth walking to.
///
/// **Ordered by broken promises first, then by count** — the server does
/// this and the app does not re-sort it. A lapsed commitment beats a larger
/// balance nobody has spoken to yet: somebody has already been given a
/// chance and has not taken it, and that is what justifies the next step.
class RoundMarket {
  const RoundMarket({
    required this.marketName,
    required this.areaName,
    required this.shops,
    required this.brokenPromises,
    required this.neverPaid,
    required this.sealed,
    required this.stops,
    this.areaId,
    this.outstanding,
  });

  final String marketName;
  final String areaName;
  final int? areaId;

  final int shops;
  final int brokenPromises;
  final int neverPaid;
  final int sealed;

  /// The market's total, from the server. Never summed from [stops].
  final Money? outstanding;

  /// **At most five, on purpose.** A round nobody can finish is a list
  /// nobody reads.
  final List<FieldCard> stops;

  factory RoundMarket.fromJson(Map<String, dynamic> json) => RoundMarket(
        marketName: json.strOr('market_name'),
        areaName: json.strOr('area_name'),
        areaId: json.integer('area_id'),
        shops: json.intOr('shops'),
        brokenPromises: json.intOr('broken_promises'),
        neverPaid: json.intOr('never_paid'),
        sealed: json.intOr('sealed'),
        outstanding: json.moneyOrNull('outstanding'),
        stops: json.children('stops').map(FieldCard.fromJson).toList(),
      );

  static List<RoundMarket> listFrom(List<dynamic> raw) => raw
      .whereType<Map<String, dynamic>>()
      .map(RoundMarket.fromJson)
      .toList(growable: false);

  /// `Liaquat Market, Circular Road`.
  String get placeLabel =>
      areaName.isEmpty ? marketName : '$marketName, $areaName';

  bool get hasStops => stops.isNotEmpty;
}
