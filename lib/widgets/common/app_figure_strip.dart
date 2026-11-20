import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../cards/app_brand_plate.dart';
import '../text/app_count_up.dart';
import '../text/app_text.dart';

/// One figure on an [AppFigureStrip].
class StripFigure {
  const StripFigure({
    required this.value,
    required this.label,
    required this.icon,
    this.tone,
  });

  final int value;
  final String label;
  final IconData icon;

  /// Null for a figure that is a fact, not a state — it wears the plate's ink.
  final AppTone? tone;
}

/// A few headline counts side by side on the brand plate, split by hairlines.
class AppFigureStrip extends StatelessWidget {
  const AppFigureStrip({super.key, required this.figures});

  final List<StripFigure> figures;

  @override
  Widget build(BuildContext context) {
    final Color ink = AppBrandPlate.inkOf(context);
    return AppBrandPlate(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < figures.length; i++) ...<Widget>[
            if (i > 0)
              Container(
                width: 1,
                height: 44,
                margin: const EdgeInsets.only(top: 4),
                color: ink.withValues(alpha: 0.16),
              ),
            Expanded(
              child: _Figure(figure: figures[i], ink: ink),
            ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.figure, required this.ink});

  final StripFigure figure;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    // A red 0 reads as one more thing to chase; at zero the tone is dropped.
    final bool live = figure.value > 0 && figure.tone != null;
    // The dark theme's tone in both themes: the plate is dark in both.
    final Color colour = live
        ? figure.tone!.resolve(Brightness.dark)
        : ink.withValues(alpha: 0.75);

    return Column(
      children: <Widget>[
        Container(
          height: 26,
          width: 26,
          decoration: BoxDecoration(
            color: ink.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(figure.icon, size: 14, color: colour),
        ),
        const SizedBox(height: 6),
        AppCountUp.count(figure.value, color: live ? colour : ink),
        const SizedBox(height: 3),
        AppText.caption(
          figure.label,
          color: ink,
          maxLines: 1,
          fontWeight: FontWeight.w600,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
