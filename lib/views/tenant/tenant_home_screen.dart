import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../controllers/tenant_home_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/get_helpers.dart';
import '../../data/mock/mock_seed.dart';
import '../../widgets/widgets.dart';
import 'widgets/chalaan_detail_sheet.dart';
import 'widgets/chalaan_tile.dart';
import 'widgets/payment_method_sheet.dart';

class TenantHomeScreen extends StatelessWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => TenantHomeController());

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final nextDue = controller.nextDue;
          final recent = controller.recentActivity;

          return RefreshIndicator(
            onRefresh: () async => controller.reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText.body('Welcome back'),
                          const SizedBox(height: 2),
                          AppText.headlineMedium(DemoIdentity.tenantName),
                        ],
                      ),
                    ),
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppStatTile(
                        label: 'Total Due',
                        value: Formatters.currency(controller.totalDue),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppStatTile(
                        label: 'Overdue',
                        value: '${controller.overdueCount}',
                        icon: Icons.error_outline_rounded,
                        valueColor: controller.overdueCount > 0 ? AppColors.error : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppStatTile(
                        label: 'Paid',
                        value: '${controller.paidCount}',
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.titleMedium('Payment Overview'),
                      const SizedBox(height: 4),
                      const AppText.caption('Paid vs due, last 6 months'),
                      const SizedBox(height: 16),
                      AppBarChart(data: controller.monthlyChartData),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (nextDue != null) ...[
                  const AppText.titleMedium('Upcoming'),
                  const SizedBox(height: 12),
                  ChalaanTile(
                    chalaan: nextDue,
                    onTap: () => ChalaanDetailSheet.show(
                      context,
                      nextDue,
                      onPay: () => PaymentMethodSheet.show(
                        context,
                        chalaan: nextDue,
                        onSettled: (_) => controller.reload(),
                      ),
                    ),
                    onPay: () => PaymentMethodSheet.show(
                      context,
                      chalaan: nextDue,
                      onSettled: (_) => controller.reload(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Row(
                  children: [
                    const Expanded(child: AppText.titleMedium('Recent Activity')),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.tenantPayments),
                      child: const AppText.label('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (recent.isEmpty)
                  const AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No activity yet',
                    message: 'Your payment history will show up here.',
                  )
                else
                  for (final chalaan in recent) ...[
                    ChalaanTile(
                      chalaan: chalaan,
                      onTap: () => ChalaanDetailSheet.show(context, chalaan),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          );
        }),
      ),
    );
  }
}
