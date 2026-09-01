import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../controllers/api/case_detail_controller.dart';
import '../../../core/utils/dialer.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/enforcement/enforcement_case.dart';
import '../../../widgets/widgets.dart';
import 'widgets/action_timeline_tile.dart';
import 'widgets/api_enum_badge.dart';
import 'widgets/detail_row.dart';

/// One enforcement case: the header, the timeline, and what can be done.
///
/// Every action button is driven by the case's own `can_*` flag and the
/// officer's permission. A button that is offered and then refused is worse
/// than one that is absent, because the officer is standing in front of a
/// shopkeeper when it fails.
class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final int caseId;

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  late final String _tag = 'case-${widget.caseId}';
  late final CaseDetailController _controller = Get.put(
    CaseDetailController.resolve(widget.caseId),
    tag: _tag,
  );

  @override
  void dispose() {
    Get.delete<CaseDetailController>(tag: _tag);
    super.dispose();
  }

  Future<void> _closeCase() async {
    final remarks = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText.titleLarge(t('cases.closeCase')),
        content: AppTextField(
          label: t('cases.closingRemarks'),
          controller: remarks,
          maxLines: 3,
        ),
        actionsPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        actions: [
          Column(
            children: [
              AppButton(
                label: t('cases.closeCase'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: t('common.cancel'),
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.closeCase(remarks.text.trim());
    }
    remarks.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(t('cases.title'))),
      body: Obx(() {
        final item = _controller.enforcementCase.value;

        if (item == null) {
          if (_controller.isLoading.value) {
            // The shape of the page, not a spinner in the middle of it.
            return const Padding(
              padding: EdgeInsets.all(18),
              child: AppSkeletonList(count: 3),
            );
          }
          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
            child: AppBanner(
              tone: AppStatusTone.danger,
              icon: Icons.cloud_off_rounded,
              message: _controller.failure.value?.message ?? t('error.unexpected'),
              action: AppButton(
                label: t('common.retry'),
                variant: AppButtonVariant.outline,
                fullWidth: false,
                height: 44,
                onPressed: _controller.reload,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _controller.reload(refreshing: true),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 40),
            children: [
              _header(context, item),
              const SizedBox(height: 16),

              // A stay order stops enforcement. Say so before the officer
              // walks to the shop, not after the server refuses the seal.
              if (_controller.hasLiveStay.value) ...[
                AppBanner(
                  tone: AppStatusTone.danger,
                  icon: Icons.gavel_rounded,
                  message: t('cases.stayOrderWarning'),
                ),
                const SizedBox(height: 16),
              ],

              if (item.visitOverdue) ...[
                AppBanner(
                  tone: AppStatusTone.warning,
                  icon: Icons.schedule_rounded,
                  message: t('cases.visitOverdue'),
                ),
                const SizedBox(height: 16),
              ],

              _actions(context, item),
              const SizedBox(height: 28),

              AppText.titleMedium(t('cases.timeline')),
              const SizedBox(height: 12),
              if (_controller.timeline.isEmpty)
                AppEmptyState(
                  illustration: AppIllustrationKind.nothingToChase,
                  title: t('cases.timelineEmpty'),
                  message: t('cases.timelineEmptyHelp'),
                )
              else
                for (final action in _controller.timeline) ...[
                  ActionTimelineTile(action: action),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      }),
    );
  }

  Widget _header(BuildContext context, EnforcementCase item) {
    final owed = item.outstanding;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserText.name(item.allottee.name),
                    const SizedBox(height: 2),
                    AppText.caption(
                      '${item.property.label} · ${item.property.areaName}',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              if (item.allottee.isCallable)
                IconButton(
                  tooltip: t('common.call'),
                  onPressed: () => Dialer.call(item.allottee.mobileNo),
                  icon: const Icon(Icons.call_rounded),
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ApiEnumBadge(item.status),
              ApiEnumBadge(item.priority),
              if (item.isSealed)
                AppStatusBadge(
                  label: t('cases.sealed'),
                  tone: AppStatusTone.neutral,
                ),
            ],
          ),
          Divider(height: 24, color: Theme.of(context).dividerColor),
          DetailRow(
            label: t('cases.caseNoLabel'),
            value: item.caseNo,
          ),
          if (owed != null)
            DetailRow(
              label: t('defaulters.outstanding'),
              valueWidget: MoneyText.row(owed),
            ),
          // Every other amount the server put on the case, under the key it
          // used. Nothing here is added up on the device.
          for (final entry in item.amounts.entries)
            if (entry.key != 'outstanding')
              DetailRow(
                label: entry.key.replaceAll('_', ' '),
                valueWidget: MoneyText.small(entry.value, withSymbol: true),
              ),
          DetailRow(
            label: t('cases.unpaidMonthsLabel'),
            value: '${item.unpaidMonths}',
          ),
          DetailRow(
            label: t('cases.nextVisitLabel'),
            value: item.nextVisitDate == null
                ? t('cases.noNextVisit')
                : Formatters.date(item.nextVisitDate!),
          ),
          if (item.openedOn != null)
            DetailRow(
              label: t('cases.openedOnLabel'),
              value: Formatters.date(item.openedOn!),
            ),
          if (item.closedOn != null)
            DetailRow(
              label: t('cases.closedOnLabel'),
              value: Formatters.date(item.closedOn!),
            ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, EnforcementCase item) {
    final buttons = <Widget>[];

    if (_controller.canRecordAction) {
      buttons.add(
        AppButton(
          label: t('cases.recordAction'),
          icon: Icons.edit_note_rounded,
          onPressed: () => context.push(AppRoutes.recordActionPath(item.id)),
        ),
      );
    }
    if (_controller.canSeal) {
      buttons.add(
        AppButton(
          label: t('cases.sealShop'),
          icon: Icons.lock_rounded,
          variant: AppButtonVariant.danger,
          onPressed: () => context.push(AppRoutes.sealCasePath(item.id)),
        ),
      );
    }
    if (_controller.canRelease) {
      buttons.add(
        AppButton(
          label: t('cases.releaseSeal'),
          icon: Icons.lock_open_rounded,
          variant: AppButtonVariant.outline,
          onPressed: () =>
              context.push(AppRoutes.releaseSealPath(item.sealId!)),
        ),
      );
    }
    if (_controller.canFine) {
      buttons.add(
        AppButton(
          label: t('cases.imposeFine'),
          icon: Icons.gavel_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: () =>
              context.push(AppRoutes.imposeFinePath(item.property.id)),
        ),
      );
    }
    if (_controller.canClose) {
      buttons.add(
        AppButton(
          label: t('cases.closeCase'),
          variant: AppButtonVariant.ghost,
          isLoading: _controller.isClosing.value,
          onPressed: _closeCase,
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final button in buttons)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
            child: button,
          ),
      ],
    );
  }
}
