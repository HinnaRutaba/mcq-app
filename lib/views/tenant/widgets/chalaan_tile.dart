import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_style.dart';
import '../../../models/chalaan.dart';
import '../../../widgets/widgets.dart';

/// A single chalaan/fine list item — used on both the Tenant Home
/// (nearest-due) and Payments screens.
class ChalaanTile extends StatelessWidget {
  const ChalaanTile({super.key, required this.chalaan, this.onTap, this.onPay});

  final Chalaan chalaan;
  final VoidCallback? onTap;
  final VoidCallback? onPay;

  bool get _canPay =>
      chalaan.status == ChalaanStatus.upcoming || chalaan.status == ChalaanStatus.overdue;

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
                child: AppText.titleMedium(chalaan.description ?? chalaan.type.label, maxLines: 1),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: chalaan.status.label,
                tone: StatusStyle.chalaanTone(chalaan.status),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppText.caption(chalaan.propertyName, maxLines: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              AppText.titleLarge(Formatters.currency(chalaan.amount)),
              const Spacer(),
              AppText.caption(
                chalaan.isSettled
                    ? 'Paid ${Formatters.date(chalaan.paidDate!)}'
                    : Formatters.dueIn(chalaan.dueDate),
                color: chalaan.status == ChalaanStatus.overdue ? AppColors.error : null,
              ),
            ],
          ),
          if (_canPay && onPay != null) ...[
            const SizedBox(height: 12),
            AppButton(label: 'Pay Now', height: 42, onPressed: onPay),
          ],
        ],
      ),
    );
  }
}
