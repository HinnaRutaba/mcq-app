import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/field/field_activity.dart';
import '../../../../widgets/widgets.dart';

/// "This month: 34 visits, 4 fines, 2 shops sealed."
///
/// Recovery is slow, unglamorous and mostly invisible. An officer who
/// cannot see his own work has no reason to believe the visits matter, and
/// this card is the cheapest way to show him.
///
/// Four counts across the top, each with its own glyph and tone; then the
/// money, on a raised panel of its own; then, where the server sent a
/// breakdown, a **donut of what the period was made of** with the total in
/// the hole.
///
/// **The money is labelled exactly as the server labels it** — "Collected
/// in your areas", never "You recovered". A payment cannot honestly be
/// attributed to a visit; the shopkeeper may have paid because of an SMS, a
/// neighbour, or the end of the month. Overclaiming here is how an officer
/// stops trusting every other figure in the app.
class ActivitySummaryCard extends StatelessWidget {
  const ActivitySummaryCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.animate = true,
    this.showBreakdown = true,
  });

  final FieldActivity activity;
  final VoidCallback onTap;
  final bool animate;

  /// False on the report screen, where the full chart is drawn separately.
  final bool showBreakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppText.titleMedium(
                      t('activity.summaryTitle',
                          args: {'days': '${activity.periodDays}'}),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: muted.withValues(alpha: 0.7),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppFigure(
                      value: activity.visits,
                      label: t('activity.visits'),
                      icon: Icons.directions_walk_rounded,
                      tone: AppTone.primary,
                      animate: animate,
                    ),
                  ),
                  Expanded(
                    child: AppFigure(
                      value: activity.finesImposed,
                      label: t('activity.fines'),
                      icon: Icons.gavel_rounded,
                      tone: AppTone.warning,
                      animate: animate,
                    ),
                  ),
                  Expanded(
                    child: AppFigure(
                      value: activity.shopsSealed,
                      label: t('activity.sealed'),
                      icon: Icons.lock_rounded,
                      tone: AppTone.danger,
                      animate: animate,
                    ),
                  ),
                  Expanded(
                    child: AppFigure(
                      value: activity.sealsReleased,
                      label: t('activity.released'),
                      icon: Icons.lock_open_rounded,
                      tone: AppTone.success,
                      animate: animate,
                    ),
                  ),
                ],
              ),
              if (activity.collectedInAreas != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: AppTone.success.container(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: 20,
                        color: AppTone.success.on(context),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // The server's own words. Not "You recovered".
                            AppText.bodySmall(
                              t('activity.collected'),
                              color: muted,
                            ),
                            const SizedBox(height: 2),
                            MoneyText(
                              activity.collectedInAreas!,
                              variant: AppTextVariant.titleMedium,
                              color: AppTone.success.on(context),
                            ),
                          ],
                        ),
                      ),
                      AppText.bodySmall(
                        t('activity.receipts',
                            args: {'n': '${activity.receiptsInAreas}'}),
                        color: muted,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showBreakdown && activity.byActionType.isNotEmpty) ...[
          const SizedBox(height: 12),
          ActivityShareDonut(activity: activity),
        ],
      ],
    );
  }
}

/// What the period was made of, as a donut with the total in the hole.
///
/// The wedges are coloured from the **ordinal escalation ramp** in
/// escalation order — a visit is the lightest step, a seal the darkest —
/// so the ring says how hard the month was, not merely that it had five
/// kinds of thing in it. Nothing here is carried by colour alone: every
/// wedge is named in the legend with its glyph and its figure, and the
/// frame's table view gives the numbers outright.
class ActivityShareDonut extends StatelessWidget {
  const ActivityShareDonut({super.key, required this.activity});

  final FieldActivity activity;

  /// Gentlest first. The API has no options endpoint for `action_type`, so
  /// this order is the app's own — see QUESTIONS.md — and anything the
  /// server adds that is not listed falls to the end rather than being
  /// dropped.
  static const List<String> escalationOrder = [
    'site_visit',
    'reminder_visit_set',
    'payment_promised',
    'verbal_warning',
    'final_warning',
    'notice_served',
    'unseal',
    'seal',
  ];

  static const Map<String, IconData> glyphs = {
    'site_visit': Icons.directions_walk_rounded,
    'reminder_visit_set': Icons.event_repeat_rounded,
    'payment_promised': Icons.handshake_rounded,
    'verbal_warning': Icons.campaign_rounded,
    'final_warning': Icons.warning_amber_rounded,
    'notice_served': Icons.description_rounded,
    'unseal': Icons.lock_open_rounded,
    'seal': Icons.lock_rounded,
  };

  /// The breakdown in escalation order, gentlest first.
  static List<MapEntry<String, int>> ordered(FieldActivity activity) {
    final entries = activity.byActionType.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) {
        final ai = escalationOrder.indexOf(a.key);
        final bi = escalationOrder.indexOf(b.key);
        // An action type MCQ adds later still draws — at the end, rather
        // than crashing or being silently dropped.
        return (ai < 0 ? escalationOrder.length : ai)
            .compareTo(bi < 0 ? escalationOrder.length : bi);
      });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = ordered(activity);
    if (entries.isEmpty) return const SizedBox.shrink();
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return AppDonutChart(
      title: t('activity.shareTitle'),
      subtitle: t('activity.shareSub'),
      centreValue: '$total',
      centreLabel: t('activity.actions'),
      otherLabel: t('chart.other'),
      slices: [
        for (final entry in entries)
          DonutSlice(
            // The app's own label for an action type.
            label: tEnum('actionType', entry.key),
            value: entry.value,
            icon: glyphs[entry.key] ?? Icons.circle_outlined,
          ),
      ],
    );
  }
}
