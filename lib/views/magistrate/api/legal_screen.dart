import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/api/legal_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/get_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/widgets.dart';
import 'widgets/api_enum_badge.dart';

/// Court cases and the hearing diary. Read only.
///
/// The cases with a live stay come first: an officer planning a round needs
/// to know which shutters not to walk to, because enforcement on those
/// properties is suspended.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(LegalController.resolve);

    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(t('legal.title'))),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: () => controller.reload(refreshing: true),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
            children: [
              AppBanner(
                tone: AppStatusTone.neutral,
                icon: Icons.lock_outline_rounded,
                message: t('legal.readOnly'),
              ),
              const SizedBox(height: 16),
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
                  illustration: AppIllustrationKind.nothingToChase,
                  title: t('legal.empty'),
                  message: t('legal.emptyHelp'),
                )
              else ...[
                for (final legalCase in [
                  ...controller.stayed,
                  ...controller.cases
                      .where((item) => !item.hasLiveStay),
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AppText.titleMedium(
                                  legalCase.caseNo,
                                  maxLines: 1,
                                ),
                              ),
                              ApiEnumBadge(legalCase.status),
                            ],
                          ),
                          if ((legalCase.subject ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            UserText.body(legalCase.subject, maxLines: 2),
                          ],
                          const SizedBox(height: 8),
                          AppText.caption(
                            [
                              legalCase.property.label,
                              legalCase.property.areaName,
                              if ((legalCase.court ?? '').isNotEmpty)
                                legalCase.court!,
                            ].where((part) => part.isNotEmpty).join(' · '),
                            maxLines: 2,
                          ),
                          if (legalCase.nextHearingDate != null) ...[
                            const SizedBox(height: 8),
                            AppText.caption(
                              t('legal.nextHearing', args: {
                                'date': Formatters.date(
                                    legalCase.nextHearingDate!),
                              }),
                            ),
                          ],
                          if (legalCase.hasLiveStay) ...[
                            const SizedBox(height: 12),
                            AppBanner(
                              tone: AppStatusTone.danger,
                              icon: Icons.pan_tool_outlined,
                              message: t('legal.stayLive'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (controller.diary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  AppText.titleMedium(t('legal.diary')),
                  const SizedBox(height: 12),
                  for (final hearing in controller.diary)
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
                      child: AppCard(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            14, 12, 14, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText.body(
                                    hearing.caseNo ?? t('legal.cases'),
                                    fontWeight: FontWeight.w600,
                                    maxLines: 1,
                                  ),
                                  if ((hearing.purpose ?? '').isNotEmpty)
                                    AppText.caption(hearing.purpose!,
                                        maxLines: 2),
                                ],
                              ),
                            ),
                            if (hearing.hearingDate != null)
                              AppText.caption(
                                Formatters.date(hearing.hearingDate!),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
