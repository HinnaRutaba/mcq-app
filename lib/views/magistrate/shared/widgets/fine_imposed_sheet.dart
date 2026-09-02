import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/fine.dart';
import '../../../../widgets/widgets.dart';
import '../../../../config/theme/app_radius.dart';

class FineImposedSheet extends StatelessWidget {
  const FineImposedSheet({super.key, required this.fine});

  final Fine fine;

  static Future<void> show(BuildContext context, {required Fine fine}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (BuildContext context) => FineImposedSheet(fine: fine),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final challan = fine.challan;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppTone.success.container(context),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: AppTone.success.on(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const AppText.titleLarge('Fine imposed'),
                    if (fine.fineNo != null) ...[
                      const SizedBox(height: 2),
                      AppText.caption(fine.fineNo!, color: muted),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // The server's own label for the offence, shown exactly as it sent
          // it — never re-worded on the handset.
          if (fine.fineType != null)
            _Line(label: 'Offence', value: fine.fineType!.label),
          if (fine.amounts.fineAmount != null)
            _Line(
              label: 'Amount',
              value: Formatters.money(fine.amounts.fineAmount) ?? '—',
            ),
          if (fine.status != null)
            _Line(label: 'Status', value: fine.status!.label),

          if (fine.requiresApproval) ...[
            const SizedBox(height: 14),
            AppAlert(
              tone: AppTone.warning,
              icon: Icons.pending_actions_rounded,
              message:
                  'This is above your field limit, so it does not take effect '
                  'until a senior approves it. Do not tell the shopkeeper it '
                  'is final.',
            ),
          ],

          if (challan != null) ...[
            const SizedBox(height: 18),
            const AppText.titleMedium('The bill'),
            const SizedBox(height: 8),
            if (challan.challanNo != null)
              _Line(label: 'Challan', value: challan.challanNo!),
            if (challan.balanceAmount != null)
              _Line(
                label: 'Balance',
                value: Formatters.money(challan.balanceAmount) ?? '—',
              ),
            if (challan.dueDate != null)
              _Line(label: 'Due', value: Formatters.date(challan.dueDate!)),
            if (challan.consumerNo != null)
              _ConsumerNumber(consumerNo: challan.consumerNo!),
            const SizedBox(height: 6),
            AppText.caption(
              challan.hasLiveLink
                  ? 'A payment link has been texted to the person fined.'
                  : 'No payment link is live on this bill yet.',
              color: muted,
            ),
          ],

          const SizedBox(height: 22),
          AppButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 96, child: AppText.body(label, color: muted)),
          Expanded(child: AppText.body(value, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// The number a shopkeeper reads out at a counter, so it is the one thing here
/// worth being able to copy.
class _ConsumerNumber extends StatelessWidget {
  const _ConsumerNumber({required this.consumerNo});

  final String consumerNo;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          SizedBox(width: 96, child: AppText.body('Consumer no', color: muted)),
          Expanded(
            child: AppText.body(consumerNo, fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: consumerNo));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: AppText.body('Consumer number copied')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }
}
