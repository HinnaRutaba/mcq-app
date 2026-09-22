import 'package:flutter/material.dart';

import '../../config/theme/app_brand.dart';
import '../../config/theme/app_radius.dart';
import '../cards/app_card.dart';
import '../text/app_count_up.dart';
import '../text/app_text.dart';

/// One figure and what it counts.
///
/// A plate rather than a wash: the icon sits on its own tinted chip, the
/// figure is the largest thing on the tile, and the card is lifted off the
/// page. The brand tints the chip and nothing else — colour on this tile would
/// have to mean a status, and "visits" is not one.
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  }) : _countTo = null;

  /// A count, which runs up to itself when the screen arrives.
  // ignore: prefer_const_constructors_in_immutables -- '$count' is not const.
  AppStatTile.count(
    int count, {
    super.key,
    required this.label,
    this.icon,
    this.valueColor,
  }) : value = '$count',
       _countTo = count;

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  /// Set by [AppStatTile.count] — null leaves the figure still.
  final int? _countTo;

  /// What a tile needs, for a caller laying these out at a fixed row height.
  static const double extent = 78;

  @override
  Widget build(BuildContext context) {
    final AppBrandColors brand = context.brand;

    return AppCard(
      lift: AppLift.soft,
      radius: AppRadius.lg,
      borderColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: Column(
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
                    color: brand.primary.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 14, color: brand.primary),
                ),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: _countTo == null
                    ? AppText.headlineMedium(
                        value,
                        color: valueColor,
                        maxLines: 1,
                      )
                    : AppCountUp.count(_countTo, color: valueColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Flexible so the label gives way rather than the tile overflowing —
          // line heights differ between the real font and a test's fallback,
          // and a fixed-extent grid cell has no give.
          Flexible(
            child: AppText.caption(
              label,
              fontWeight: FontWeight.w600,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
