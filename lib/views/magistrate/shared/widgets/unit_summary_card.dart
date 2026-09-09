import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../widgets/widgets.dart';

/// The shop a field write is against, as the register has it — shown, never
/// asked for.
///
/// Drawn from the unit card the officer arrived with, or from the profile
/// fetched behind a route that carried only an id, so it takes plain values
/// rather than either record.
class UnitSummaryCard extends StatelessWidget {
  const UnitSummaryCard({
    super.key,
    required this.title,
    this.holder,
    this.code,
    this.area,
    this.address,
    this.outstanding,
    this.isVacant = false,
    this.isSealed = false,
  });

  /// e.g. "F-3 · Liaquat Bazaar".
  final String title;

  /// Who the register says holds it. Null where it names nobody.
  final String? holder;

  final String? code;
  final String? area;
  final String? address;

  /// Rent arrears, as the server sent them. Never added to anything.
  final String? outstanding;

  final bool isVacant;
  final bool isSealed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.6,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.storefront_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppText.titleMedium(title),
                    const SizedBox(height: 2),
                    AppText.caption(
                      // "Vacant" is not the same fact as "owes nothing", so
                      // the two never share a line.
                      isVacant
                          ? 'Vacant — nobody holds this unit'
                          : (holder ?? 'Held, allottee not named'),
                      color: muted,
                    ),
                  ],
                ),
              ),
              if (isSealed)
                const AppStatusBadge(label: 'Sealed', tone: AppTone.warning),
            ],
          ),
          const SizedBox(height: 12),
          if (code != null) AppDetailRow(icon: Icons.tag_rounded, value: code!),
          if (area != null)
            AppDetailRow(icon: Icons.location_on_outlined, value: area!),
          if (address != null)
            AppDetailRow(
              icon: Icons.place_outlined,
              value: address!,
              maxLines: 2,
            ),
          if (outstanding != null)
            // Rent arrears, and a fine is a separate debt: the two figures are
            // never added together.
            AppDetailRow(
              icon: Icons.account_balance_wallet_outlined,
              value:
                  '${Formatters.money(outstanding) ?? outstanding} owed in rent',
            ),
        ],
      ),
    );
  }
}
