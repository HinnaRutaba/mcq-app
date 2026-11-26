import 'package:flutter/material.dart';

import '../../config/theme/app_radius.dart';
import '../text/app_text.dart';
import 'app_card.dart';

/// One row on a "More" hub, in either workspace: an icon, what the
/// destination is, and a line saying what the officer will find there.
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
    this.trailing,
    this.bare = false,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Only for the one destructive-feeling row. Everything else takes the
  /// brand tint, because a colour here would be decoration, not status.
  final Color? tint;

  /// Sits before the chevron, e.g. a count.
  final Widget? trailing;

  /// A row inside someone else's card: no surface or border of its own.
  final bool bare;

  /// Beside the title, e.g. a status tag.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tint ?? theme.colorScheme.primary;
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    const padding = EdgeInsetsDirectional.fromSTEB(14, 14, 10, 14);
    final row = Row(
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
              if (badge == null)
                AppText.titleMedium(title)
              else
                Row(
                  children: <Widget>[
                    Flexible(child: AppText.titleMedium(title, maxLines: 1)),
                    const SizedBox(width: 8),
                    badge!,
                  ],
                ),
              const SizedBox(height: 2),
              AppText.caption(subtitle, color: muted, maxLines: 2),
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[const SizedBox(width: 10), trailing!],
        Icon(Icons.chevron_right_rounded, color: muted),
      ],
    );
    if (bare) {
      return InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: row),
      );
    }
    return AppCard(onTap: onTap, padding: padding, child: row);
  }
}
