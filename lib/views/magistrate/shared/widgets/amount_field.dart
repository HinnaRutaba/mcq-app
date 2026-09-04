import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../widgets/widgets.dart';

/// The one money field on a form, at the size the figure is read out at.
///
/// The fine's amount: the register suggests a figure, the officer may change
/// it, and it is sent as a string exactly as typed. A licence fee is not one
/// of these — MCQ's tariff prices it and the officer cannot alter it.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.validator,
    this.suggestion,
    this.source = 'the register',
    this.subject = 'fine',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;

  /// What the register suggests for the chosen row. Always said out loud
  /// underneath: an officer who does not know the figure is only a suggestion
  /// will not change it, and the figure has to fit what they are looking at.
  final String? suggestion;

  /// Who suggested it — the register the row was read off.
  final String source;

  /// What the figure is, for the line under it: a fine, or a fee.
  final String subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: AppText.headlineSmall('Rs', color: muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  onChanged: onChanged,
                  validator: validator,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  // Digits and one dot. The figure is never turned into a
                  // number on the handset — it is sent as typed.
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: muted?.withValues(alpha: 0.35),
                    ),
                    isDense: true,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: const UnderlineInputBorder(),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    errorMaxLines: 2,
                  ),
                ),
              ),
            ],
          ),
          if (suggestion != null) ...<Widget>[
            const SizedBox(height: 12),
            _SuggestionChip(
              suggestion: suggestion!,
              source: source,
              subject: subject,
              // Whether the figure in the field is still the register's own.
              unchanged: controller.text.trim() == suggestion,
            ),
          ],
        ],
      ),
    );
  }
}

/// The line under the amount: where the figure came from, and that it is the
/// officer's to change.
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.suggestion,
    required this.source,
    required this.subject,
    required this.unchanged,
  });

  final String suggestion;
  final String source;
  final String subject;
  final bool unchanged;

  @override
  Widget build(BuildContext context) {
    final Color ink = AppTone.info.on(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTone.info.container(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.lightbulb_outline_rounded, size: 16, color: ink),
          const SizedBox(width: 8),
          Expanded(
            child: AppText.caption(
              unchanged
                  ? 'Rs $suggestion is what $source suggests. Change it if '
                        'the $subject should be more or less.'
                  : 'Changed from the suggested Rs $suggestion.',
              color: ink,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}
