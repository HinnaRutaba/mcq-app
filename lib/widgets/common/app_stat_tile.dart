import 'package:flutter/material.dart';

import '../cards/app_card.dart';
import '../text/app_text.dart';

/// A small "label + big value" stat block, used in the summary rows on the
/// dashboards.
///
/// The icon sits beside the figure rather than above it. Stacked, it pushed a
/// band of empty card through the middle of every tile and made a row of four
/// numbers take up half a screen.
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  /// What a tile needs, for a caller laying these out at a fixed row height.
  static const double extent = 76;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: AppText.headlineSmall(
                  value,
                  color: valueColor,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Flexible so the label gives way rather than the tile overflowing —
          // line heights differ between the real font and a test's fallback,
          // and a fixed-extent grid cell has no give.
          Flexible(child: AppText.caption(label, maxLines: 2)),
        ],
      ),
    );
  }
}
