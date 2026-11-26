import 'package:flutter/material.dart';

import '../../../../config/theme/app_series_colors.dart';

/// Chart colours for statuses, fixed per key so a slice keeps its
/// colour when the period changes. Anything unlisted folds into the neutral.
class IntakeSeries {
  IntakeSeries._();

  /// Workflow order, so the ring reads round as the case travels.
  static const List<String> _statuses = <String>[
    'pending_taxation',
    'pending_cmo',
    'pending_admin',
    'pending_dispatch',
    'activated',
  ];

  static Color status(BuildContext context, String key) =>
      AppSeriesColors.at(context, _statuses.indexOf(key));

  /// Listed statuses first, the neutral rest after, so the grey is one arc.
  static int statusOrder(String key) {
    final int i = _statuses.indexOf(key);
    return i == -1 ? _statuses.length : i;
  }
}
