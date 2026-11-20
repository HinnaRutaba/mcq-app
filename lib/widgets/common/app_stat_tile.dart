import 'package:flutter/material.dart';

import '../../config/theme/app_brand.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../cards/app_card.dart';
import '../cards/app_tone_plate.dart';
import '../text/app_count_up.dart';
import '../text/app_text.dart';

/// One figure and what it counts.
///
/// A plate rather than a wash: the icon sits on its own tinted chip, the
/// figure is the largest thing on the tile, and the card is lifted off the
/// page. The brand tints the chip and nothing else unless [tone] is set —
/// colour on this tile has to mean a status, and "visits" is not one.
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.tone,
  }) : _countTo = null;

  /// A count, which runs up to itself when the screen arrives.
  // ignore: prefer_const_constructors_in_immutables -- '$count' is not const.
  AppStatTile.count(
    int count, {
    super.key,
    required this.label,
    this.icon,
    this.valueColor,
    this.tone,
  }) : value = '$count',
       _countTo = count;

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  /// Draws the tile on an [AppTonePlate] in this status. Only for a figure
  /// that means a state, and only inside a fixed-height cell.
  final AppTone? tone;

  /// Set by [AppStatTile.count] — null leaves the figure still.
  final int? _countTo;

  /// What a tile needs, for a caller laying these out at a fixed row height.
  static const double extent = 78;

  @override
  Widget build(BuildContext context) {
    final AppTone? shown = tone == AppTone.neutral ? null : tone;
    if (shown != null) {
      final Color ink = shown.on(context);
      return AppTonePlate(
        tone: shown,
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
        child: _body(
          chip: ink,
          mark: shown.onFilled(context),
          figure: valueColor ?? ink,
          label: ink,
        ),
      );
    }

    final Color brand = context.brand.primary;
    return AppCard(
      lift: AppLift.soft,
      radius: AppRadius.lg,
      borderColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: _body(
        chip: brand.withValues(alpha: 0.11),
        mark: brand,
        figure: valueColor,
      ),
    );
  }

  Widget _body({
    required Color chip,
    required Color mark,
    Color? figure,
    Color? label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Container(
                height: 26,
                width: 26,
                decoration: BoxDecoration(
                  color: chip,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 14, color: mark),
              ),
              const SizedBox(width: 9),
            ],
            Flexible(
              child: _countTo == null
                  ? AppText.headlineMedium(value, color: figure, maxLines: 1)
                  : AppCountUp.count(_countTo, color: figure),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Flexible so the label gives way rather than the tile overflowing —
        // line heights differ between the real font and a test's fallback,
        // and a fixed-extent grid cell has no give.
        Flexible(
          child: AppText.caption(
            this.label,
            color: label,
            fontWeight: FontWeight.w600,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
