import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme/app_colors.dart';
import '../../../controllers/field/activity_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/get_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/field/field_activity.dart';
import '../../../widgets/widgets.dart';
import 'widgets/activity_summary_card.dart';
import 'widgets/field_list_view.dart';

/// "My work" — the report that makes an officer trust the app.
///
/// There was no way for a field officer to see his own work, and that is a
/// real gap rather than a nicety. Recovery is slow, unglamorous and mostly
/// invisible; an officer who cannot see that thirty visits sat behind four
/// hundred thousand rupees has no reason to believe the visits matter.
///
/// Three views of the same period, in the order the question is asked:
/// **how much** (four counts and the money), **what of** (the donut), and
/// **which actions** (the ranked bars).
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(ActivityController.resolve);

    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(t('activity.title'))),
      body: Obx(() {
        final activity = controller.activity.value;
        final animate = controller.isFirstLoad.value;

        return FieldListView(
          isLoading: controller.isLoading.value,
          isEmpty: activity == null && !controller.isLoading.value,
          isStale: controller.isStale.value,
          fetchedAt: controller.fetchedAt.value,
          failureMessage: controller.failure.value?.message,
          onRefresh: () => controller.reload(refreshing: true),
          skeletonCount: 2,
          header: [
            _PeriodPicker(controller: controller),
            const SizedBox(height: 18),
          ],
          emptyState: AppEmptyState(
            illustration: AppIllustrationKind.allClear,
            title: t('activity.empty'),
            message: t('activity.emptyHelp'),
          ),
          children: activity == null
              ? const []
              : [
                  if (activity.since != null) ...[
                    AppText.bodySmall(
                      t('activity.since',
                          args: {'date': Formatters.date(activity.since!)}),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _Headline(activity: activity, animate: animate),
                  const SizedBox(height: 20),
                  if (activity.collectedInAreas != null) ...[
                    _Collected(activity: activity),
                    const SizedBox(height: 20),
                  ],
                  if (activity.byActionType.isNotEmpty) ...[
                    ActivityShareDonut(activity: activity),
                    const SizedBox(height: 20),
                    _Breakdown(activity: activity, animate: animate),
                  ],
                ],
        );
      }),
    );
  }
}

/// Seven days, thirty, ninety.
class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.controller});

  final ActivityController controller;

  @override
  Widget build(BuildContext context) {
    // A segmented button, because these are three mutually exclusive views
    // of one thing rather than three filters — and it is the control
    // Material has for exactly that.
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          segments: [
            for (final period in FieldActivity.periods)
              ButtonSegment<int>(
                value: period,
                label: Text(t('activity.days', args: {'n': '$period'})),
              ),
          ],
          selected: {controller.days.value},
          showSelectedIcon: false,
          onSelectionChanged: (selection) {
            AppHaptics.select();
            controller.periodChanged(selection.first);
          },
        ),
      ),
    );
  }
}

/// Four counts, counting up, each on a toned tile of its own.
class _Headline extends StatelessWidget {
  const _Headline({required this.activity, required this.animate});

  final FieldActivity activity;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final entries = <(int, String, IconData, AppTone)>[
      (activity.visits, t('activity.visits'), Icons.directions_walk_rounded,
          AppTone.primary),
      (activity.finesImposed, t('activity.fines'), Icons.gavel_rounded,
          AppTone.warning),
      (activity.shopsSealed, t('activity.sealed'), Icons.lock_rounded,
          AppTone.danger),
      (activity.sealsReleased, t('activity.released'),
          Icons.lock_open_rounded, AppTone.success),
    ];

    final scale =
        (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 1.7);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1 / (0.72 * scale),
      children: [
        for (var i = 0; i < entries.length; i++)
          AppStaggerIn(
            index: i,
            enabled: animate,
            child: AppCard(
              tone: entries[i].$4,
              rail: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    entries[i].$3,
                    size: 21,
                    color: entries[i].$4.on(context),
                  ),
                  const SizedBox(height: 12),
                  AppCountUp(
                    entries[i].$1,
                    variant: AppTextVariant.displaySmall,
                    color: entries[i].$4.on(context),
                    enabled: animate,
                  ),
                  const SizedBox(height: 4),
                  AppText.titleSmall(entries[i].$2, maxLines: 2),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The money, labelled exactly as the server labels it.
class _Collected extends StatelessWidget {
  const _Collected({required this.activity});

  final FieldActivity activity;

  @override
  Widget build(BuildContext context) {
    return AppMoneyPanel(
      // "Collected in your areas" — never "You recovered". A payment cannot
      // honestly be attributed to a visit: the shopkeeper may have paid
      // because of an SMS, a neighbour, or the end of the month.
      // Overclaiming here is how an officer stops trusting every other
      // figure in the app.
      label: t('activity.collected'),
      amount: activity.collectedInAreas,
      absentLabel: t('common.notRecorded'),
      tone: AppTone.success,
      footnote: t('activity.collectedNote'),
      facts: [
        AppPill(
          icon: Icons.receipt_rounded,
          tone: AppTone.success,
          label: t('activity.receipts',
              args: {'n': '${activity.receiptsInAreas}'}),
        ),
        if (activity.finesAmount != null)
          AppPill(
            icon: Icons.gavel_rounded,
            tone: AppTone.warning,
            label: t('activity.finesAmount',
                args: {'amount': activity.finesAmount!.withSymbol()}),
          ),
      ],
    );
  }
}

/// The action types as ranked horizontal bars.
///
/// Horizontal because the categories are words — "Reminder to revisit"
/// rotated under a vertical bar is a label nobody reads — and each bar
/// carries its figure at the end, so no value has to be estimated against
/// a gridline.
class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.activity, required this.animate});

  final FieldActivity activity;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final entries = ActivityShareDonut.ordered(activity);
    if (entries.isEmpty) return const SizedBox.shrink();

    return AppOrdinalBarChart(
      title: t('activity.breakdown'),
      subtitle: t('activity.breakdownSub'),
      animate: animate,
      entries: [
        for (final entry in entries)
          ChartBarEntry(
            // The app's own label for an action type — the API has no
            // options endpoint for this enum yet, so these are a second
            // source of truth. See QUESTIONS.md.
            label: tEnum('actionType', entry.key),
            value: entry.value,
            icon: ActivityShareDonut.glyphs[entry.key],
          ),
      ],
    );
  }
}
