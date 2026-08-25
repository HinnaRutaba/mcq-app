import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/tenant_home_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/get_helpers.dart';
import '../../data/mock/mock_seed.dart';
import '../../widgets/widgets.dart';
import 'widgets/chalaan_detail_sheet.dart';
import 'widgets/chalaan_tile.dart';
import 'widgets/payment_method_sheet.dart';
import 'widgets/recent_payment_tile.dart';

class TenantHomeScreen extends StatelessWidget {
  const TenantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => TenantHomeController());

    return Scaffold(
      body: Obx(() {
        final upcoming = controller.unpaid;
        final recent = controller.recentActivity;
        final nextDue = controller.nextDue;

        return RefreshIndicator(
          onRefresh: () async => controller.reload(),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              AppHeroHeader(
                subtitle: 'Welcome back',
                title: DemoIdentity.tenantName,
                trailing: const AppCircleIconButton(
                  icon: Icons.notifications_none_rounded,
                  badge: true,
                ),
                bottom: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.label('Total Due', color: Colors.white.withValues(alpha: 0.75)),
                    const SizedBox(height: 4),
                    AppText(
                      Formatters.currency(controller.totalDue),
                      variant: AppTextVariant.displaySmall,
                      color: Colors.white,
                    ),
                    if (controller.overdueCount > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: AppText.label(
                          '${controller.overdueCount} overdue — pay now to avoid extra charges',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppQuickAction(
                          icon: Icons.bolt_rounded,
                          label: 'Pay Now',
                          onTap: nextDue == null
                              ? null
                              : () => PaymentMethodSheet.show(
                                    context,
                                    chalaan: nextDue,
                                    onSettled: (_) => controller.reload(),
                                  ),
                        ),
                        AppQuickAction(
                          icon: Icons.receipt_long_rounded,
                          label: 'Payments',
                          onTap: () => context.go(AppRoutes.tenantPayments),
                        ),
                        AppQuickAction(
                          icon: Icons.bar_chart_rounded,
                          label: 'Overview',
                          onTap: () => _ChartSheet.show(context, controller),
                        ),
                        AppQuickAction(
                          icon: Icons.person_outline_rounded,
                          label: 'Profile',
                          onTap: () => context.go(AppRoutes.tenantProfile),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    AppText.titleMedium('Upcoming Payments (${upcoming.length})'),
                    const SizedBox(height: 12),
                    if (upcoming.isEmpty)
                      const AppEmptyState(
                        icon: Icons.task_alt_rounded,
                        title: 'Nothing due',
                        message: 'You\'re all caught up — no pending chalaans.',
                      )
                    else
                      for (final chalaan in upcoming) ...[
                        ChalaanTile(
                          chalaan: chalaan,
                          onTap: () => ChalaanDetailSheet.show(
                            context,
                            chalaan,
                            onPay: () => PaymentMethodSheet.show(
                              context,
                              chalaan: chalaan,
                              onSettled: (_) => controller.reload(),
                            ),
                          ),
                          onPay: () => PaymentMethodSheet.show(
                            context,
                            chalaan: chalaan,
                            onSettled: (_) => controller.reload(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: AppText.titleMedium('Past Payments')),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.tenantPayments),
                          child: const AppText.label('See all'),
                        ),
                      ],
                    ),
                    if (recent.isEmpty)
                      const AppEmptyState(
                        icon: Icons.history_rounded,
                        title: 'No history yet',
                        message: 'Your settled payments will show up here.',
                      )
                    else
                      AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Column(
                          children: [
                            for (var i = 0; i < recent.length; i++) ...[
                              RecentPaymentTile(
                                chalaan: recent[i],
                                onTap: () => ChalaanDetailSheet.show(context, recent[i]),
                              ),
                              if (i != recent.length - 1) const Divider(height: 1),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// "Overview" quick action opens the 6-month chart in a bottom sheet —
/// kept out of the main flow so it doesn't compete with Upcoming/Past.
class _ChartSheet {
  static Future<void> show(BuildContext context, TenantHomeController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
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
              const AppText.titleMedium('Payment Overview'),
              const SizedBox(height: 4),
              const AppText.caption('Paid vs due, last 6 months'),
              const SizedBox(height: 16),
              AppBarChart(data: controller.monthlyChartData),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
