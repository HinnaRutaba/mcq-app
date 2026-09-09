import 'package:flutter/material.dart';

import '../text/app_text.dart';
import '../../config/theme/app_radius.dart';

class AppExtendedFab extends StatefulWidget {
  const AppExtendedFab({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.foregroundColor,
    this.onTap,
    this.height = 44,
  });

  final IconData icon;

  final String label;

  final Color color;

  final Color foregroundColor;
  final VoidCallback? onTap;
  final double height;

  static const double _spread = 0.14;

  static const double _pressedScale = 0.92;

  static const Duration _down = Duration(milliseconds: 110);
  static const Duration _up = Duration(milliseconds: 260);

  static const Duration _hold = Duration(milliseconds: 130);

  @override
  State<AppExtendedFab> createState() => _AppExtendedFabState();
}

class _AppExtendedFabState extends State<AppExtendedFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: AppExtendedFab._down,
    reverseDuration: AppExtendedFab._up,
  );

  /// `easeOutBack` on the way back overshoots 1, so the button pops a shade
  /// past its size before settling — the difference between a button that
  /// releases and one that merely stops being pressed.
  late final Animation<double> _scale =
      Tween<double>(begin: 1, end: AppExtendedFab._pressedScale).animate(
        CurvedAnimation(
          parent: _press,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeOutBack.flipped,
        ),
      );

  /// A tap already waiting out [AppExtendedFab._hold]. A second press on top
  /// of it is dropped: the wait is what a double tap would otherwise open two
  /// of.
  bool _waiting = false;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final VoidCallback? onTap = widget.onTap;
    if (onTap == null || _waiting) return;

    // Read before the wait, not after it: an officer who has asked for no
    // animations has nothing to be shown and should not be made to wait.
    if (MediaQuery.disableAnimationsOf(context)) {
      onTap();
      return;
    }

    _waiting = true;
    await Future<void>.delayed(AppExtendedFab._hold);
    _waiting = false;
    if (!mounted) return;
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius corners = BorderRadius.circular(AppRadius.pill);

    return ScaleTransition(
      scale: _scale,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: corners,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.lerp(widget.color, Colors.white, AppExtendedFab._spread)!,
              Color.lerp(widget.color, Colors.black, AppExtendedFab._spread)!,
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
            onTap: widget.onTap == null ? null : _handleTap,
            // The highlight is the press: it goes true on tap-down and false
            // on release or cancel, so a drag off the button springs it back.
            onHighlightChanged: (bool down) =>
                down ? _press.forward() : _press.reverse(),
            borderRadius: corners,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(widget.icon, color: widget.foregroundColor, size: 18),
                  const SizedBox(width: 8),
                  AppText.label(
                    widget.label,
                    color: widget.foregroundColor,
                    fontWeight: FontWeight.w800,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
