import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/dialer.dart';
import '../../../controllers/field/follow_ups_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/field/follow_up.dart';
import '../../../widgets/widgets.dart';
import 'widgets/field_actions.dart';
import 'widgets/field_list_view.dart';
import 'widgets/follow_up_card.dart';

/// Promises to chase — the queue that did not exist.
///
/// A promise taken and never chased is worse than no promise at all: the
/// officer has spent his authority and got nothing back for it. This is
/// where the promises he took come home.
class FollowUpsScreen extends StatefulWidget {
  const FollowUpsScreen({super.key, this.initialState});

  /// `due` when the officer arrived from the home screen's "Promises to
  /// chase" tile.
  final String? initialState;

  @override
  State<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends State<FollowUpsScreen> {
  // Tagged by the state it opened on. A shared controller would show the
  // officer whatever tab he happened to leave open last time, under a
  // heading that says otherwise.
  late final String _tag = 'follow-ups-${widget.initialState ?? 'all'}';
  late final FollowUpsController _controller = Get.put(
    FollowUpsController.resolve(initialState: widget.initialState),
    tag: _tag,
  );

  @override
  void dispose() {
    Get.delete<FollowUpsController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(t('followUps.title'))),
      body: Obx(() {
        final sections = controller.sections;

        return FieldListView(
          isLoading: controller.isLoading.value,
          isEmpty: sections.isEmpty && !controller.isLoading.value,
          isStale: controller.isStale.value,
          fetchedAt: controller.fetchedAt.value,
          failureMessage: controller.failure.value?.message,
          onRefresh: () => controller.reload(refreshing: true),
          skeletonCount: 3,
          emptyState: AppEmptyState(
            illustration: AppIllustrationKind.nothingToChase,
            title: controller.state.value == FollowUpsController.stateDue
                ? t('followUps.noneDue')
                : t('followUps.none'),
            message: t('followUps.noneHelp'),
          ),
          header: [
            _StateTabs(controller: controller),
            const SizedBox(height: 16),
          ],
          children: [
            for (final section in sections) ...[
              _SectionHeader(state: section.key, count: section.value.length),
              for (var i = 0; i < section.value.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                AppStaggerIn(
                  index: i,
                  enabled: controller.isFirstLoad.value,
                  child: _card(context, controller, section.value[i]),
                ),
              ],
              const SizedBox(height: 22),
            ],
          ],
        );
      }),
    );
  }

  Widget _card(
    BuildContext context,
    FollowUpsController controller,
    FollowUp followUp,
  ) {
    return FollowUpCard(
      followUp: followUp,
      onTap: () => context.push(
        AppRoutes.propertyProfilePath(followUp.propertyId),
      ),
      onCall: followUp.isCallable ? () => Dialer.call(followUp.mobileNo) : null,
      // Escalation belongs on a broken promise and nowhere else. Somebody
      // has already been given a chance and has not taken it, and that is
      // what justifies the next step.
      onEscalate: followUp.state == FollowUpState.overdue
          ? () => FieldActions.show(
                context,
                target: ActionTarget(
                  propertyId: followUp.propertyId,
                  shopLabel: followUp.unitLabel,
                  allotteeName: followUp.allotteeName,
                  allotmentId: followUp.allotmentId,
                  caseId: followUp.caseId,
                ),
                onChanged: () => controller.reload(refreshing: true),
              )
          : null,
    );
  }
}

/// Everything · Due now · Upcoming.
class _StateTabs extends StatelessWidget {
  const _StateTabs({required this.controller});

  final FollowUpsController controller;

  @override
  Widget build(BuildContext context) {
    const options = <String, String>{
      '': 'followUps.tabAll',
      FollowUpsController.stateDue: 'followUps.tabDue',
      FollowUpsController.stateUpcoming: 'followUps.tabUpcoming',
    };

    return Obx(
      () => Row(
        children: [
          for (final entry in options.entries) ...[
            Expanded(
              child: AppPressable(
                onTap: () {
                  AppHaptics.select();
                  controller.stateChanged(entry.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: controller.state.value == entry.key
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.state.value == entry.key
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: AppText.label(
                    t(entry.value),
                    color: controller.state.value == entry.key
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                ),
              ),
            ),
            if (entry.key != FollowUpsController.stateUpcoming)
              const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// A sticky-feeling section header. Overdue first, always.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.state, required this.count});

  final FollowUpState state;
  final int count;

  AppTone get _tone {
    switch (state) {
      case FollowUpState.overdue:
        return AppTone.danger;
      case FollowUpState.dueToday:
        return AppTone.warning;
      case FollowUpState.upcoming:
        return AppTone.neutral;
    }
  }

  String get _titleKey {
    switch (state) {
      case FollowUpState.overdue:
        return 'followUps.sectionOverdue';
      case FollowUpState.dueToday:
        return 'followUps.sectionToday';
      case FollowUpState.upcoming:
        return 'followUps.sectionUpcoming';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colour = _tone.on(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 4, height: 18, color: colour),
          const SizedBox(width: 9),
          AppText.titleMedium(t(_titleKey), color: colour),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: AppText.caption('$count', color: colour),
          ),
        ],
      ),
    );
  }
}
