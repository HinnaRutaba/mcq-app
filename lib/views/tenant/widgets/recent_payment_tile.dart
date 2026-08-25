import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/chalaan.dart';
import '../../../widgets/widgets.dart';

/// A compact, lower-visual-weight row for settled/pending-verification
/// chalaans — deliberately plainer than [ChalaanTile] so "Past Payments"
/// reads as lower priority than the bold "Upcoming Payments" cards.
class RecentPaymentTile extends StatelessWidget {
  const RecentPaymentTile({super.key, required this.chalaan, this.onTap});

  final Chalaan chalaan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isPending = chalaan.status == ChalaanStatus.pendingVerification;
    final tint = isPending ? AppColors.warning : AppColors.success;
    final icon = isPending ? Icons.hourglass_top_rounded : Icons.check_rounded;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(color: tint.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    chalaan.description ?? chalaan.type.label,
                    variant: AppTextVariant.titleSmall,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  AppText.caption(
                    isPending ? 'Pending verification' : Formatters.date(chalaan.paidDate!),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppText(Formatters.currency(chalaan.amount), variant: AppTextVariant.titleSmall),
          ],
        ),
      ),
    );
  }
}
