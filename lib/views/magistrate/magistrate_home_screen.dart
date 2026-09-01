import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../controllers/magistrate_home_controller.dart';
import '../../controllers/seal_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/get_helpers.dart';
import '../../data/mock/mock_seed.dart';
import '../../widgets/widgets.dart';
import 'widgets/collection_tile.dart';
import 'widgets/seal_tile.dart';

class MagistrateHomeScreen extends StatelessWidget {
  const MagistrateHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => MagistrateHomeController());
    final sealController = Get.find<SealController>();

    return Scaffold(
      body: Obx(() {
        final unpaidFines = controller.unpaidFines;
        final pendingCollections = controller.pendingCollections;
        final readyToUnseal = controller.readyToUnseal;

        return RefreshIndicator(
          onRefresh: () async => controller.reload(),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              AppHeroHeader(
                subtitle: DemoIdentity.magistrateJurisdiction,
                title: 'Inspector ${DemoIdentity.magistrateName}',
                trailing: AppCircleIconButton(
                  icon: Icons.notifications_none_rounded,
                  badge: readyToUnseal.isNotEmpty,
                ),
                bottom: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.label(
                      'Pending Amount',
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      Formatters.currency(controller.totalPendingAmount),
                      variant: AppTextVariant.displaySmall,
                      color: Colors.white,
                    ),
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
                          icon: Icons.add_circle_outline_rounded,
                          label: 'New Entry',
                          onTap: () => context.push(AppRoutes.createChalaan),
                        ),
                        AppQuickAction(
                          icon: Icons.location_on_outlined,
                          label: 'Collections',
                          onTap: () =>
                              context.go(AppRoutes.magistrateCollections),
                        ),
                        AppQuickAction(
                          icon: Icons.lock_outline_rounded,
                          label: 'Sealed',
                          onTap: () => context.go(AppRoutes.magistrateSealed),
                        ),
                        AppQuickAction(
                          icon: Icons.person_outline_rounded,
                          label: 'Profile',
                          onTap: () => context.go(AppRoutes.magistrateProfile),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // --- Priority 1: unpaid fines --------------------------
                    Row(
                      children: [
                        const Icon(
                          Icons.gavel_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        AppText.titleMedium(
                          'Unpaid Fines (${unpaidFines.length})',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const AppText.caption(
                      'Tenants who haven\'t settled a fine yet',
                    ),
                    const SizedBox(height: 12),
                    if (unpaidFines.isEmpty)
                      const AppEmptyState(
                        illustration: AppIllustrationKind.allClear,
                        title: 'No unpaid fines',
                        message: 'Every issued fine has been settled.',
                      )
                    else
                      for (final chalaan in unpaidFines) ...[
                        CollectionTile(
                          chalaan: chalaan,
                          onTap: () => context.push(
                            AppRoutes.collectionDetailPath(chalaan.id),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 24),

                    // --- Priority 2: pending collections -------------------
                    Row(
                      children: [
                        const Expanded(
                          child: AppText.titleMedium('Pending Collections'),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.go(AppRoutes.magistrateCollections),
                          child: const AppText.label('See all'),
                        ),
                      ],
                    ),
                    const AppText.caption(
                      'Chalaans coming due across your jurisdiction',
                    ),
                    const SizedBox(height: 12),
                    if (pendingCollections.isEmpty)
                      const AppEmptyState(
                        illustration: AppIllustrationKind.allClear,
                        title: 'All caught up',
                        message: 'No outstanding collections right now.',
                      )
                    else
                      for (final chalaan in pendingCollections.take(5)) ...[
                        CollectionTile(
                          chalaan: chalaan,
                          onTap: () => context.push(
                            AppRoutes.collectionDetailPath(chalaan.id),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 24),

                    // --- Priority 3: fines paid, ready to unseal -----------
                    Row(
                      children: [
                        const Expanded(
                          child: AppText.titleMedium('Ready to Unseal'),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.go(AppRoutes.magistrateSealed),
                          child: const AppText.label('See all'),
                        ),
                      ],
                    ),
                    const AppText.caption(
                      'Fine paid — seal can now be removed',
                    ),
                    const SizedBox(height: 12),
                    if (readyToUnseal.isEmpty)
                      const AppEmptyState(
                        illustration: AppIllustrationKind.shopSealed,
                        title: 'Nothing to unseal',
                        message:
                            'Sealed shops will appear here once their fine is paid.',
                      )
                    else
                      for (final seal in readyToUnseal) ...[
                        SealTile(
                          seal: seal,
                          isProcessing: sealController.isProcessing.value,
                          onRemove: () => sealController.removeSeal(seal.id),
                        ),
                        const SizedBox(height: 12),
                      ],
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
