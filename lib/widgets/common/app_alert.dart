import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../text/app_text.dart';
import '../../config/theme/app_radius.dart';

/// The single inline message block for a form or a screen — the thing that says
/// why a submission did not go through.
///
/// Deliberately not a SnackBar: a failure the officer has to act on (a wrong
/// password, a refused seal, a fine that needs approval) belongs on screen next
/// to what it concerns, not sliding away after four seconds while they are
/// standing in front of a shopkeeper.
///
/// Colours come from [AppTone], so this is the same red as every other red in
/// the app and re-steps itself for dark mode.
class AppAlert extends StatelessWidget {
  const AppAlert({
    super.key,
    required this.message,
    this.tone = AppTone.danger,
    this.icon,
  });

  final String message;
  final AppTone tone;

  /// Defaults to an error mark; pass an icon that suits a non-danger [tone].
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = tone.on(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tone.container(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.error_outline_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: AppText.body(message, color: color)),
        ],
      ),
    );
  }
}
