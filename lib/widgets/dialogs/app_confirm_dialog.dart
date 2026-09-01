import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_status_colors.dart';
import '../../l10n/app_localizations.dart';
import '../motion/app_pressable.dart';
import '../text/app_text.dart';

/// The confirmation every destructive action goes through.
///
/// [body] must **name the shop and the allottee**. Sealing the wrong shop
/// is a real-world event with a real-world consequence for a real family's
/// income, and releasing a seal that should stand loses MCQ its leverage.
/// Neither is an undo-able tap.
///
/// It is a real [AlertDialog], so it gets the platform's barrier, its
/// focus trap, its escape handling and its screen-reader announcement. What
/// is added is the part a dialog cannot know: an icon in the destructive
/// tone at the top, so the officer sees *what kind* of decision this is
/// before he has read the sentence, and the actions laid out with the
/// confirm on the trailing side where the thumb expects it.
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.destructive = true,
    this.note,
    this.icon,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final bool destructive;

  /// A quieter line beneath the question — what will happen afterwards,
  /// what cannot be undone.
  final String? note;

  final IconData? icon;

  /// Returns true only if the officer confirmed.
  static Future<bool> ask(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = true,
    String? note,
    IconData? icon,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppConfirmDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        destructive: destructive,
        note: note,
        icon: icon,
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = context.status;
    final tone = destructive ? AppTone.danger : AppTone.primary;
    final colour =
        destructive ? status.danger : theme.colorScheme.primary;

    return AlertDialog(
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: tone.container(context),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon ??
              (destructive
                  ? Icons.warning_amber_rounded
                  : Icons.help_outline_rounded),
          color: colour,
          size: 26,
        ),
      ),
      title: AppText.titleLarge(title, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText.body(body, textAlign: TextAlign.center),
          if (note != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppText.bodySmall(
                note!,
                textAlign: TextAlign.center,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actionsPadding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 20),
      actions: [
        // Cancel is a real TextButton and stays quiet; confirm is filled in
        // the tone of what it does. Nobody confirms a seal by accident
        // because the two buttons looked the same.
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: AppText.label(t('common.cancel')),
          ),
        ),
        Expanded(
          child: FilledButton(
            onPressed: () {
              if (destructive) AppHaptics.decision();
              Navigator.of(context).pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colour,
              foregroundColor:
                  destructive ? status.onDanger : theme.colorScheme.onPrimary,
            ),
            child: Text(
              confirmLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
