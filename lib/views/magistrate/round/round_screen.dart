import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/round_controller.dart';
import '../../../models/defaulter_card.dart';
import '../../../models/round_group.dart';
import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';
import '../shared/widgets/defaulter_tile.dart';
import 'widgets/round_filters.dart';
import 'widgets/round_sticky_head.dart';

class RoundScreen extends StatelessWidget {
  const RoundScreen({super.key});

  /// The round's size, the title, and the search box under it.
  static const double _headerHeight = 152;

  @override
  Widget build(BuildContext context) {
    final RoundController controller = Get.find<RoundController>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(
          () => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              AppSliverHeroHeader(
                title: 'Today’s Round',
                subtitle: _subtitle(controller),
                expandedHeight: _headerHeight,
                compactTitle: true,
                leading: const BackToHomeButton(),
                bottom: AppSearchField(
                  controller: controller.searchController,
                  hint: 'Bazaar, holder, shop or CNIC',
                  onChanged: controller.search,
                ),
              ),
              AppPinnedBar(
                height: RoundFilters.heightFor(
                  withAreaChips: controller.hasAreaChoice,
                ),
                child: RoundFilters(controller: controller),
              ),
              ..._slivers(context, controller),
            ],
          ),
        ),
      ),
    );
  }
}

/// How much walking the round is, said before the officer scrolls it.
String _subtitle(RoundController controller) {
  if (!controller.hasData) return 'Your bazaars, in walking order';
  final int markets = controller.visible.length;
  final int stops = controller.stopCount;
  return '${markets == 1 ? '1 bazaar' : '$markets bazaars'} · '
      '${stops == 1 ? '1 stop' : '$stops stops'}';
}

List<Widget> _slivers(BuildContext context, RoundController controller) {
  // Nothing on screen yet: one spinner, not a half-drawn page.
  if (controller.isLoading.value && !controller.hasData) {
    return const <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ];
  }

  final String? error = controller.errorMessage.value;
  if (error != null && !controller.hasData) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorRetry(
          title: 'Could not load the round',
          message: error,
          onRetry: controller.load,
        ),
      ),
    ];
  }

  final List<RoundGroup> groups = controller.visible;
  if (groups.isEmpty) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        // Read here, inside the `Obx`, and handed over as plain values.
        child: _Nothing(
          narrowed: controller.isNarrowed,
          onClear: controller.clearFilters,
        ),
      ),
    ];
  }

  return <Widget>[
    // A failure over a round that is already up rides at the top: it is a
    // note, not a wall, and the sections below it are the last good ones.
    if (error != null)
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        sliver: SliverToBoxAdapter(
          child: AppAlert(
            message: error,
            tone: AppTone.warning,
            icon: Icons.wifi_off_rounded,
          ),
        ),
      ),

    // One group per market, each its own pinned head over its own stops: that
    // is what hands the next market's head the job of pushing the last one
    // off, rather than every head in the round stacking up.
    for (final RoundGroup group in groups)
      SliverMainAxisGroup(
        key: ValueKey<String>('market-${_key(group)}'),
        slivers: <Widget>[
          RoundStickyHead(group: group),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            sliver: SliverList.builder(
              itemCount: group.stops.length,
              itemBuilder: (BuildContext context, int index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == group.stops.length - 1 ? 0 : 12,
                ),
                child: _Stop(card: group.stops[index], index: index),
              ),
            ),
          ),
        ],
      ),

    const SliverToBoxAdapter(child: SizedBox(height: 24)),
  ];
}

/// Distinct per market, so a section keeps its element across a refresh: two
/// markets can share a bazaar, and the bazaar alone would collide.
String _key(RoundGroup group) =>
    '${group.areaId ?? 0}-${group.marketName ?? group.areaName ?? ''}';

/// One shop to call at. The same card the defaulter list draws, opening the
/// same profile.
class _Stop extends StatelessWidget {
  const _Stop({required this.card, required this.index});

  final DefaulterCard card;
  final int index;

  @override
  Widget build(BuildContext context) {
    final int? propertyId = card.propertyId;

    // Keyed by the unit, so a row keeps its element as the officer types:
    // unkeyed, every rebuild would restart the entrance and the round would
    // flicker on each keystroke.
    return AppEntrance(
      key: ValueKey<Object>(
        card.allotmentId ?? propertyId ?? card.allotmentNo ?? index,
      ),
      index: index,
      child: DefaulterTile(
        card: card,
        onTap: propertyId == null
            ? null
            : () => context.push(
                AppRoutes.propertyProfilePath(propertyId),
                // The profile draws its header from this while its own calls
                // are still out.
                extra: card,
              ),
      ),
    );
  }
}

/// An empty round, which means one of two very different things.
class _Nothing extends StatelessWidget {
  const _Nothing({required this.narrowed, required this.onClear});

  /// Whether a chip or the search box is what emptied the screen.
  final bool narrowed;

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (!narrowed) {
      return const AppEmptyState(
        icon: Icons.directions_walk_rounded,
        title: 'Nothing to walk today',
        message: 'No bazaar on your beat has a shop behind on rent.',
      );
    }

    // What emptied it is above this, but the way out of a dead end belongs in
    // the dead end.
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'Nothing matches',
            message: 'No bazaar or shop on today’s round answers to that.',
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Clear filters',
            icon: Icons.filter_alt_off_outlined,
            variant: AppButtonVariant.outline,
            fullWidth: false,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
