import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../controllers/magistrate_home_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/get_helpers.dart';
import '../../data/mock/mock_seed.dart';
import '../../widgets/widgets.dart';
import 'widgets/collection_tile.dart';

class MagistrateHomeScreen extends StatelessWidget {
  const MagistrateHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => MagistrateHomeController());

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final readyToUnseal = controller.readyToUnseal;
          final priority = controller.priorityCollections;

          return RefreshIndicator(
            onRefresh: () async => controller.reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                const AppText.body('Saddar Town'),
                const SizedBox(height: 2),
                AppText.headlineMedium('Inspector ${DemoIdentity.magistrateName}'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppStatTile(
                        label: 'Pending Amount',
                        value: Formatters.currency(controller.totalPendingAmount),
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
                        label: 'Sealed',
                        value: '${controller.sealedCount}',
                        icon: Icons.lock_outline_rounded,
                      ),
                    ),
                  ],
                ),
                if (readyToUnseal.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.go(AppRoutes.magistrateSealed),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, color: AppColors.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  '${readyToUnseal.length} shop${readyToUnseal.length == 1 ? '' : 's'} ready to unseal',
                                  variant: AppTextVariant.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                const AppText.caption('Fine paid — seal can now be removed'),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.warning),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: AppText.titleMedium("Today's Priority Collections")),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.magistrateCollections),
                      child: const AppText.label('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (priority.isEmpty)
                  const AppEmptyState(
                    icon: Icons.task_alt_rounded,
                    title: 'All caught up',
                    message: 'No outstanding collections right now.',
                  )
                else
                  for (final chalaan in priority) ...[
                    CollectionTile(
                      chalaan: chalaan,
                      onTap: () => context.push(AppRoutes.collectionDetailPath(chalaan.id)),
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
