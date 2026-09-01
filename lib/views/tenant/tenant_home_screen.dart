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
                    AppText.label(
                      'Total Due',
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      Formatters.currency(controller.totalDue),
                      variant: AppTextVariant.displaySmall,
                      color: Colors.white,
                    ),
                    if (controller.overdueCount > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
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
                    AppSectionHeader(
                      title: 'Upcoming payments',
                      subtitle: upcoming.isEmpty
                          ? null
                          : '${upcoming.length} waiting',
                      icon: Icons.event_note_rounded,
                    ),
                    if (upcoming.isEmpty)
                      const AppEmptyState(
                        // A zero here is good news, and it has to look
                        // like good news rather than like a blank list.
                        illustration: AppIllustrationKind.allClear,
                        title: 'Nothing due',
                        message: 'You\'re all caught up — no pending chalaans.',
                        compact: true,
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
                    AppSectionHeader(
                      title: 'Past payments',
                      icon: Icons.history_rounded,
                      actionLabel: 'See all',
                      onAction: () => context.go(AppRoutes.tenantPayments),
                    ),
                    if (recent.isEmpty)
                      const AppEmptyState(
                        illustration: AppIllustrationKind.nothingToChase,
                        title: 'No history yet',
                        message: 'Your settled payments will show up here.',
                        compact: true,
                      )
                    else
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < recent.length; i++) ...[
                              RecentPaymentTile(
                                chalaan: recent[i],
                                onTap: () =>
                                    ChalaanDetailSheet.show(context, recent[i]),
                              ),
                              if (i != recent.length - 1)
                                const Divider(height: 1),
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
  static Future<void> show(
    BuildContext context,
    TenantHomeController controller,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Paid against due is a pair of *states*, so it wears the
            // reserved status colours rather than a categorical palette,
            // and each one carries an icon and a word in the legend.
            AppPaidDueChart(
              title: 'Payment overview',
              subtitle: 'Paid against due, last 6 months',
              data: controller.monthlyChartData,
            ),
          ],
        ),
      ),
    );
  }
}
