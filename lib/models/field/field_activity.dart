import '../../core/utils/json_reader.dart';
import '../common/money.dart';

/// `GET /enforcement/field/activity?days=30` — "my work".
///
/// There was no way for a field officer to see his own work, and that is a
/// real gap rather than a nicety. Recovery is slow, unglamorous and mostly
/// invisible; an officer who cannot see that thirty visits sat behind four
/// hundred thousand rupees has no reason to believe the visits matter.
class FieldActivity {
  const FieldActivity({
    required this.periodDays,
    required this.visits,
    required this.byActionType,
    required this.finesImposed,
    required this.shopsSealed,
    required this.sealsReleased,
    required this.receiptsInAreas,
    this.since,
    this.finesAmount,
    this.collectedInAreas,
  });

  final int periodDays;
  final DateTime? since;

  final int visits;

  /// `{ site_visit: 21, verbal_warning: 6, … }` — the bar chart.
  final Map<String, int> byActionType;

  final int finesImposed;
  final Money? finesAmount;

  final int shopsSealed;
  final int sealsReleased;

  /// **Label this exactly as the server does: "Collected in your areas".**
  /// Never "You recovered". A payment cannot honestly be attributed to a
  /// visit — the shopkeeper may have paid because of an SMS, a neighbour,
  /// or the end of the month. Overclaiming here is how an officer stops
  /// trusting every other figure in the app.
  final Money? collectedInAreas;

  final int receiptsInAreas;

  static const FieldActivity empty = FieldActivity(
    periodDays: 30,
    visits: 0,
    byActionType: {},
    finesImposed: 0,
    shopsSealed: 0,
    sealsReleased: 0,
    receiptsInAreas: 0,
  );

  factory FieldActivity.fromJson(Map<String, dynamic> json) {
    final breakdown = <String, int>{};
    final raw = json.child('by_action_type');
    raw?.forEach((key, value) {
      final count = value is int ? value : int.tryParse('$value');
      if (count != null) breakdown[key] = count;
    });

    return FieldActivity(
      periodDays: json.intOr('period_days', 30),
      since: json.date('since'),
      visits: json.intOr('visits'),
      byActionType: breakdown,
      finesImposed: json.intOr('fines_imposed'),
      finesAmount: json.moneyOrNull('fines_amount'),
      shopsSealed: json.intOr('shops_sealed'),
      sealsReleased: json.intOr('seals_released'),
      collectedInAreas: json.moneyOrNull('collected_in_your_areas'),
      receiptsInAreas: json.intOr('receipts_in_your_areas'),
    );
  }

  bool get isEmpty =>
      visits == 0 &&
      finesImposed == 0 &&
      shopsSealed == 0 &&
      sealsReleased == 0;

  /// The breakdown, largest first, for the bar chart.
  List<MapEntry<String, int>> get breakdown {
    final entries = byActionType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// The tallest bar, so the chart scales to the data rather than to a
  /// round number that leaves everything short.
  int get busiest =>
      byActionType.values.fold<int>(0, (max, v) => v > max ? v : max);

  /// The periods the report offers.
  static const List<int> periods = [7, 30, 90];
}
