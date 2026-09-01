import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_status_colors.dart';
import '../motion/app_pressable.dart';
import '../text/app_text.dart';

/// Visual styles [AppButton] supports, each mapping to a **real Material 3
/// button** rather than to a hand-painted container.
///
/// The mapping is the point. `FilledButton` already knows about focus
/// rings, disabled states, ink, keyboard traversal, semantics and the
/// platform's own accessibility scaling; a `Container` with a
/// `GestureDetector` on it knows none of that and has to be taught each one
/// by hand, badly, once per app.
enum AppButtonVariant {
  /// `FilledButton` in the corporation's green. One per screen — the thing
  /// the officer came to do.
  primary,

  /// `FilledButton` in warm gold. **Always dark text**; white on gold fails
  /// contrast outdoors at these sizes, and the rule is enforced here rather
  /// than left to each caller to remember.
  accent,

  /// Historic alias for [accent].
  secondary,

  /// `FilledButton.tonal` — a real second-rank action. Present enough to
  /// find, quiet enough not to compete with the primary.
  tonal,

  /// `OutlinedButton`.
  outline,

  /// `TextButton`.
  ghost,

  /// `FilledButton` in the danger red — sealing, cancelling, refusing.
  danger,
}

/// The single button widget every screen uses.
///
/// It exists to enforce three rules, not to re-paint Material:
///
/// 1. **Never white on gold.** [AppButtonVariant.accent] picks its own
///    foreground and ignores anything a caller might prefer.
/// 2. **A minimum height of 52.** This is tapped by somebody standing on a
///    footpath, holding a phone in one hand, in the sun.
/// 3. **A press the thumb can feel.** The button shrinks under the finger —
///    an ink ripple is close to invisible on a cheap screen in daylight —
///    and a [destructive] one fires a heavier haptic, because sealing a
///    shop should feel like a decision.
///
/// Everything else — colour, radius, typography, disabled treatment — comes
/// from the theme's button themes, so a screen can also use a bare
/// `FilledButton` and match.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.height = 52,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final double height;

  /// Fires a decision-weight haptic on tap.
  final bool destructive;

  bool get _disabled => onPressed == null || isLoading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  /// The button's own state set, so the shrink is driven by Material's
  /// notion of "pressed" rather than by a second gesture recogniser
  /// competing with it.
  final WidgetStatesController _states = WidgetStatesController();
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(_onStates);
  }

  void _onStates() {
    final pressed = _states.value.contains(WidgetState.pressed);
    if (pressed != _pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  void dispose() {
    _states
      ..removeListener(_onStates)
      ..dispose();
    super.dispose();
  }

  void _fire() {
    if (widget.destructive) {
      AppHaptics.decision();
    } else {
      AppHaptics.select();
    }
    widget.onPressed!.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = context.status;

    // The one place that decides what gold, danger and tonal look like on
    // a button, in both brightnesses.
    final (Color? background, Color? foreground) = switch (widget.variant) {
      AppButtonVariant.primary => (scheme.primary, scheme.onPrimary),
      AppButtonVariant.accent ||
      AppButtonVariant.secondary =>
        (status.accent, status.onAccent),
      AppButtonVariant.danger => (status.danger, status.onDanger),
      AppButtonVariant.tonal => (null, null),
      AppButtonVariant.outline => (null, null),
      AppButtonVariant.ghost => (null, null),
    };

    final resolvedForeground = foreground ??
        switch (widget.variant) {
          AppButtonVariant.tonal => scheme.onSecondaryContainer,
          _ => scheme.primary,
        };

    final child = widget.isLoading
        ? SizedBox(
            height: 21,
            width: 21,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: resolvedForeground,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: AppText(
                  widget.label,
                  variant: AppTextVariant.labelLarge,
                  color: resolvedForeground,
                  maxLines: 1,
                ),
              ),
            ],
          );

    final onPressed = widget._disabled ? null : _fire;
    final size = Size(widget.fullWidth ? double.infinity : 64, widget.height);

    final Widget button = switch (widget.variant) {
      AppButtonVariant.outline => OutlinedButton(
          onPressed: onPressed,
          statesController: _states,
          style: OutlinedButton.styleFrom(minimumSize: size),
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: onPressed,
          statesController: _states,
          style: TextButton.styleFrom(minimumSize: size),
          child: child,
        ),
      AppButtonVariant.tonal => FilledButton.tonal(
          onPressed: onPressed,
          statesController: _states,
          style: FilledButton.styleFrom(minimumSize: size),
          child: child,
        ),
      _ => FilledButton(
          onPressed: onPressed,
          statesController: _states,
          style: FilledButton.styleFrom(
            minimumSize: size,
            backgroundColor: background,
            foregroundColor: resolvedForeground,
            // Depth on the one button a screen actually wants tapped —
            // and none at all on a disabled one, which should look inert.
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: child,
        ),
    };

    final sized = SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      height: widget.height,
      child: button,
    );

    // A coloured glow under the filled variants, so the primary action on
    // a screen sits above the card behind it rather than on it.
    final lifted = background == null ||
            widget._disabled ||
            Theme.of(context).brightness == Brightness.dark
        ? sized
        : DecoratedBox(
            position: DecorationPosition.background,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: background.withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: sized,
          );

    return AnimatedScale(
      scale: _pressed ? 0.965 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: lifted,
    );
  }
}

/// The gold call-to-action as a bare, circular icon button — a call, a
/// direction, a share — for rows too tight for a labelled button.
///
/// Icon-only is allowed **here and only here**: these sit beside a card
/// that already names the shop, and every one carries a tooltip and a
/// semantic label so a screen reader and a long-press both say what it
/// does.
class AppIconAction extends StatelessWidget {
  const AppIconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tone = AppTone.success,
    this.size = 46,
  });

  final IconData icon;

  /// Spoken by the screen reader and shown on long-press. Required — an
  /// unlabelled glyph is a guess.
  final String label;

  final VoidCallback? onPressed;
  final AppTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colour = tone.on(context);
    return Tooltip(
      message: label,
      child: SizedBox(
        width: size,
        height: size,
        child: IconButton.filledTonal(
          onPressed: onPressed == null
              ? null
              : () {
                  AppHaptics.select();
                  onPressed!();
                },
          tooltip: null,
          icon: Icon(icon, size: size * 0.46),
          style: IconButton.styleFrom(
            backgroundColor: tone.container(context),
            foregroundColor: colour,
            side: BorderSide(color: colour.withValues(alpha: 0.30)),
            shape: const CircleBorder(),
          ),
        ),
      ),
    );
  }
}
