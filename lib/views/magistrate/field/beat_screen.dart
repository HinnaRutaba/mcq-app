import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/routes/queue_destination.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/api/offline_queue_controller.dart';
import '../../../controllers/field/beat_controller.dart';
import '../../../controllers/field/field_map_controller.dart';
import '../../../core/utils/dialer.dart';
import '../../../core/utils/get_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/widgets.dart';
import 'widgets/activity_summary_card.dart';
import 'widgets/beat_header.dart';
import 'widgets/beat_queue_tile.dart';
import 'widgets/map_preview_card.dart';
import 'widgets/round_market_card.dart';
import '../api/widgets/stale_data_banner.dart';

/// The home screen — one call, everything on it.
///
/// The officer should open this and immediately know three things: **who he
/// is and where he is posted, what needs doing today, and what to tap to do
/// it.** If it does not do that it is not finished, however good the
/// endpoints are.
///
/// Built as a [CustomScrollView] so the green band collapses into a pinned
/// bar as he scrolls into the work, and so the six queues are a real
/// [SliverGrid] rather than a wrapped column — two columns of large,
/// equal-height tap targets that stay aligned when a label runs to two
/// lines or the officer has turned the text size up.
///
/// Everything here is reachable in one tap. **Nothing on this screen is a
/// dead end**: every tile opens the list behind it, the round card opens
/// the round, the chart opens the report, the map opens the map.
class BeatScreen extends StatelessWidget {
  const BeatScreen({super.key});

  static const EdgeInsets _gutter = EdgeInsets.symmetric(horizontal: 18);

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(BeatController.resolve);
    final maps = getOrPut(FieldMapController.resolve);
    final queue = Get.find<OfflineQueueController>();

    return Scaffold(
      body: AppRefresh(
        // Below the collapsed bar, so the spinner is not drawn under it.
        edgeOffset: MediaQuery.paddingOf(context).top + 64,
        onRefresh: () async {
          await controller.reload(refreshing: true);
          await maps.reload(refreshing: true);
        },
        child: Obx(() {
          final beat = controller.beat.value;
          final animate = controller.isFirstLoad.value;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              BeatHeaderSliver(
                officer: controller.officer,
                scope: controller.scope,
                actions: [
                  IconButton(
                    onPressed: () => context.push(AppRoutes.settings),
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: t('settings.title'),
                    color: Colors.white,
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                sliver: SliverList.list(
                  children: [
                    // What has not synced is never hidden from the officer.
                    Obx(() {
                      if (queue.badgeCount == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 18),
                        child: AppBanner(
                          tone: queue.attentionCount > 0
                              ? AppStatusTone.danger
                              : AppStatusTone.warning,
                          icon: Icons.sync_problem_rounded,
                          message: t('queue.count',
                              args: {'count': '${queue.badgeCount}'}),
                          action: AppButton(
                            label: t('queue.title'),
                            variant: AppButtonVariant.outline,
                            fullWidth: false,
                            height: 44,
                            onPressed: () => context.push(AppRoutes.queue),
                          ),
                        ),
                      );
                    }),
                    if (controller.isStale.value &&
                        controller.fetchedAt.value != null) ...[
                      StaleDataBanner(
                        fetchedAt: controller.fetchedAt.value!,
                        onRetry: () => controller.reload(refreshing: true),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),

              if (controller.isLoading.value && beat == null)
                const SliverPadding(
                  padding: _gutter,
                  sliver: SliverToBoxAdapter(child: _BeatSkeleton()),
                )
              else if (controller.hasFailed && beat == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    illustration: AppIllustrationKind.disconnected,
                    title: t('beat.couldNotLoad'),
                    // The server's own sentence, verbatim.
                    message: controller.failure.value!.message,
                    actionLabel: t('common.retry'),
                    onAction: controller.reload,
                  ),
                )
              else if (controller.hasNoPosting)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    illustration: AppIllustrationKind.noPosting,
                    title: t('beat.noPosting'),
                    message: t('beat.noPostingHelp'),
                  ),
                )
              else if (beat != null) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: AppSectionHeader(
                      title: t('beat.queuesTitle'),
                      subtitle: t('beat.queuesSub'),
                      icon: Icons.checklist_rounded,
                    ),
                  ),
                ),
                _QueueGrid(controller: controller, animate: animate),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
                  sliver: SliverList.list(
                    children: [
                      _RoundPreview(controller: controller),
                      const SizedBox(height: 26),
                      _Activity(controller: controller, animate: animate),
                      const SizedBox(height: 26),
                      Obx(() {
                        final units = maps.units.value;
                        if (units.units.isEmpty && !maps.isLoading.value) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSectionHeader(
                              title: t('map.title'),
                              icon: Icons.map_rounded,
                            ),
                            MapPreviewCard(
                              units: units,
                              onTap: () => context.push(AppRoutes.map),
                            ),
                            const SizedBox(height: 26),
                          ],
                        );
                      }),
                      const _QuickActions(),
                      if (beat.generatedAt != null) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: AppText.bodySmall(
                            t('beat.generatedAt', args: {
                              'time': TimeOfDay.fromDateTime(
                                      beat.generatedAt!.toLocal())
                                  .format(context),
                            }),
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

/// Two columns of large tap targets — the six queues.
///
/// A real [SliverGrid], so every tile is the same height whatever its
/// label does, and so the grid participates in the same scroll view as the
/// collapsing header rather than being nested inside it.
class _QueueGrid extends StatelessWidget {
  const _QueueGrid({required this.controller, required this.animate});

  final BeatController controller;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final queues = controller.queues;
    if (queues.isEmpty) {
      return SliverToBoxAdapter(
        child: AppEmptyState(
          illustration: AppIllustrationKind.allClear,
          title: t('beat.noQueues'),
          message: t('beat.noQueuesHelp'),
        ),
      );
    }

    // A fixed extent rather than an aspect ratio: the officer's large-text
    // setting must grow the tile, not clip its sub-label. 246 is the
    // *measured* height of the tallest tile — icon plate, count, amount,
    // a two-line title and a two-line sub-label — arrived at by rendering
    // it, not by guessing. Guessing is how the first version shipped with
    // "Shops behind on" as a queue name.
    final scale =
        (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 1.7);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 246 * scale,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => AppStaggerIn(
            index: index,
            enabled: animate,
            child: BeatQueueTile(
              queue: queues[index],
              animate: animate,
              onTap: () => QueueDestination.open(context, queues[index]),
            ),
          ),
          childCount: queues.length,
        ),
      ),
    );
  }
}

/// Today's round, previewed: the first market, with its stops one tap away.
class _RoundPreview extends StatelessWidget {
  const _RoundPreview({required this.controller});

  final BeatController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final market = controller.nextMarket;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: t('round.title'),
            subtitle: t('round.subtitle'),
            icon: Icons.directions_walk_rounded,
            actionLabel:
                controller.round.length > 1 ? t('common.seeAll') : null,
            onAction: controller.round.length > 1
                ? () => context.go(AppRoutes.round)
                : null,
          ),
          if (market == null)
            AppCard(
              tone: AppTone.success,
              child: Row(
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    color: AppTone.success.on(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: AppText.body(t('round.nothingToWalk'))),
                ],
              ),
            )
          else
            RoundMarketCard(
              market: market,
              // Its own namespace: the round branch is alive in the shell
              // at the same time as this one, drawing the same market.
              heroPrefix: 'beat-round',
              expanded: false,
              onToggle: () => context.go(AppRoutes.round),
              onOpenStop: (stop) => context.push(
                AppRoutes.propertyProfilePath(
                  stop.propertyId,
                  from: 'beat-round-${market.marketName}',
                ),
                extra: stop,
              ),
              onCallStop: (stop) => Dialer.call(stop.mobileNo),
            ),
        ],
      );
    });
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.controller, required this.animate});

  final BeatController controller;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activity = controller.activity.value;
      if (activity == null) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: t('beat.yourWork'),
            subtitle: t('beat.yourWorkSub'),
            icon: Icons.insights_rounded,
            actionLabel: t('common.seeAll'),
            onAction: () => context.push(AppRoutes.activity),
          ),
          ActivitySummaryCard(
            activity: activity,
            animate: animate,
            onTap: () => context.push(AppRoutes.activity),
          ),
        ],
      );
    });
  }
}

/// Search, the map, and my work — three things that are not a queue.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: t('beat.quickActions')),
        Row(
          children: [
            Expanded(
              child: AppQuickAction(
                icon: Icons.search_rounded,
                label: t('nav.find'),
                onTap: () => context.go(AppRoutes.find),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppQuickAction(
                icon: Icons.handshake_rounded,
                label: t('followUps.short'),
                tone: AppTone.warning,
                onTap: () => context.push(AppRoutes.followUps),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppQuickAction(
                icon: Icons.insights_rounded,
                label: t('activity.short'),
                tone: AppTone.info,
                onTap: () => context.push(AppRoutes.activity),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The shape of the home screen while it loads — six tiles and a card.
class _BeatSkeleton extends StatelessWidget {
  const _BeatSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeletonGrid(),
        SizedBox(height: 26),
        AppSkeletonCard(),
      ],
    );
  }
}
