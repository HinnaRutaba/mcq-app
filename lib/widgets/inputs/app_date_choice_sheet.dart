import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../buttons/app_button.dart';
import '../motion/app_pressable.dart';
import '../text/app_text.dart';

/// Taking a promise must be two taps.
///
/// The officer has five minutes with a shopkeeper who is arguing with him.
/// A shopkeeper does not say "the fourteenth"; he says "after Eid", "next
/// week", "end of the month" — so those are the buttons, and the calendar
/// is there for the one time in ten it is not enough.
///
/// The same sheet takes a revisit date, which is the other half of the pair
/// that was missing entirely and is what makes the app worth carrying.
class AppDateChoiceSheet {
  AppDateChoiceSheet._();

  /// Returns the chosen date, or null if the officer backed out.
  static Future<DateTime?> ask(
    BuildContext context, {
    required String title,
    String? subtitle,
    DateTime? earliest,
    DateTime? latest,
  }) {
    final today = DateTime.now();
    final from = DateTime(today.year, today.month, today.day);

    // Quick options, in the words a shopkeeper actually uses.
    final quick = <_DateOption>[
      _DateOption(t('date.inOneWeek'), from.add(const Duration(days: 7))),
      _DateOption(t('date.inTenDays'), from.add(const Duration(days: 10))),
      _DateOption(t('date.endOfMonth'), DateTime(from.year, from.month + 1, 0)),
      _DateOption(
        t('date.endOfNextMonth'),
        DateTime(from.year, from.month + 2, 0),
      ),
    ];

    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _Sheet(
        title: title,
        subtitle: subtitle,
        options: quick,
        earliest: earliest ?? from,
        latest: latest ?? from.add(const Duration(days: 365)),
      ),
    );
  }
}

class _DateOption {
  const _DateOption(this.label, this.date);

  final String label;
  final DateTime date;
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.earliest,
    required this.latest,
  });

  final String title;
  final String? subtitle;
  final List<_DateOption> options;
  final DateTime earliest;
  final DateTime latest;

  Future<void> _pick(BuildContext context) async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: earliest,
      firstDate: earliest,
      lastDate: latest,
    );
    if (chosen != null && context.mounted) Navigator.of(context).pop(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              AppText.titleLarge(title),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                AppText.body(
                  subtitle!,
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ],
              const SizedBox(height: 18),
              for (final option in options) ...[
                AppPressable(
                  onTap: () => Navigator.of(context).pop(option.date),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 15, 16, 15),
                    margin: const EdgeInsetsDirectional.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 21,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: AppText.titleMedium(option.label)),
                        // The actual date, always — "next week" is a
                        // promise somebody will dispute later.
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: AppText.bodySmall(
                            Formatters.date(option.date),
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              AppButton(
                label: t('date.pickAnother'),
                icon: Icons.calendar_month_rounded,
                variant: AppButtonVariant.outline,
                onPressed: () => _pick(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
