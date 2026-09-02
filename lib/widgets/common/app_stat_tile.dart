import 'package:flutter/material.dart';

import '../../config/theme/app_brand.dart';
import '../cards/app_card.dart';
import '../text/app_text.dart';


class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.filled = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  final bool filled;

  /// What a tile needs, for a caller laying these out at a fixed row height.
  static const double extent = 76;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final ink = filled ? brand.onFilledPlate : null;

    return AppCard(
      gradient: filled ? brand.filledPlate : null,
      borderColor: filled
          ? brand.onFilledPlate.withValues(alpha: 0.16)
          : null,
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
                  color: ink ?? Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: AppText.headlineSmall(
                  value,
                  color: valueColor ?? ink,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Flexible so the label gives way rather than the tile overflowing —
          // line heights differ between the real font and a test's fallback,
          // and a fixed-extent grid cell has no give.
          Flexible(
            child: AppText.caption(
              label,
              color: ink,
              fontWeight: filled ? FontWeight.w600 : null,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
