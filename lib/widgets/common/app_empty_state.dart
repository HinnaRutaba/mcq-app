import 'package:flutter/material.dart';

import '../../config/theme/app_radius.dart';
import '../cards/app_card.dart';
import '../text/app_text.dart';

/// The single "nothing here" placeholder every empty list should use.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required IconData this.icon,
    required this.title,
    this.message,
  }) : art = null;

  /// A short card with an illustration beside the text — for an empty block
  /// inside a page, where the full placeholder would push the rest away.
  const AppEmptyState.compact({
    super.key,
    required Widget this.art,
    required this.title,
    this.message,
  }) : icon = null;

  final IconData? icon;
  final Widget? art;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    if (art != null) {
      return AppCard(
        lift: AppLift.soft,
        radius: AppRadius.lg,
        borderColor: Theme.of(
          context,
        ).colorScheme.outline.withValues(alpha: 0.6),
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        child: Row(
          children: [
            art!,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.titleMedium(title),
                  if (message != null) ...[
                    const SizedBox(height: 4),
                    AppText.body(message!, color: muted),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: muted),
            const SizedBox(height: 16),
            AppText.titleMedium(title, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 6),
              AppText.body(message!, color: muted, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
