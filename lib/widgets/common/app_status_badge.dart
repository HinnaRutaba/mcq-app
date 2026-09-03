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
  });

  final String label;
  final AppTone tone;

  /// A glyph before the label — a second reading of the state, never the only
  /// one: the pill is always labelled.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = tone.on(context);
    final Widget text = AppText.caption(
      label,
      color: color,
      fontWeight: FontWeight.w700,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 10 : 8, 5, 10, 5),
      decoration: BoxDecoration(
        color: tone.container(context),
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
