import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../models/agreement_case.dart';
import '../../../../widgets/widgets.dart';
import '../../shared/intake_labels.dart';

/// The acts this reader may take, drawn from `stage.act_options` and nothing
/// else. A closed act is explained under the buttons, not hidden silently.
class IntakeActBar extends StatelessWidget {
  const IntakeActBar({super.key, required this.options, required this.onAct});

  final List<IntakeActOption> options;
  final ValueChanged<IntakeActOption> onAct;

  /// Reasons worth saying out loud. "Not at your stage" is every closed case.
  static const Set<String> _worthSaying = <String>{
    IntakeRefusalReason.queryOpen,
    IntakeRefusalReason.separationOfDuties,
    IntakeRefusalReason.priorStepNotValid,
    IntakeRefusalReason.locationChanged,
    IntakeRefusalReason.signatureRequired,
  };

  @override
  Widget build(BuildContext context) {
    final List<IntakeActOption> open = options
        .where((IntakeActOption o) => o.allowed)
        .toList();
    final Set<String> why = <String>{
      for (final IntakeActOption o in options)
        if (!o.allowed && _worthSaying.contains(o.reason))
          IntakeLabels.refusal(o.reason),
    };
    if (open.isEmpty && why.isEmpty) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final String line in why) ...<Widget>[
                AppAlert(
                  message: line,
                  tone: AppTone.warning,
                  icon: Icons.info_outline_rounded,
                  compact: true,
                ),
                const SizedBox(height: 8),
              ],
              // Two fit side by side. Past that the first act takes the full
              // width and the rest share the row under it.
              if (open.length > 2) ...<Widget>[
                _button(open.first),
                const SizedBox(height: 8),
              ],
              if (open.isNotEmpty)
                Row(
                  children: <Widget>[
                    for (final (int i, IntakeActOption o)
                        in open
                            .skip(open.length > 2 ? 1 : 0)
                            .indexed) ...<Widget>[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: _button(o)),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(IntakeActOption option) => AppButton(
    label: IntakeLabels.act(option.act),
    icon: _icon(option),
    variant: _variant(option.act),
    height: 44,
    onPressed: () => onAct(option),
  );

  static AppButtonVariant _variant(String act) => switch (act) {
    'reject' => AppButtonVariant.dangerOutline,
    'return' => AppButtonVariant.outline,
    _ => AppButtonVariant.primary,
  };

  static IconData? _icon(IntakeActOption option) => option.signed
      ? Icons.draw_outlined
      : switch (option.act) {
          'reject' => Icons.block_rounded,
          'return' => Icons.undo_rounded,
          'respond' => Icons.question_answer_outlined,
          'dispatch' => Icons.send_outlined,
          _ => null,
        };
}
