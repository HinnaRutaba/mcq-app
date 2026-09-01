import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_theme.dart';
import '../motion/app_pressable.dart';

/// The single card container every list item and grouped block uses.
///
/// It is a real Material [Card] with a real [InkWell] in it, so a tap gets
/// ink, a focus ring, keyboard traversal and a `button` semantic without
/// any of that having to be re-implemented; the theme's `cardTheme` gives
/// it its surface, radius, border and elevation, so a bare `Card` on a
/// screen matches this one.
///
/// **Depth, not flatness.** Elevation and a soft shadow in light mode, so
/// cards sit *on* the background rather than being drawn onto it — the
/// whole complaint about the previous build was that every row looked like
/// the row above it. In dark mode a shadow does nothing, so the card lifts
/// a surface step instead.
///
/// [rail] draws a coloured accent down the card's **leading** edge — start
/// in English, end in Urdu, because it is `EdgeInsetsDirectional` all the
/// way down. That rail is how a card says "overdue" or "ready to unseal"
/// before the officer has read a word of it, and it is always paired with
/// a pill that says the same thing in words.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.tone,
    this.rail = false,
    this.elevated = true,
    this.haptic = false,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;

  /// Tints the surface and colours the rail. Null is an ordinary card.
  final AppTone? tone;

  /// Draw the tone as an accent rail down the leading edge.
  final bool rail;

  final bool elevated;

  /// True on a card whose tap is a decision rather than navigation.
  final bool haptic;

  /// Draws the brand ring — for a card that is currently chosen.
  final bool selected;

  static const double radius = AppShape.card;
  static const double _railWidth = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);
    final accent = tone?.on(context);

    final base = theme.cardTheme.color ?? theme.colorScheme.surface;
    final surface = accent == null
        ? base
        : Color.alphaBlend(
            accent.withValues(alpha: dark ? 0.10 : 0.055),
            base,
          );

    final borderColour = selected
        ? theme.colorScheme.primary
        : accent == null
            ? theme.dividerColor
            : accent.withValues(alpha: dark ? 0.34 : 0.24);

    final content = Stack(
      children: [
        Padding(
          padding: rail && accent != null
              ? padding
                  .add(const EdgeInsetsDirectional.only(start: _railWidth))
              : padding,
          child: child,
        ),
        if (rail && accent != null)
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: Container(width: _railWidth, color: accent),
          ),
      ],
    );

    return Card(
      color: surface,
      elevation: !elevated || dark ? 0 : 2,
      shadowColor: dark ? Colors.transparent : theme.colorScheme.shadow
          .withValues(alpha: 0.16),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: shape,
        side: BorderSide(
          color: borderColour,
          width: selected ? 1.8 : 1,
        ),
      ),
      child: onTap == null && onLongPress == null
          ? content
          : InkWell(
              onTap: onTap == null
                  ? null
                  : () {
                      if (haptic) {
                        AppHaptics.decision();
                      } else {
                        AppHaptics.select();
                      }
                      onTap!();
                    },
              onLongPress: onLongPress,
              // The ink is tinted by the card's own tone, so a red card
              // does not flash green when it is tapped.
              splashColor: (accent ?? theme.colorScheme.primary)
                  .withValues(alpha: 0.10),
              highlightColor: (accent ?? theme.colorScheme.primary)
                  .withValues(alpha: 0.05),
              child: content,
            ),
    );
  }
}

/// A card whose whole surface is a gradient — for the one block on a screen
/// that carries the headline figure.
///
/// Used sparingly and never for a list row: if two of these appear on one
/// screen, neither of them is the headline any more.
class AppGradientCard extends StatelessWidget {
  const AppGradientCard({
    super.key,
    required this.child,
    required this.tone,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.rail = true,
  });

  final Widget child;
  final AppTone tone;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool rail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = tone.on(context);
    final base = theme.cardTheme.color ?? theme.colorScheme.surface;
    final shape = BorderRadius.circular(AppShape.card + 2);

    final content = Stack(
      children: [
        Padding(
          padding: rail
              ? padding.add(const EdgeInsetsDirectional.only(start: 6))
              : padding,
          child: child,
        ),
        if (rail)
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 6, color: accent),
          ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.alphaBlend(
                accent.withValues(alpha: dark ? 0.18 : 0.12), base),
            Color.alphaBlend(
                accent.withValues(alpha: dark ? 0.05 : 0.02), base),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: dark ? 0.34 : 0.22),
        ),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: accent.withValues(alpha: 0.14),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: onTap == null
            ? content
            : Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap, child: content),
              ),
      ),
    );
  }
}
