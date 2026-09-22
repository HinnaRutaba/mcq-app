import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/dialer.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/unit_card.dart';
import '../../../../widgets/widgets.dart';

/// One unit on the search list.
///
/// Close kin of `DefaulterTile`, and deliberately not it: this list carries
/// the shops that owe nothing and the ones nobody holds, neither of which a
/// defaulter row can say — and it has no "months behind" to put where the
/// arrears go.
class UnitTile extends StatelessWidget {
  const UnitTile({
    super.key,
    required this.card,
    this.onTap,
    this.dialer = const Dialer(),
  });

  final UnitCard card;

  final VoidCallback? onTap;

  final Dialer dialer;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final String? owed = _owed;
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
                  card.allotteeName ??
                      (card.isVacant ? 'Vacant' : 'No holder on record'),
                  maxLines: 1,
                ),
              ),
              if (owed != null) ...<Widget>[
                const SizedBox(width: 12),
                AppText.titleMedium(owed, maxLines: 1),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: <Widget>[
              Expanded(child: AppText.body(_unit, maxLines: 1)),
              if (owed == null) ...<Widget>[
                const SizedBox(width: 12),
                // Said out loud, because a blank where the arrears go reads as
                // a figure that failed to arrive.
                AppText.caption('Paid up', color: muted, maxLines: 1),
              ],
            ],
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: 4),
            AppText.caption(note, color: muted, maxLines: 1),
          ],
          if (badges.isNotEmpty || mobileNo != null) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Wrap(spacing: 6, runSpacing: 6, children: badges),
                ),
                if (mobileNo != null) ...<Widget>[
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

  /// The shop and where it stands — the line that finds it in a bazaar.
  String get _unit {
    final String unit =
        card.shopNo ?? card.propertyCode ?? card.allotmentNo ?? 'Unit';
    final String? place = card.marketName ?? card.areaName;
    return place == null ? unit : '$unit · $place';
  }

  /// Rent arrears, and nothing where there are none: a unit that is paid up
  /// owes no figure, and "Rs 0" beside a holder's name reads as a debt.
  String? get _owed {
    final num? value = num.tryParse(card.outstanding.trim());
    if (value != null && value <= 0) return null;
    return Formatters.money(card.outstanding);
  }

  String? _note() {
    final DateTime? lastPaid = card.lastPaymentDate;
    final List<String> parts = <String>[
      if (card.propertyCode != null) card.propertyCode!,
      if (lastPaid != null) 'last paid ${Formatters.date(lastPaid.toLocal())}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  List<Widget> _badges() => <Widget>[
    if (card.isVacant)
      const AppStatusBadge(label: 'Vacant', tone: AppTone.info),
    if (card.isSealed)
      AppStatusBadge(
        label: card.sealNo == null ? 'Sealed' : 'Sealed · ${card.sealNo}',
        tone: AppTone.danger,
      ),
    if (card.hasOpenCase) AppStatusBadge(label: 'Case #${card.openCaseId}'),
  ];
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
