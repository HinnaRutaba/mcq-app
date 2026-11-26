import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/agreement_case.dart';
import '../../../../widgets/widgets.dart';
import 'intake_info_card.dart';

/// The instalment offer: what is paid each month up top, then the total and
/// the months it runs. Every figure is the server's.
class IntakeInstalmentsCard extends StatelessWidget {
  const IntakeInstalmentsCard({super.key, required this.plan});

  final IntakeInstalments plan;

  @override
  Widget build(BuildContext context) {
    final DateTime? first = plan.firstPeriod;
    final DateTime? last = plan.lastPeriod;
    final int? months = plan.months;
    final bool split = plan.uneven && plan.last != null;

    return IntakeInfoCard(
      title: 'Instalments',
      icon: Icons.event_repeat_outlined,
      trailing: AppStatusBadge(
        label: plan.offered ? 'Offered' : 'Not offered',
        tone: plan.offered ? AppTone.success : AppTone.neutral,
      ),
      children: plan.offered
          ? <Widget>[
              if (plan.each != null)
                _Headline(
                  amount: _money(plan.each!),
                  // Uneven: the headline covers every month but the last.
                  note: months == null
                      ? 'a month'
                      : split
                      ? 'a month for ${months - 1} months'
                      : 'a month for ${_months(months)}',
                ),
              ...IntakeFact.of(<String, String?>{
                if (split) 'Final instalment': _money(plan.last!),
                'Total': plan.total == null ? null : _money(plan.total!),
                if (plan.each == null && months != null)
                  'Duration': _months(months),
                'First instalment': first == null
                    ? null
                    : Formatters.monthYear(first),
                'Last instalment': last == null || months == 1
                    ? null
                    : Formatters.monthYear(last),
              }),
            ]
          : const <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: AppText.body('No instalment plan on this case.'),
              ),
            ],
    );
  }

  static String _months(int n) => '$n month${n == 1 ? '' : 's'}';

  /// Paise kept when there are any: "Rs 152,627.50".
  static String _money(String value) => Formatters.moneyExact(value) ?? value;
}

/// The monthly figure, large, on a soft brand tint.
class _Headline extends StatelessWidget {
  const _Headline({required this.amount, required this.note});

  final String amount;
  final String note;

  @override
  Widget build(BuildContext context) {
    final Color brand = AppTone.primary.on(context);
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.65);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppText.titleLarge(amount, color: brand, maxLines: 1),
          const SizedBox(height: 2),
          AppText.caption(note, color: muted, maxLines: 1),
        ],
      ),
    );
  }
}
