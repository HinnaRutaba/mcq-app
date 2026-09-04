import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_radius.dart';
import '../../../controllers/challans_controller.dart';
import '../../../models/challan.dart';
import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';
import 'widgets/challan_filters.dart';
import 'widgets/challan_tile.dart';

class ChallansScreen extends StatelessWidget {
  const ChallansScreen({super.key});

  /// Two heights: the count line only appears once the first page has landed,
  /// and a header sized for it before then leaves a gap under the title.
  static const double _headerHeight = 104;
  static const double _headerWithCount = 110;

  /// Between the title and the count line. Set here rather than left to fall
  /// out of [_headerWithCount], which is what made it a tuning exercise.
  static const double _countSpacing = 12;

  static const double _prefetchExtent = 600;

  @override
  Widget build(BuildContext context) {
    final ChallansController controller = Get.find<ChallansController>();

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification.metrics.extentAfter < _prefetchExtent) {
            controller.loadMore();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: Obx(
            () => CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                AppSliverHeroHeader(
                  title: 'Challans',
                  expandedHeight: controller.hasData
                      ? _headerWithCount
                      : _headerHeight,
                  compactTitle: true,
                  leading: const BackToHomeButton(),
                  bottomSpacing: _countSpacing,
                  // The header's own slot: it fades out before the bar finishes
                  // collapsing, so the count goes with the expanded block and
                  // the officer scrolls down to rows rather than past a plate.
                  bottom: controller.hasData
                      ? _CountLine(
                          shown: controller.visible.length,
                          total: controller.total,
                          filter: controller.filter.value,
                        )
                      : null,
                ),
                AppPinnedBar(
                  height: ChallanFilters.height,
                  child: ChallanFilters(controller: controller),
                ),
                ..._slivers(controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _slivers(ChallansController controller) {
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
          title: 'Could not load the challans',
          message: error,
          onRetry: controller.load,
        ),
      ),
    ];
  }

  final List<Challan> rows = controller.visible;

  if (rows.isEmpty) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        // Read here, inside the `Obx`, and handed over as plain values.
        child: _Nothing(
          filter: controller.filter.value,
          hasMore: controller.hasMore,
          isLoadingMore: controller.isLoadingMore.value,
          onLoadMore: controller.loadMore,
          onClear: () => controller.showFilter(ChallanFilter.all),
        ),
      ),
    ];
  }

  // A failure over rows that are already up rides at the top of the list: it
  // is a note, not a wall, and the rows below it are the last good ones.
  final List<Widget> lead = <Widget>[
    if (error != null)
      AppAlert(
        message: error,
        tone: AppTone.warning,
        icon: Icons.wifi_off_rounded,
      ),
  ];

  return <Widget>[
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      sliver: SliverList.builder(
        itemCount: lead.length + rows.length,
        itemBuilder: (BuildContext context, int index) {
          if (index < lead.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: lead[index],
            );
          }

          final Challan challan = rows[index - lead.length];

          // Keyed by the bill, so a row keeps its element as pages append:
          // unkeyed, every rebuild would restart the entrance and the list
          // would flicker each time the next page lands.
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppEntrance(
              key: ValueKey<Object>(challan.id ?? challan.challanNo ?? index),
              index: index,
              child: ChallanTile(challan: challan),
            ),
          );
        },
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
      sliver: SliverToBoxAdapter(
        child: _Footer(
          hasMore: controller.hasMore,
          isLoadingMore: controller.isLoadingMore.value,
          total: controller.total,
          onLoadMore: controller.loadMore,
        ),
      ),
    ),
  ];
}

/// How many bills are outstanding, on one line under the header's title.
///
/// The whole count leads, not the part fetched — an officer wants to know what
/// the bazaar owes, and "25" over a list of 30 is a fact about the scroll
/// position rather than about the debt. Where the two differ the scroll's own
/// figure follows the total on the same line.
///
/// A count of bills, never a total of them: adding a fine's balance to a rent
/// bill's would invent a debt nobody is owed.
class _CountLine extends StatelessWidget {
  const _CountLine({
    required this.shown,
    required this.total,
    required this.filter,
  });

  /// Rows on screen — fewer than [total] until the last page is in.
  final int shown;

  /// What the server says the current query holds, all pages in. Null until
  /// the first page has landed.
  final int? total;

  final ChallanFilter filter;

  @override
  Widget build(BuildContext context) {
    final Color muted = Colors.white.withValues(alpha: 0.75);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Icon(Icons.receipt_long_rounded, size: 18, color: muted),
          const SizedBox(width: 10),
          AppText.titleLarge(
            '$_figure',
            color: Colors.white,
            fontWeight: FontWeight.w700,
            maxLines: 1,
          ),
          const SizedBox(width: 6),
          Expanded(child: AppText.body(_rest, color: muted, maxLines: 1)),
        ],
      ),
    );
  }

  /// Rent is narrowed in the app rather than asked for, so the server's total
  /// does not describe it and the rows in hand are the only honest count —
  /// see [ChallanFilter].
  int get _figure => filter == ChallanFilter.rent ? shown : (total ?? shown);

  /// What the figure counts, and — where the list is longer than the pages
  /// fetched — how much of it is up.
  String get _rest {
    final String noun = switch (filter) {
      ChallanFilter.all => _figure == 1 ? 'challan' : 'challans',
      ChallanFilter.rent => _figure == 1 ? 'rent bill' : 'rent bills',
      ChallanFilter.fines => _figure == 1 ? 'fine' : 'fines',
    };
    if (filter == ChallanFilter.rent) return '$noun · loaded so far';
    final int? all = total;
    if (all == null || shown >= all) return noun;
    return '$noun · $shown showing';
  }
}

/// The bottom of the list: the next page on its way, an offer to fetch it, or
/// the end said out loud.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.hasMore,
    required this.isLoadingMore,
    required this.total,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool isLoadingMore;
  final int? total;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    // Scrolling fetches the next page on its own; this is for the thumb that
    // stops at the gap, and it is what a test can press.
    if (hasMore) {
      return Center(
        child: AppButton(
          label: 'Load more',
          icon: Icons.expand_more_rounded,
          variant: AppButtonVariant.outline,
          fullWidth: false,
          onPressed: onLoadMore,
        ),
      );
    }

    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Center(
      child: AppText.caption(
        total == null ? 'End of the list' : 'End of the list · $total in all',
        color: muted,
      ),
    );
  }
}

/// An empty list, which means two different things.
class _Nothing extends StatelessWidget {
  const _Nothing({
    required this.filter,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onClear,
  });

  final ChallanFilter filter;

  /// Whether the server still has pages. On [ChallanFilter.rent] this is the
  /// difference between "no rent bills" and "none on the pages fetched yet".
  final bool hasMore;

  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (filter == ChallanFilter.all) {
      return const AppEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Nothing outstanding',
        message: 'No challan is waiting to be paid.',
      );
    }

    final bool isFines = filter == ChallanFilter.fines;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AppEmptyState(
            icon: isFines ? Icons.gavel_rounded : Icons.receipt_long_outlined,
            title: isFines ? 'No fines' : 'No rent bills',
            message: hasMore && !isFines
                // Rent is narrowed in the app, so an empty screen here is only
                // a statement about the pages fetched so far.
                ? 'None on the pages loaded so far. There are more to fetch.'
                : isFines
                ? 'Nobody has an unpaid penalty.'
                : 'Every bill outstanding is a penalty, not rent.',
          ),
          const SizedBox(height: 8),
          AppButton(
            label: hasMore && !isFines ? 'Load more' : 'Show all bills',
            icon: hasMore && !isFines
                ? Icons.expand_more_rounded
                : Icons.filter_alt_off_outlined,
            variant: AppButtonVariant.outline,
            fullWidth: false,
            onPressed: isLoadingMore
                ? null
                : (hasMore && !isFines ? onLoadMore : onClear),
          ),
        ],
      ),
    );
  }
}
