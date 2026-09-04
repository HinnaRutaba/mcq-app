import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../models/person_lookup.dart';
import '../../../../widgets/widgets.dart';

/// Who the registers say the typed CNIC belongs to, offered under the field.
///
/// Offered, never applied on its own: MCQ has no single person register, so
/// this says which register the name came from and how many fines are already
/// on it — a first offence and a fifth are different conversations at a
/// counter — and the officer decides whether the person in front of them is
/// the person on record.
class PersonSuggestionCard extends StatelessWidget {
  const PersonSuggestionCard({
    super.key,
    required this.person,
    required this.onTake,
  });

  final PersonLookup person;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final PersonSuggestion suggestion = person.suggested!;

    return AppCard(
      onTap: onTake,
      borderColor: theme.colorScheme.primary.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.badge_outlined,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppText.titleMedium(suggestion.name),
                    const SizedBox(height: 2),
                    AppText.caption(
                      // The register it came off: a name on a signed tenancy
                      // is worth more than one off an application.
                      _sourceLine(suggestion.source),
                      color: muted,
                    ),
                  ],
                ),
              ),
              if (person.isRepeatOffender)
                AppStatusBadge(
                  label: person.fineCount == 1
                      ? '1 fine'
                      : '${person.fineCount} fines',
                  tone: AppTone.warning,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (suggestion.fatherName != null)
            AppDetailRow(
              icon: Icons.person_outline_rounded,
              value: 'S/O ${suggestion.fatherName}',
            ),
          if (suggestion.mobileNo != null)
            AppDetailRow(
              icon: Icons.phone_outlined,
              value: suggestion.mobileNo!,
            ),
          if (person.isOnTradeRegister)
            AppDetailRow(
              icon: Icons.storefront_outlined,
              value: person.tradeLicences.length == 1
                  ? 'Holds a trade licence'
                  : 'Holds ${person.tradeLicences.length} trade licences',
            ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.person_add_alt_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppText.caption(
                    'Tap to fill in who pays',
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The register behind the name, in the officer's words. Server-defined, so
  /// anything unrecognised is said plainly rather than guessed at.
  static String _sourceLine(String? source) => switch (source) {
    'allottee' => 'On the property register',
    'trade_licence' => 'On the trade licence register',
    null => 'On record',
    _ => 'On record ($source)',
  };
}
