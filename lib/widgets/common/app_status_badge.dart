import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../text/app_text.dart';
import '../../config/theme/app_radius.dart';

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppTone.neutral,
    this.icon,
    this.brightness,
    this.filled = false,
    this.count,
    this.minWidth = 48,
    this.minHeight = 26,
  });

  final String label;
  final AppTone tone;

  /// The brightness to resolve [tone] against, for a pill drawn on a plate
  /// whose colour does not follow the theme — the brand's filled plate is a
  /// light tint in both. Null follows the theme, which is almost always right.
  final Brightness? brightness;

  /// A glyph before the label — a second reading of the state, never the only
  /// one: the pill is always labelled.
  final IconData? icon;

  /// Solid tone with its own ink — for a count beside a heading, which has
  /// to read as a figure rather than as a state.
  final bool filled;

  /// A figure after the label, in its own light disc — "All ⑦".
  final int? count;

  /// Floor on the pill's size, so a one-word label isn't a sliver; 26 is the
  /// natural height of a caption pill, so rows of badges stay level.
  final double minWidth;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final Brightness? on = brightness;
    final Color toneColor = on == null ? tone.on(context) : tone.resolve(on);
    final Color color = filled ? tone.onFilled(context) : toneColor;
    final Widget text = AppText.caption(
      label,
      color: color,
      fontWeight: FontWeight.w700,
    );

    final int? figure = count;
    final Widget? disc = figure == null
        ? null
        : Container(
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Light in both themes, so the figure reads as a disc on the pill.
              color: filled
                  ? Color.lerp(toneColor, Colors.white, 0.82)
                  : toneColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: AppText.caption(
              '$figure',
              color: filled
                  ? Color.lerp(toneColor, Colors.black, 0.45)
                  : toneColor,
              fontWeight: FontWeight.w800,
            ),
          );

    return Container(
      constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
      padding: EdgeInsets.fromLTRB(
        icon == null ? 10 : 8,
        disc == null ? 5 : 3,
        disc == null ? 10 : 3,
        disc == null ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: filled
            ? toneColor
            : on == null
            ? tone.container(context)
            : tone.containerIn(on),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      // Factors of 1 keep the pill hugging its content above the minimum,
      // while centring a short label inside it.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: icon == null && disc == null
            ? text
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 13, color: color),
                    const SizedBox(width: 5),
                  ],
                  // Flexible, because a row hands a child unbounded width and a
                  // long label would run off the pill instead of wrapping.
                  Flexible(child: text),
                  if (disc != null) ...<Widget>[const SizedBox(width: 6), disc],
                ],
              ),
      ),
    );
  }
}
