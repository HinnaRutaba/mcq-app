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

  /// Cool, restrained tones for the acts chart: navy, steel blue, teal, slate.
  static const List<Color> _actionLight = <Color>[
    Color(0xFF2E4A86),
    Color(0xFF4A7FB0),
    Color(0xFF12A08A),
    Color(0xFF6B7A8A),
  ];
  static const List<Color> _actionDark = <Color>[
    Color(0xFF5A74B0),
    Color(0xFF6A9AC6),
    Color(0xFF1E9A85),
    Color(0xFF8B98A6),
  ];

  /// Fixed slot per act; the acts one role takes never share a slot
  /// (CMO: endorsed/returned/responded/dispatched, Admin: approved/returned/rejected).
  static const Map<String, int> _actions = <String, int>{
    'endorsed': 0,
    'approved': 0,
    'taxation_forwarded': 0,
    'returned': 1,
    'responded': 2,
    'dispatched': 3,
    'rejected': 3,
    'execution_forwarded': 3,
  };

  /// Faded so the columns read soft rather than loud.
  static Color action(BuildContext context, String key) {
    final List<Color> tones = Theme.of(context).brightness == Brightness.dark
        ? _actionDark
        : _actionLight;
    final int? i = _actions[key];
    final Color base = i == null ? AppSeriesColors.other(context) : tones[i];
    return base.withValues(alpha: 0.55);
  }

  /// Listed statuses first, the neutral rest after, so the grey is one arc.
  static int statusOrder(String key) {
    final int i = _statuses.indexOf(key);
    return i == -1 ? _statuses.length : i;
  }
}
