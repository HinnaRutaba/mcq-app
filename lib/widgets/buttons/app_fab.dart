import 'package:flutter/material.dart';

import '../text/app_text.dart';
import '../../config/theme/app_radius.dart';

/// A round action button carrying an icon over a short label, filled with a
/// gradient of [color].
///
/// Built by hand rather than as a [FloatingActionButton] because a FAB takes
/// a flat `backgroundColor` and cannot be given a gradient. The shape is
/// Material 3's rounded square; [AppBottomNavBar] cuts a notch of the same
/// shape, so pass it [cornerRadius] to keep the two in step.
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.foregroundColor,
    this.onTap,
    this.size = 56,
    this.cornerRadius = defaultCornerRadius,
  });

  /// Material 3's own FAB radius, so the button reads as one.
  static const double defaultCornerRadius = AppRadius.lg;

  final IconData icon;

  /// One word. It shares a 56pt circle with the icon, so anything longer is
  /// wider than the chord it sits on.
  final String label;

  /// The middle of the gradient — the two stops are derived from it, so a
  /// caller passes the accent it already has rather than a matched pair.
  final Color color;

  final Color foregroundColor;
  final VoidCallback? onTap;
  final double size;
  final double cornerRadius;

  /// How far either end of the gradient travels from [color]. Kept small on
  /// purpose: the ink a caller picked is legible against [color], and a stop
  /// that runs much lighter or darker than that stops being a safe bet.
  static const double _spread = 0.14;

  @override
  Widget build(BuildContext context) {
    final BorderRadius corners = BorderRadius.circular(cornerRadius);

    return Tooltip(
      message: label,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          borderRadius: corners,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.lerp(color, Colors.white, _spread)!,
              Color.lerp(color, Colors.black, _spread)!,
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: corners,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: corners,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: foregroundColor, size: size * 0.36),
                AppText.caption(
                  label,
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
