import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_style.dart';
import '../../../models/chalaan.dart';
import '../../../widgets/widgets.dart';

/// Full-detail bottom sheet for a single chalaan, with a "Pay Now" action
/// when it's still outstanding.
class ChalaanDetailSheet extends StatelessWidget {
  const ChalaanDetailSheet({super.key, required this.chalaan, this.onPay});

  final Chalaan chalaan;
  final VoidCallback? onPay;

  static Future<void> show(BuildContext context, Chalaan chalaan, {VoidCallback? onPay}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChalaanDetailSheet(chalaan: chalaan, onPay: onPay),
    );
  }

  bool get _canPay =>
      chalaan.status == ChalaanStatus.upcoming || chalaan.status == ChalaanStatus.overdue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppText.headlineSmall(chalaan.description ?? chalaan.type.label),
                ),
                AppStatusBadge(
                  label: chalaan.status.label,
                  tone: StatusStyle.chalaanTone(chalaan.status),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AppText.body(chalaan.propertyName),
            const SizedBox(height: 20),
            _DetailRow(label: 'Chalaan ID', value: chalaan.id),
            _DetailRow(label: 'Type', value: chalaan.type.label),
            _DetailRow(label: 'Amount', value: Formatters.currency(chalaan.amount)),
            _DetailRow(label: 'Issued', value: Formatters.date(chalaan.issueDate)),
            _DetailRow(label: 'Due', value: Formatters.date(chalaan.dueDate)),
            if (chalaan.paidDate != null)
              _DetailRow(label: 'Paid on', value: Formatters.date(chalaan.paidDate!)),
            if (chalaan.method != null)
              _DetailRow(label: 'Method', value: chalaan.method!.label),
            if (chalaan.referenceNumber != null)
              _DetailRow(label: 'Reference', value: chalaan.referenceNumber!),
            if (_canPay && onPay != null) ...[
              const SizedBox(height: 16),
              AppButton(
                label: 'Pay Now',
                onPressed: () {
                  Navigator.pop(context);
                  onPay!();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: AppText.body(label)),
          AppText(value, variant: AppTextVariant.titleSmall),
        ],
      ),
    );
  }
}
