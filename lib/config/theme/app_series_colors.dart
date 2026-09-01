import 'package:flutter/material.dart';

/// Colours for chart series — and nothing else.
///
/// Kept apart from both the brand and the status palette on purpose. The
/// status hues (red, amber, emerald, information blue) are reserved: a chart
/// segment must never be the same red as an overdue account. The brand moves
/// when the officer picks a scheme, and a bazaar's colour changing because
/// somebody preferred Teal would be worse than no colour at all.
///
/// So these five are their own set, stepped for each brightness and validated
/// as a set rather than eyeballed. On the adjacent pairs a stacked bar and a
/// ranked list actually put side by side, the worst separation is ΔE 8.9
/// (light) / 8.2 (dark) under simulated colour-vision deficiency, against a
/// target of 8; worst normal-vision separation ΔE 19.3 / 16.8 against a floor
/// of 15; every slot clears 3:1 against its surface. **Re-run the validator
/// before changing any of these hexes** — the order is part of what passed.
///
/// Five, and then [other]. A sixth bazaar does not get an invented hue; it
/// folds into the neutral, which is the honest way to say "and the rest".
class AppSeriesColors {
  AppSeriesColors._();

  static const List<Color> _light = <Color>[
    Color(0xFF6A4FD4), // violet
    Color(0xFF12A08A), // teal
    Color(0xFFB4632A), // clay
    Color(0xFFA8479E), // magenta
    Color(0xFF2F6FD0), // blue
  ];

  static const List<Color> _dark = <Color>[
    Color(0xFF7E68D6),
    Color(0xFF1E9A85),
    Color(0xFFB8703C),
    Color(0xFFB65AA2),
    Color(0xFF4A85CE),
  ];

  /// How many entities can carry their own colour before the rest fold into
  /// [other].
  static int get slots => _light.length;

  static List<Color> of(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  /// The colour for slot [index]. Assigned by **entity**, never by rank: a
  /// bazaar keeps its hue when the list reorders, which is the whole reason
  /// the same colour can be trusted across two charts.
  ///
  /// Past the last slot, the neutral — never a generated hue.
  static Color at(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colors = of(theme.brightness);
    if (index < 0 || index >= colors.length) return other(context);
    return colors[index];
  }

  /// "And the rest": the sixth bazaar onward, and anything unrecognised.
  static Color other(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  /// A single-hue step for a **magnitude**: the bigger the value, the more
  /// solid the fill. [fraction] is the value against the largest in the same
  /// chart, 0 to 1.
  ///
  /// The hue is the theme's brand colour, so it re-steps with the officer's
  /// chosen scheme, and only its weight moves. One hue light-to-dark is what a
  /// magnitude is allowed to look like; a rainbow across the same bars would
  /// claim the rows were different kinds of thing rather than different sizes
  /// of one.
  ///
  /// Floored at [_faintest] rather than run to nothing: the smallest row still
  /// has to be visible, and a bar that fades out is a row the officer will
  /// skip. It is never the only reading either — every row prints its count.
  static Color magnitude(BuildContext context, double fraction) {
    final hue = Theme.of(context).colorScheme.primary;
    final t = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 1.0;
    return hue.withValues(alpha: _faintest + (1 - _faintest) * t);
  }

  /// The weakest a bar is allowed to get.
  static const double _faintest = 0.34;
}
