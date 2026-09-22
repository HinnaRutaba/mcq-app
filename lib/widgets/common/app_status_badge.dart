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

  @override
  Widget build(BuildContext context) {
    final Brightness? on = brightness;
    final color = on == null ? tone.on(context) : tone.resolve(on);
    final Widget text = AppText.caption(
      label,
      color: color,
      fontWeight: FontWeight.w700,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 10 : 8, 5, 10, 5),
      decoration: BoxDecoration(
        color: on == null ? tone.container(context) : tone.containerIn(on),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: icon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                // Flexible, because a row hands a child unbounded width and a
                // long label would run off the pill instead of wrapping.
                Flexible(child: text),
              ],
            ),
    );
  }
}
