import 'package:flutter/material.dart';

import '../../../../widgets/widgets.dart';
import '../../../../config/theme/app_radius.dart';

/// One row on the "More" hub: an icon, what the destination is, and a line
/// saying what the officer will find there.
///
/// Built on [AppCard] so it carries the app's one card surface, radius and
/// border rather than a second hand-rolled one.
class MoreMenuTile extends StatelessWidget {
  const MoreMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Only for the one destructive-feeling row. Everything else takes the
  /// brand tint, because a colour here would be decoration, not status.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tint ?? theme.colorScheme.primary;
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 10, 14),
      child: Row(
        children: <Widget>[
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppText.titleMedium(title),
                const SizedBox(height: 2),
                AppText.caption(subtitle, color: muted, maxLines: 2),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: muted),
        ],
      ),
    );
  }
}
