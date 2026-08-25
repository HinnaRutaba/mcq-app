import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../text/app_text.dart';

/// The semantic "job" a status color communicates — never assigned by
/// screen or reused for an unrelated series, only for actual state.
enum AppStatusTone { neutral, info, success, warning, danger }

/// The single status-pill widget every screen should use to show a state
/// (chalaan status, seal status, etc). Status is always paired with a text
/// [label] — never color alone.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({super.key, required this.label, this.tone = AppStatusTone.neutral});

  final String label;
  final AppStatusTone tone;

  Color _color(BuildContext context) {
    switch (tone) {
      case AppStatusTone.success:
        return AppColors.success;
      case AppStatusTone.warning:
        return AppColors.warning;
      case AppStatusTone.danger:
        return AppColors.error;
      case AppStatusTone.info:
        return AppColors.info;
      case AppStatusTone.neutral:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: AppText.caption(label, color: color, fontWeight: FontWeight.w700),
    );
  }
}
