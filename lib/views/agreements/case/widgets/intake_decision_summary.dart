import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/agreement_case.dart';
import '../../../../widgets/widgets.dart';
import '../../shared/widgets/intake_card.dart';

/// The case being decided, compact: who and where, its status, and the facts
/// a reviewer checks as chips — warnings among them in their own tones.
class IntakeDecisionSummary extends StatelessWidget {
  const IntakeDecisionSummary({super.key, required this.file});

  final AgreementCase file;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.65);
    final String? rent = Formatters.money(
      file.amounts['verified_monthly_rent'] ?? file.amounts['monthly_rent'],
    );
    final String? address = file.shop.addressLine;

    final List<Widget> chips = <Widget>[
      if (file.query != null)
        const AppStatusBadge(
          icon: Icons.help_outline_rounded,
          label: 'Query open',
          tone: AppTone.warning,
        ),
      if (file.shop.locationChangedSinceReview)
        const AppStatusBadge(
          icon: Icons.wrong_location_outlined,
          label: 'Location changed',
          tone: AppTone.danger,
        ),
      _chip(Icons.tag_rounded, file.intakeNo ?? 'Case ${file.id}'),
      if (file.caseType != null)
        _chip(Icons.category_outlined, file.caseType!.label),
      if (rent != null) _chip(Icons.payments_outlined, '$rent / month'),
      if (file.submittedAt != null)
        _chip(
          Icons.schedule_rounded,
          Formatters.date(file.submittedAt!.toLocal()),
        ),
    ];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: AppText.titleMedium(file.title, maxLines: 1)),
              if (file.status != null) ...<Widget>[
                const SizedBox(width: 8),
                IntakeStatusBadge(
                  status: file.status!.value,
                  label: file.status!.label,
                  tone: file.status!.tone,
                ),
              ],
            ],
          ),
          if (address != null) ...<Widget>[
            const SizedBox(height: 3),
            Row(
              children: <Widget>[
                Icon(Icons.place_outlined, size: 14, color: muted),
                const SizedBox(width: 4),
                Expanded(
                  child: AppText.caption(address, color: muted, maxLines: 1),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: chips),
        ],
      ),
    );
  }

  static Widget _chip(IconData icon, String label) =>
      AppStatusBadge(icon: icon, label: label, tone: AppTone.primary);
}
