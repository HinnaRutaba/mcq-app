import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/dialer.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/defaulter_card.dart';
import '../../../../widgets/widgets.dart';

class DefaulterTile extends StatelessWidget {
  const DefaulterTile({
    super.key,
    required this.card,
    this.onTap,
    this.dialer = const Dialer(),
  });

  final DefaulterCard card;

  final VoidCallback? onTap;

  final Dialer dialer;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final String? note = _note();
    final List<Widget> badges = _badges();
    final String? mobileNo = card.mobileNo;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: AppText.titleMedium(
                  card.allotteeName ?? 'No holder on record',
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 12),
              AppText.titleMedium(
                Formatters.money(card.outstanding) ?? card.outstanding,
                maxLines: 1,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: <Widget>[
              Expanded(child: AppText.body(_unit, maxLines: 1)),
              if (_behind != null) ...[
                const SizedBox(width: 12),
                AppText.caption(
                  _behind!,
                  color: AppTone.danger.on(context),
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                ),
              ],
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            AppText.caption(note, color: muted, maxLines: 1),
          ],
          if (badges.isNotEmpty || mobileNo != null) ...[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Wrap(spacing: 6, runSpacing: 6, children: badges),
                ),
                if (mobileNo != null) ...[
                  const SizedBox(width: 8),
                  _CallButton(mobileNo: mobileNo, dialer: dialer),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String get _unit {
    final String unit =
        card.shopNo ?? card.propertyCode ?? card.allotmentNo ?? 'Unit';
    final String? place = card.marketName ?? card.areaName;
    return place == null ? unit : '$unit · $place';
  }

  String? get _behind {
    final int? months = card.monthsBehind;
    if (months != null && months > 0) {
      return '$months ${months == 1 ? 'month' : 'months'} behind';
    }
    final int? days = card.daysOverdue;
    if (days != null && days > 0) {
      return '$days ${days == 1 ? 'day' : 'days'} overdue';
    }
    return null;
  }

  String? _note() {
    final DateTime? lastPaid = card.lastPaymentDate;
    final List<String> parts = <String>[
      if (card.allotmentNo != null) card.allotmentNo!,
      if (lastPaid != null) 'last paid ${Formatters.date(lastPaid.toLocal())}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  List<Widget> _badges() {
    final DateTime? nextVisit = card.nextVisitDate;
    final String? visit = nextVisit == null
        ? null
        : Formatters.date(nextVisit.toLocal());

    return <Widget>[
      if (card.neverPaid)
        const AppStatusBadge(label: 'Never paid', tone: AppTone.warning),
      if (card.hasCommitment)
        AppStatusBadge(
          // A promise and the day it comes due are one fact, not two.
          label: visit == null ? 'Promised' : 'Promised · $visit',
          tone: AppTone.info,
        )
      else if (visit != null)
        AppStatusBadge(label: 'Visit $visit'),
      if (card.isSealed)
        AppStatusBadge(
          label: card.sealNo == null ? 'Sealed' : 'Sealed · ${card.sealNo}',
          tone: AppTone.danger,
        ),
      if (card.hasOpenCase) AppStatusBadge(label: 'Case #${card.openCaseId}'),
    ];
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.mobileNo, required this.dialer});

  final String mobileNo;
  final Dialer dialer;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Call',
      icon: Icons.phone_outlined,
      variant: AppButtonVariant.outline,
      fullWidth: false,
      height: 34,
      onPressed: () => dialer.call(mobileNo),
    );
  }
}
