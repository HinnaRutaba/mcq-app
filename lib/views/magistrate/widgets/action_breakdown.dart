import 'package:flutter/material.dart';

import '../../../widgets/widgets.dart';

/// What the officer's visits actually were, action type by action type.
///
/// Bars are proportional to the largest count rather than to a total, because
/// the counts are not parts of one whole — a single visit can serve a notice
/// and impose a fine, so they would not add up to anything meaningful.
///
/// Keys are server-defined and new ones can appear without an app release, so
/// an unknown key is spelled out rather than dropped.
class ActionBreakdown extends StatelessWidget {
  const ActionBreakdown({super.key, required this.byActionType});

  final Map<String, int> byActionType;

  @override
  Widget build(BuildContext context) {
    if (byActionType.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: AppBarList(
        data: <BarDatum>[
          for (final MapEntry<String, int> entry in byActionType.entries)
            BarDatum(
              label: _label(entry.key),
              value: entry.value.toDouble(),
              valueLabel: '${entry.value}',
            ),
        ],
      ),
    );
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
