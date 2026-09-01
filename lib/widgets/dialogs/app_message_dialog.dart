import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../buttons/app_button.dart';
import '../text/app_text.dart';

/// A dialog carrying a sentence the server wrote.
///
/// A 409 is a domain refusal — "The dues are not cleared, so this seal
/// cannot be released" — and the officer has to read it and act on it,
/// standing in front of a shopkeeper who is arguing with them. A toast that
/// fades in three seconds is the wrong container for that.
///
/// [message] is shown **verbatim**: it is already translated into the
/// officer's language and it names what was refused and usually what to do
/// instead. Never replace it with "Something went wrong".
class AppMessageDialog extends StatelessWidget {
  const AppMessageDialog({
    super.key,
    required this.message,
    this.title,
    this.secondaryLabel,
  });

  final String message;
  final String? title;

  /// An optional second button, e.g. "Send again" on a stuck queue item.
  final String? secondaryLabel;

  /// Returns true if the officer tapped the secondary action.
  static Future<bool> show(
    BuildContext context, {
    required String message,
    String? title,
    String? secondaryLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AppMessageDialog(
        message: message,
        title: title,
        secondaryLabel: secondaryLabel,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title == null ? null : AppText.titleLarge(title!),
      content: AppText.body(message),
      actionsPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
      actions: [
        Column(
          children: [
            if (secondaryLabel != null) ...[
              AppButton(
                label: secondaryLabel!,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 8),
            ],
            AppButton(
              label: t('common.close'),
              variant: secondaryLabel == null
                  ? AppButtonVariant.primary
                  : AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ],
    );
  }
}
