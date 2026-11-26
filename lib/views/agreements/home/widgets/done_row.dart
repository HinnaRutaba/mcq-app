import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../widgets/widgets.dart';

/// One line of "What you did". A main row (Pending, Forwarded, Cancelled)
/// carries a small icon; an item under a group carries none.
class DoneRow extends StatelessWidget {
  const DoneRow.main({
    super.key,
    required this.title,
    required this.count,
    required IconData this.icon,
    this.tone,
    this.onTap,
  }) : item = false;

  const DoneRow.item({
    super.key,
    required this.title,
    required this.count,
    this.onTap,
  }) : icon = null,
       tone = null,
       item = true;

  final String title;
  final int count;
  final IconData? icon;
  final AppTone? tone;

  /// Null on a group's row: no one list holds the whole group.
  final VoidCallback? onTap;
  final bool item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.5,
    );
    final AppTone? shown = count == 0 ? null : tone;
    final Color? ink = shown?.on(context) ?? (count == 0 ? muted : null);

    final Widget row = Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          // Same square plate as the dashboard tiles' icons.
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color:
                  shown?.on(context) ??
                  (ink ?? theme.colorScheme.primary).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              size: 17,
              color:
                  shown?.onFilled(context) ?? ink ?? theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: item
              ? AppText.body(title, color: ink, maxLines: 1)
              : AppText.titleMedium(
                  title,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                ),
        ),
        if (item)
          AppText.body('$count', fontWeight: FontWeight.w600, color: ink)
        else
          AppText.titleLarge('$count', fontWeight: FontWeight.w800, color: ink),
        // Same width either way, so every count sits in one column.
        SizedBox(
          width: 28,
          child: onTap == null
              ? null
              : Icon(Icons.chevron_right_rounded, size: 20, color: muted),
        ),
      ],
    );

    // A main row gets a faint band in its tone so the groups stand out.
    return Material(
      color: item
          ? Colors.transparent
          : (ink ?? theme.colorScheme.primary).withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: item
              ? const EdgeInsetsDirectional.fromSTEB(58, 7, 8, 7)
              : const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 14),
          child: row,
        ),
      ),
    );
  }
}
