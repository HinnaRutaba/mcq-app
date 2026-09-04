import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../text/app_text.dart';
import '../../config/theme/app_radius.dart';

class AppAlert extends StatelessWidget {
  const AppAlert({
    super.key,
    required this.message,
    this.tone = AppTone.danger,
    this.icon,
    this.compact = false,
  });

  final String message;
  final AppTone tone;

  /// Defaults to an error mark; pass an icon that suits a non-danger [tone].
  final IconData? icon;

  /// Tighter, for the submit bar — the same metrics as `StillNeededNote`, so
  /// the two things that can sit above a button read as one family rather than
  /// two sizes of red.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = tone.on(context);

    return Container(
      width: double.infinity,
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tone.container(context),
        borderRadius: BorderRadius.circular(
          compact ? AppRadius.sm : AppRadius.md,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.error_outline_rounded,
            size: compact ? 16 : 18,
            color: color,
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: compact
                ? AppText.label(
                    message,
                    color: color,
                    fontWeight: FontWeight.normal,
                  )
                : AppText.body(message, color: color),
          ),
        ],
      ),
    );
  }
}
