import 'package:flutter/material.dart';

import '../cards/app_card.dart';
import '../text/app_text.dart';

/// A small "label + big value" stat block, used in the summary rows on
/// both dashboards.
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

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
          ],
          AppText.headlineSmall(value, color: valueColor, maxLines: 1),
          const SizedBox(height: 4),
          AppText.caption(label, maxLines: 1),
        ],
      ),
    );
  }
}
