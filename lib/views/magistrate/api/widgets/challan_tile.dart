import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/billing/challan.dart';
import '../../../../widgets/widgets.dart';
import 'api_enum_badge.dart';

/// A challan — the monthly bill, or a fine's own bill.
///
/// Every challan says what kind it is and this shows it: a 3,000 fine and a
/// 3,000 rent bill are indistinguishable by amount, and the officer is
/// often standing in front of the person being billed.
///
/// **There is deliberately no charge breakdown here.** A fine challan is a
/// single charge with no billing period, and drawing it with rent labels —
/// "This month", "Previous rent pending", "Late payment fine 0.00" — is
/// meaningless on a penalty and reads as the fine being nothing. Rather
/// than branching on `is_single_charge`, this tile draws the total, the
/// server's own type label and the payment link, which is true of both
/// kinds. If a breakdown is ever wanted, it must branch on
/// `is_single_charge` and print no month on a fine.
class ChallanTile extends StatelessWidget {
  const ChallanTile({super.key, required this.challan});

  final Challan challan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText.titleMedium(
                  t('challan.no', args: {'no': challan.challanNo}),
                  maxLines: 1,
                ),
              ),
              MoneyText.row(challan.payableNow ?? challan.total),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // The server's own label for the kind of bill. Never mapped
              // to strings of our own.
              ApiEnumBadge(challan.challanType),
              ApiEnumBadge(challan.status),
              if (challan.dueDate != null)
                AppText.caption(
                  t('challan.dueOn',
                      args: {'date': Formatters.date(challan.dueDate!)}),
                ),
            ],
          ),
          if (challan.hasPayLink) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: AppText.caption(
                    challan.consumerNo == null
                        ? t('challan.payable')
                        : '${t('challan.payable')} · ${challan.consumerNo}',
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
