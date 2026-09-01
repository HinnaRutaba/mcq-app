import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A tap target that answers the finger.
///
/// Two things every important control in this app does and a bare
/// [InkWell] does not: it *shrinks* under the thumb, which reads as
/// physical on a phone held at arm's length in sunlight where an ink
/// ripple is nearly invisible; and it can fire haptic feedback, so a
/// decision is felt as well as seen.
///
/// [haptic] is deliberately off by default. Sealing a shop should feel
/// like a decision; scrolling past a card should not.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.haptic = false,
    this.scale = 0.975,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool haptic;
  final double scale;
  final BorderRadius? borderRadius;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _down = false;

  void _set(bool down) {
    if (widget.onTap == null || _down == down) return;
    setState(() => _down = down);
  }

  void _fire() {
    if (widget.onTap == null) return;
    if (widget.haptic) HapticFeedback.mediumImpact();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap == null ? null : _fire,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// The haptics vocabulary, in one place so the app is consistent about
/// what a phone is allowed to say.
class AppHaptics {
  AppHaptics._();

  /// A decision with a consequence — sealing, fining, releasing.
  static void decision() => HapticFeedback.heavyImpact();

  /// Something completed and went to the server.
  static void success() => HapticFeedback.mediumImpact();

  /// A refusal, a validation failure, a lost signal.
  static void refused() => HapticFeedback.vibrate();

  /// A selection changed — a filter chip, a date option.
  static void select() => HapticFeedback.selectionClick();
}
