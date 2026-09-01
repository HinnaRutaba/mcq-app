import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../text/app_text.dart';

/// A triage signal on a card: an icon, a word, and a tone.
///
/// **The icon and the word are not decoration.** A magistrate may be
/// colour-blind and is certainly in bright sunlight; a red pill and an
/// amber pill have to be distinguishable in greyscale, so every pill
/// carries a glyph and a sentence and the colour only reinforces them.
///
/// [emphasis] draws the pill filled rather than tinted, for the one signal
/// on a card that has to win — a broken promise, or "never paid".
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    required this.icon,
    this.tone = AppTone.neutral,
    this.emphasis = false,
  });

  final String label;
  final IconData icon;
  final AppTone tone;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final colour = tone.on(context);
    final onFilled = ThemeData.estimateBrightnessForColor(colour) ==
            Brightness.dark
        ? Colors.white
        : AppColors.onAccent;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 12, 6),
      decoration: BoxDecoration(
        color: emphasis ? colour : colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasis ? colour : colour.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: emphasis ? onFilled : colour),
          const SizedBox(width: 6),
          Flexible(
            child: AppText.caption(
              label,
              color: emphasis ? onFilled : colour,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// The row of pills along the bottom of a card. Wraps rather than
/// scrolling — a signal the officer has to swipe to find is a signal he
/// will not see.
class AppPillStrip extends StatelessWidget {
  const AppPillStrip({super.key, required this.pills, this.spacing = 7});

  final List<Widget> pills;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (pills.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: spacing, runSpacing: spacing, children: pills);
  }
}
