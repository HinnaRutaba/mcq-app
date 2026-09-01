import 'package:flutter/material.dart';

import '../text/app_text.dart';

/// A section heading with an optional trailing action.
///
/// Screens have a lot of sections and they all used to be a bare
/// `Row(Text, TextButton)`. This keeps the rhythm identical everywhere —
/// which is most of what makes a screen look designed rather than
/// assembled.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleLarge(title, maxLines: 2),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  AppText.bodySmall(
                    subtitle!,
                    color: theme.colorScheme.onSurfaceVariant,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: AppText.label(actionLabel!),
            ),
        ],
      ),
    );
  }
}
