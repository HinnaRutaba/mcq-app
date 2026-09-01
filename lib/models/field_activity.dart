import '../core/utils/json_parse.dart';

/// The officer's own work over a window of days.
///
/// Label the money exactly as the server names it: [collectedInYourAreas] is
/// what came in across their bazaars, which is not the same claim as "you
/// recovered this". A magistrate's visit is one reason a shopkeeper pays; the
/// figure is not a personal total.
class FieldActivity {
  const FieldActivity({
    required this.periodDays,
    this.since,
    this.visits = 0,
    this.byActionType = const <String, int>{},
    this.finesImposed = 0,
    this.finesAmount,
    this.shopsSealed = 0,
    this.sealsReleased = 0,
    this.collectedInYourAreas,
    this.receiptsInYourAreas = 0,
  });

  final int periodDays;

  /// The first day counted.
  final DateTime? since;

  final int visits;

  /// Action type -> how many. Keys are server-defined (`site_visit`,
  /// `notice_served`, `verbal_warning`, `final_warning`, `fine_imposed`, …)
  /// and new ones can appear without an app release.
  final Map<String, int> byActionType;

  final int finesImposed;

  /// Total fines imposed, as a string.
  final String? finesAmount;

  final int shopsSealed;
  final int sealsReleased;

  /// Collected across the officer's bazaars in the period. Show it under the
  /// server's own wording.
  final String? collectedInYourAreas;

  final int receiptsInYourAreas;

  factory FieldActivity.fromJson(Map<String, dynamic> json) => FieldActivity(
    periodDays: Json.integerOr(json['period_days'], 30),
    since: Json.dateTime(json['since']),
    visits: Json.integerOr(json['visits']),
    byActionType: Json.counts(json['by_action_type']),
    finesImposed: Json.integerOr(json['fines_imposed']),
    finesAmount: Json.money(json['fines_amount']),
    shopsSealed: Json.integerOr(json['shops_sealed']),
    sealsReleased: Json.integerOr(json['seals_released']),
    collectedInYourAreas: Json.money(json['collected_in_your_areas']),
    receiptsInYourAreas: Json.integerOr(json['receipts_in_your_areas']),
  );
}
