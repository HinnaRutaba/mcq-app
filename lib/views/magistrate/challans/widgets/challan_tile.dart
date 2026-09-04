import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/dialer.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/challan.dart';
import '../../../../widgets/widgets.dart';


class ChallanTile extends StatelessWidget {
  const ChallanTile({
    super.key,
    required this.challan,
    this.onTap,
    this.dialer = const Dialer(),
  });

  final Challan challan;

  /// Opens the bill in full. Every row has one: the figures are already on
  /// the record behind the tile, so there is nothing to fetch and no row that
  /// cannot answer for itself.
  final VoidCallback? onTap;

  final Dialer dialer;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final String? where = _where;
    final String? note = _note;
    final String? mobileNo = _mobileNo;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: AppText.titleMedium(_name, maxLines: 1)),
              const SizedBox(width: 12),
              AppText.titleMedium(
                _figure,
                color: challan.isOverdue ? AppTone.danger.on(context) : null,
                maxLines: 1,
              ),
            ],
          ),
          if (where != null) ...<Widget>[
            const SizedBox(height: 3),
            AppText.body(where, maxLines: 1),
          ],
          if (note != null) ...<Widget>[
            const SizedBox(height: 4),
            AppText.caption(note, color: muted, maxLines: 1),
          ],
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Wrap(spacing: 6, runSpacing: 6, children: _badges()),
              ),
              if (mobileNo != null) ...<Widget>[
                const SizedBox(width: 8),
                AppButton(
                  label: 'Call',
                  icon: Icons.phone_outlined,
                  variant: AppButtonVariant.outline,
                  fullWidth: false,
                  height: 34,
                  onPressed: () => dialer.call(mobileNo),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// The holder, or whoever the bill was addressed to — a fine can be raised
  /// against somebody who is not on the register, and then `payer_name` is the
  /// only name on it.
  String get _name =>
      challan.allottee?.fullName ??
      challan.payerName ??
      challan.property?.displayName ??
      'Unnamed';

  String? get _mobileNo => challan.allottee?.mobileNo ?? challan.payerMobileNo;

  /// The shop, then the bazaar — dropped when the name above is already it.
  String? get _where {
    final String? unit = challan.property?.displayName;
    if (unit != null && unit != _name) return unit;
    return challan.area?.name;
  }

  /// What the officer reads out: the challan number, the month it covers, and
  /// when it was due.
  String? get _note {
    final List<String> parts = <String>[
      ?challan.challanNo,
      ?challan.billingPeriod?.periodCode,
      if (challan.dueDate != null)
        'due ${Formatters.date(challan.dueDate!.toLocal())}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// What is due today, after any deferral. Falls back to the balance where
  /// the server sent no `payable_now`.
  String get _figure =>
      Formatters.money(challan.amounts.payableNow) ??
      Formatters.money(challan.amounts.balanceAmount) ??
      '—';

  List<Widget> _badges() => <Widget>[
    if (challan.status != null)
      AppStatusBadge(
        // The server owns this wording, and new statuses arrive without an
        // app release.
        label: challan.status!.label,
        tone: AppToneColors.fromApi(challan.status!.tone),
      ),
    if (challan.isFine)
      // Neutral on purpose: the status pill beside it already carries the
      // urgency, and three coloured pills on one row read as three alarms.
      const AppStatusBadge(label: 'Fine', icon: Icons.gavel_rounded),
    if (challan.isOverdue && challan.daysOverdue > 0)
      AppStatusBadge(
        label:
            '${challan.daysOverdue} '
            '${challan.daysOverdue == 1 ? 'day' : 'days'} overdue',
        tone: AppTone.danger,
        icon: Icons.schedule_rounded,
      ),
    if (challan.hasLiveLink)
      const AppStatusBadge(
        // Worth saying only while it still works — an expired link shared at a
        // doorstep is worse than none.
        label: 'Link live',
        tone: AppTone.info,
        icon: Icons.link_rounded,
      ),
  ];
}
