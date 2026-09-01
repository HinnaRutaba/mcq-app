import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../controllers/api/fines_controller.dart';
import '../../../core/utils/get_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/widgets.dart';
import 'widgets/fine_tile.dart';
import 'widgets/stale_data_banner.dart';

/// Fines imposed in the officer's areas.
///
/// A fine awaiting somebody else's approval is not effective yet, and the
/// row says so rather than showing it as imposed.
class FinesScreen extends StatelessWidget {
  const FinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(FinesController.resolve);

    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(t('fines.title'))),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: () => controller.reload(refreshing: true),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
            children: [
              if (controller.isStale.value &&
                  controller.fetchedAt.value != null) ...[
                StaleDataBanner(
                  fetchedAt: controller.fetchedAt.value!,
                  onRetry: () => controller.reload(refreshing: true),
                ),
                const SizedBox(height: 16),
              ],
              if (controller.isLoading.value && controller.fines.isEmpty)
                // Skeletons, never a spinner: the shape of what is coming,
                // and how much of it.
                const AppSkeletonList(count: 4)
              else if (controller.hasFailed && controller.fines.isEmpty)
                AppBanner(
                  tone: AppStatusTone.danger,
                  icon: Icons.cloud_off_rounded,
                  message: controller.failure.value!.message,
                  action: AppButton(
                    label: t('common.retry'),
                    variant: AppButtonVariant.outline,
                    fullWidth: false,
                    height: 44,
                    onPressed: controller.reload,
                  ),
                )
              else if (controller.fines.isEmpty)
                AppEmptyState(
                  illustration: AppIllustrationKind.nothingToChase,
                  title: t('fines.empty'),
                  message: t('fines.emptyHelp'),
                )
              else
                for (final fine in controller.ordered)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
                    child: FineTile(
                      fine: fine,
                      onTap: fine.property.id == 0
                          ? null
                          : () => context.push(
                                AppRoutes.propertyProfilePath(fine.property.id),
                              ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
