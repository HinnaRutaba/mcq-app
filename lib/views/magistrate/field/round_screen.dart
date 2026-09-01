import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/field/round_controller.dart';
import '../../../core/utils/dialer.dart';
import '../../../core/utils/get_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/field/field_card.dart';
import '../../../models/field/round.dart';
import '../../../widgets/widgets.dart';
import 'widgets/field_card_tile.dart';
import 'widgets/field_list_view.dart';
import 'widgets/round_market_card.dart';

/// Today's round — the screen that saves him an hour.
///
/// The officer is going to the bazaar anyway. The expensive part of his day
/// is deciding which shops to call on once he is standing there, and this
/// answers it: his defaulters grouped by market, ordered by broken promises
/// first, five stops each.
class RoundScreen extends StatelessWidget {
  const RoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(RoundController.resolve);

    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(t('round.title'))),
      body: Obx(() {
        final markets = controller.markets;
        final animate = controller.isFirstLoad.value;

        return FieldListView(
          isLoading: controller.isLoading.value,
          isEmpty: markets.isEmpty && !controller.isLoading.value,
          isStale: controller.isStale.value,
          fetchedAt: controller.fetchedAt.value,
          failureMessage: controller.failure.value?.message,
          onRefresh: () => controller.reload(refreshing: true),
          skeletonCount: 3,
          emptyState: AppEmptyState(
            illustration: AppIllustrationKind.roundDone,
            title: t('round.nothingToWalk'),
            message: t('round.nothingToWalkHelp'),
          ),
          header: [
            _RoundHeader(controller: controller),
            const SizedBox(height: 18),
          ],
          children: [
            for (var i = 0; i < markets.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              AppStaggerIn(
                index: i,
                enabled: animate,
                child: RoundMarketCard(
                  market: markets[i],
                  expanded: controller.expanded.value == i,
                  onToggle: () => controller.toggleExpanded(i),
                  hasWalked: controller.hasWalked,
                  onWalked: controller.markWalked,
                  onOpenStop: (stop) => context.push(
                    AppRoutes.propertyProfilePath(
                      stop.propertyId,
                      from: 'round-${markets[i].marketName}',
                    ),
                    extra: stop,
                  ),
                  onCallStop: (stop) => Dialer.call(stop.mobileNo),
                  onStartRound: markets[i].hasStops
                      ? () => RoundWalkPage.open(
                            context,
                            market: markets[i],
                            controller: controller,
                          )
                      : null,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

/// The illustrated header, and — once the officer starts ticking stops off
/// — his progress through the round.
class _RoundHeader extends StatelessWidget {
  const _RoundHeader({required this.controller});

  final RoundController controller;

  @override
  Widget build(BuildContext context) {
    final total = controller.totalStops;
    final walked = controller.walkedCount;
    final complete = controller.isComplete;

    return AppCard(
      tone: complete ? AppTone.success : AppTone.primary,
      rail: true,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleLarge(
                  complete ? t('round.complete') : t('round.subtitle'),
                ),
                const SizedBox(height: 6),
                AppText.body(
                  complete
                      ? t('round.completeHelp')
                      : t('round.progress', args: {
                          'walked': '$walked',
                          'total': '$total',
                        }),
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.75),
                ),
                if (total > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: total == 0 ? 0 : walked / total),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 7,
                        backgroundColor: Theme.of(context).dividerColor,
                        valueColor: AlwaysStoppedAnimation(
                          (complete ? AppTone.success : AppTone.primary)
                              .on(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          AppIllustration(
            complete
                ? AppIllustrationKind.roundDone
                : AppIllustrationKind.allClear,
            size: 84,
          ),
        ],
      ),
    );
  }
}

/// "Start round" — the stops, one at a time.
///
/// One shop fills the screen, with everything the officer needs on it and
/// the action sheet one tap away. He walks, taps *Done here*, and the next
/// shop appears. It is the difference between a list to read and a route to
/// walk.
class RoundWalkPage extends StatefulWidget {
  const RoundWalkPage({
    super.key,
    required this.market,
    required this.controller,
  });

  final RoundMarket market;
  final RoundController controller;

  static Future<void> open(
    BuildContext context, {
    required RoundMarket market,
    required RoundController controller,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => RoundWalkPage(market: market, controller: controller),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<RoundWalkPage> createState() => _RoundWalkPageState();
}

class _RoundWalkPageState extends State<RoundWalkPage> {
  final PageController _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<FieldCard> get _stops => widget.market.stops;

  void _next() {
    if (_index >= _stops.length - 1) {
      AppHaptics.success();
      Navigator.of(context).pop();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: UserText.name(widget.market.marketName),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: AppText.label(
                t('round.stopOf', args: {
                  'n': '${_index + 1}',
                  'total': '${_stops.length}',
                }),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _stops.isEmpty ? 0 : (_index + 1) / _stops.length,
            minHeight: 4,
            backgroundColor: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: _stops.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                final stop = _stops[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FieldCardTile(
                        card: stop,
                        heroPrefix: 'walk',
                        onTap: () => context.push(
                          AppRoutes.propertyProfilePath(
                            stop.propertyId,
                            from: 'walk',
                          ),
                          extra: stop,
                        ),
                        onCall: stop.isCallable
                            ? () => Dialer.call(stop.mobileNo)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: t('round.openProfile'),
                        icon: Icons.badge_outlined,
                        variant: AppButtonVariant.outline,
                        onPressed: () => context.push(
                          AppRoutes.propertyProfilePath(
                            stop.propertyId,
                            from: 'walk',
                          ),
                          extra: stop,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: t('round.doneHere'),
                        icon: Icons.check_rounded,
                        onPressed: () {
                          widget.controller.markWalked(stop);
                          AppHaptics.select();
                          _next();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
