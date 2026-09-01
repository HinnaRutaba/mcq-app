import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../text/app_text.dart';

/// The semantic "job" a status colour communicates — never assigned by
/// screen or reused for an unrelated series, only for actual state.
enum AppStatusTone { neutral, info, success, warning, danger }

extension AppStatusToneMapping on AppStatusTone {
  /// The app-wide tone, so a status pill and a toned card are the same red.
  AppTone get tone {
    switch (this) {
      case AppStatusTone.success:
        return AppTone.success;
      case AppStatusTone.warning:
        return AppTone.warning;
      case AppStatusTone.danger:
        return AppTone.danger;
      case AppStatusTone.info:
        return AppTone.info;
      case AppStatusTone.neutral:
        return AppTone.neutral;
    }
  }
}

/// The single status-pill widget every screen uses to show a state.
///
/// Status is always paired with a text [label] — never colour alone — and
/// carries an [icon] wherever one exists, so the pill survives greyscale,
/// sunlight and a colour-blind reader.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.icon,
  });

  final String label;
  final AppStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colour = tone.tone.on(context);
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(icon == null ? 11 : 9, 6, 12, 6),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colour.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: colour),
            const SizedBox(width: 6),
          ],
          Flexible(child: AppText.caption(label, color: colour, maxLines: 1)),
        ],
      ),
    );
  }
}
