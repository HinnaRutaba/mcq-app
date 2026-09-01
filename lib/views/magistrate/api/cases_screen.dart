import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../controllers/api/cases_controller.dart';
import '../../../core/utils/get_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/widgets.dart';
import 'widgets/case_tile.dart';
import 'widgets/stale_data_banner.dart';

/// Enforcement cases in the officer's areas, visit-overdue first — that is
/// the queue.
class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key, this.assignedToMe = false});

  /// True when the officer came from the "Assigned to you" beat tile.
  final bool assignedToMe;

  @override
  Widget build(BuildContext context) {
    // Two lists, two controllers: "every case in my areas" and "the ones
    // the taxation branch sent me" answer different questions and must not
    // overwrite each other's rows.
    final controller = assignedToMe
        ? Get.put(
            CasesController.resolve(assignedToMe: true),
            tag: 'cases-assigned',
            permanent: false,
          )
        : getOrPut(CasesController.resolve);

    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge(
          assignedToMe ? t('cases.assignedTitle') : t('cases.title'),
        ),
        centerTitle: false,
      ),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: () => controller.reload(refreshing: true),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 32),
            children: [
              if (controller.isStale.value &&
                  controller.fetchedAt.value != null) ...[
                StaleDataBanner(
                  fetchedAt: controller.fetchedAt.value!,
                  onRetry: () => controller.reload(refreshing: true),
                ),
                const SizedBox(height: 16),
              ],
              // MCQ asked for taxation-branch cases to arrive in the app.
              // They must be visibly *from* somewhere, not just another row.
              if (assignedToMe) ...[
                AppBanner(
                  tone: AppStatusTone.info,
                  icon: Icons.assignment_ind_rounded,
                  title: t('cases.assignedBadge'),
                  message: t('cases.assignedHelp'),
                ),
                const SizedBox(height: 16),
              ],
              AppChipTabs<CaseFilter>(
                items: CaseFilter.values,
                itemLabel: (item) => t(item.labelKey),
                selected: controller.filter.value,
                onChanged: controller.setFilter,
              ),
              const SizedBox(height: 18),
              if (controller.isLoading.value && controller.cases.isEmpty)
                // Skeletons, never a spinner: the shape of what is coming,
                // and how much of it.
                const AppSkeletonList(count: 4)
              else if (controller.hasFailed && controller.cases.isEmpty)
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
              else if (controller.cases.isEmpty)
                AppEmptyState(
                  illustration: AppIllustrationKind.allClear,
                  title: assignedToMe ? t('cases.noneAssigned') : t('cases.empty'),
                  message: assignedToMe
                      ? t('cases.noneAssignedHelp')
                      : t('cases.emptyHelp'),
                )
              else ...[
                for (final item in controller.cases) ...[
                  CaseTile(
                    enforcementCase: item,
                    onTap: () =>
                        context.push(AppRoutes.caseDetailPath(item.id)),
                  ),
                  const SizedBox(height: 12),
                ],
                if (controller.hasMore.value)
                  AppButton(
                    label: t('common.seeAll'),
                    variant: AppButtonVariant.outline,
                    isLoading: controller.isRefreshing.value,
                    onPressed: controller.loadMore,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
