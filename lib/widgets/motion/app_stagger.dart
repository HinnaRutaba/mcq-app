import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Cards animate in with a stagger — the one motion that makes a list feel
/// built rather than dumped.
///
/// **Fast, and never in the officer's way.** 280ms per item and a 45ms step
/// between them, capped so the tenth card is not still waiting while
/// somebody argues at the officer's elbow. Animation that delays the work
/// is a failure, not a polish.
///
/// The entrance runs once, on first build. A refresh must not replay it:
/// re-animating rows the officer is already reading is how a list becomes
/// unusable on a bad connection. That is what [enabled] is for, and every
/// list in this app passes its controller's `isFirstLoad`.
class AppStaggerIn extends StatelessWidget {
  const AppStaggerIn({
    super.key,
    required this.index,
    required this.child,
    this.enabled = true,
  });

  final int index;
  final Widget child;

  /// False replays nothing — used when rows arrive from a refresh rather
  /// than a first load.
  final bool enabled;

  /// The cap. Beyond the tenth card the delay stops growing.
  static const int maxSteps = 10;
  static const Duration step = Duration(milliseconds: 45);
  static const Duration duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final delay = step * index.clamp(0, maxSteps);
    return Animate(
      effects: [
        FadeEffect(delay: delay, duration: duration, curve: Curves.easeOut),
        // Six logical pixels of rise, not thirty. The card should look
        // like it settled, not like it flew in from off-screen.
        MoveEffect(
          delay: delay,
          duration: duration,
          begin: const Offset(0, 14),
          end: Offset.zero,
          curve: Curves.easeOutCubic,
        ),
      ],
      child: child,
    );
  }
}

/// The same entrance for a whole column, so a screen does not have to
/// count indices itself.
class AppStaggerColumn extends StatelessWidget {
  const AppStaggerColumn({
    super.key,
    required this.children,
    this.spacing = 12,
    this.enabled = true,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final double spacing;
  final bool enabled;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          AppStaggerIn(index: i, enabled: enabled, child: children[i]),
        ],
      ],
    );
  }
}

/// A single element that fades and rises into place with no stagger — for
/// a panel, a banner, a headline figure appearing on its own.
class AppFadeIn extends StatelessWidget {
  const AppFadeIn({
    super.key,
    required this.child,
    this.enabled = true,
    this.delay = Duration.zero,
  });

  final Widget child;
  final bool enabled;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Animate(
      effects: [
        FadeEffect(
          delay: delay,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        ),
        MoveEffect(
          delay: delay,
          duration: const Duration(milliseconds: 260),
          begin: const Offset(0, 10),
          end: Offset.zero,
          curve: Curves.easeOutCubic,
        ),
      ],
      child: child,
    );
  }
}

/// One slow, shallow breath, repeating — for the single card on a list
/// whose commitment lapses today.
///
/// It is deliberately the only repeating animation in the app. A second
/// one competing with it would make both invisible.
class AppAttentionPulse extends StatelessWidget {
  const AppAttentionPulse({
    super.key,
    required this.child,
    required this.colour,
    this.enabled = true,
    this.radius = 18,
  });

  final Widget child;
  final Color colour;
  final bool enabled;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Animate(
      onPlay: (controller) => controller.repeat(reverse: true),
      effects: [
        CustomEffect(
          duration: const Duration(milliseconds: 1800),
          curve: Curves.easeInOut,
          builder: (context, value, child) => DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: colour.withValues(alpha: 0.05 + 0.17 * value),
                  blurRadius: 14 + 12 * value,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ],
      child: child,
    );
  }
}
