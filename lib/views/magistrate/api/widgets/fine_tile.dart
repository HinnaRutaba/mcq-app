import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/enforcement/fine.dart';
import '../../../../widgets/widgets.dart';
import 'api_enum_badge.dart';

/// A fine as it appears in a list.
///
/// If it needs approval it is **not yet effective** — the row says so
/// rather than showing it as imposed.
class FineTile extends StatelessWidget {
  const FineTile({super.key, required this.fine, this.onTap});

  final Fine fine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium(
                      fine.fineType.isEmpty
                          ? t('fines.title')
                          : fine.fineType.label,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    AppText.caption(
                      '${fine.property.label} · ${fine.fineNo}',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              MoneyText.row(fine.amount),
            ],
          ),
          if (fine.payerName.isNotEmpty) ...[
            const SizedBox(height: 8),
            UserText.body(fine.payerName, maxLines: 1),
          ],
          if ((fine.legalProvision ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            AppText.caption(fine.legalProvision!, maxLines: 2),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ApiEnumBadge(fine.status),
              if (fine.notYetEffective)
                AppStatusBadge(
                  label: t('fines.requiresApproval'),
                  tone: AppStatusTone.warning,
                ),
              if (fine.imposedOn != null)
                AppText.caption(Formatters.date(fine.imposedOn!)),
            ],
          ),
        ],
      ),
    );
  }
}
