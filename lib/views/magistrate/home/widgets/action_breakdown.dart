import 'package:flutter/material.dart';

import '../../../../config/theme/app_series_colors.dart';
import '../../../../widgets/widgets.dart';

/// What the officer's visits actually were, as an escalation ladder.
///
/// Ordered by how far each step goes rather than by how many there were. Read
/// down the card and it is a funnel: a lot of visits, fewer notices, fewer
/// warnings, a handful of fines, the occasional seal. That shape is the thing
/// worth seeing — a sort by count would scatter the ladder and lose it.
///
/// So the ladder is carried by the order, and the colour is free to carry
/// volume: the busiest step is solid, the quietest is faint, on the one brand
/// hue. That deliberately says the same thing the bar's length says. It is
/// redundant on purpose — a glance down the card finds the heavy rows without
/// reading a single number, and the number is still on every row for when the
/// glance is not enough.
///
/// Not a categorical palette. These steps have an order and a size; giving
/// each its own unrelated hue would say they are merely different when what
/// matters is that one is more serious, and one is busier, than the next.
class ActionBreakdown extends StatelessWidget {
  const ActionBreakdown({super.key, required this.byActionType});

  final Map<String, int> byActionType;

  /// The ladder, mildest first. Server-defined keys; anything not on it is a
  /// step this build has not been told about and goes last.
  static const List<String> _ladder = <String>[
    'site_visit',
    'notice_served',
    'verbal_warning',
    'final_warning',
    'fine_imposed',
    'shop_sealed',
    'seal_released',
  ];

  @override
  Widget build(BuildContext context) {
    if (byActionType.isEmpty) return const SizedBox.shrink();

    final entries = byActionType.entries.toList()
      ..sort(
        (MapEntry<String, int> a, MapEntry<String, int> b) =>
            _rung(a.key).compareTo(_rung(b.key)),
      );

    // Weighted against the busiest step in this card, not against a fixed
    // ceiling — a quiet month should still read as a ladder, not as five
    // barely-there rows.
    final busiest = entries.fold<int>(
      0,
      (int most, MapEntry<String, int> e) => e.value > most ? e.value : most,
    );

    return AppCard(
      child: AppBarList(
        // The ladder's order is the point; sorting by count would undo it.
        sorted: false,
        data: <BarDatum>[
          for (final MapEntry<String, int> entry in entries)
            BarDatum(
              label: _label(entry.key),
              value: entry.value.toDouble(),
              valueLabel: '${entry.value}',
              color: AppSeriesColors.magnitude(
                context,
                busiest == 0 ? 1 : entry.value / busiest,
              ),
            ),
        ],
      ),
    );
  }

  /// Where a step sits on the ladder. Unknown keys sort to the end rather than
  /// being dropped — a new action type the server adds still shows.
  static int _rung(String key) {
    final index = _ladder.indexOf(key);
    return index == -1 ? _ladder.length : index;
  }

  static String _label(String key) => switch (key) {
    'site_visit' => 'Site visits',
    'notice_served' => 'Notices served',
    'verbal_warning' => 'Verbal warnings',
    'final_warning' => 'Final warnings',
    'fine_imposed' => 'Fines imposed',
    'shop_sealed' => 'Shops sealed',
    'seal_released' => 'Seals released',
    _ => _humanise(key),
  };

  static String _humanise(String key) {
    if (key.isEmpty) return 'Other';
    final words = key.replaceAll('_', ' ').trim();
    return words[0].toUpperCase() + words.substring(1);
  }
}
