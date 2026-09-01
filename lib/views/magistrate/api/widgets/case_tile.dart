import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/enforcement/enforcement_case.dart';
import '../../../../widgets/widgets.dart';
import 'api_enum_badge.dart';

/// One enforcement case in a list.
class CaseTile extends StatelessWidget {
  const CaseTile({super.key, required this.enforcementCase, this.onTap});

  final EnforcementCase enforcementCase;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final owed = enforcementCase.outstanding;

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
                    UserText.name(enforcementCase.allottee.name),
                    const SizedBox(height: 2),
                    AppText.caption(
                      '${enforcementCase.property.label} · ${enforcementCase.property.areaName}',
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              if (owed != null) MoneyText.row(owed),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ApiEnumBadge(enforcementCase.status),
              if (enforcementCase.visitOverdue)
                AppStatusBadge(
                  label: t('cases.visitOverdue'),
                  tone: AppStatusTone.danger,
                ),
              if (enforcementCase.isSealed)
                AppStatusBadge(
                  label: t('seal.sealed'),
                  tone: AppStatusTone.neutral,
                ),
            ],
          ),
          const SizedBox(height: 8),
          AppText.caption(
            enforcementCase.nextVisitDate == null
                ? t('cases.noNextVisit')
                : t('cases.nextVisit', args: {
                    'date': Formatters.date(enforcementCase.nextVisitDate!),
                  }),
          ),
        ],
      ),
    );
  }
}
