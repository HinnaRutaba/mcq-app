import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme/app_colors.dart';
import '../../../controllers/field/shop_profile_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/field/field_card.dart';
import '../../../widgets/widgets.dart';
import '../api/widgets/action_timeline_tile.dart';
import '../api/widgets/challan_tile.dart';
import 'widgets/field_actions.dart';
import 'widgets/profile_hero.dart';

/// The shopkeeper profile — and the action sheet, which is the important
/// part.
///
/// The card the officer tapped expands into this page: the name and the
/// amount visibly continue rather than cutting to a new screen, and both
/// are on it before a single request has answered.
///
/// ### Why the page is tabbed
///
/// A shop's record answers three different questions, and an officer
/// standing in front of the shutter is asking exactly one of them: *who is
/// this and what do I know*, *what is owed*, and *what has already been
/// tried*. Stacked in one column those three ran to four screenfuls, and
/// the third — the history, which is what justifies a seal — was always
/// the part he had to scroll to. As tabs, each is one tap, and the two
/// things he must never have to hunt for stay pinned above them: the name
/// and the figure.
class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({
    super.key,
    required this.propertyId,
    this.card,
    this.heroPrefix = 'defaulters',
  });

  final int propertyId;

  /// The card the officer tapped. Carried as `extra` so the page draws
  /// immediately and still works with no signal — which is exactly when an
  /// officer is standing in front of the shop.
  final FieldCard? card;

  final String heroPrefix;

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  late final String _tag = 'profile-${widget.propertyId}';
  late final ShopProfileController _controller = Get.put(
    ShopProfileController.resolve(widget.propertyId, seed: widget.card),
    tag: _tag,
  );

  @override
  void dispose() {
    Get.delete<ShopProfileController>(tag: _tag);
    super.dispose();
  }

  void _openActions(FieldCard card) {
    FieldActions.show(
      context,
      target: ActionTarget.fromCard(card).copyWith(
        caseId: _controller.openCaseId,
        sealId: _controller.sealId,
        isSealed: _controller.isSealed,
        hasLiveStay: _controller.hasLiveStay,
      ),
      onChanged: () => _controller.reload(refreshing: true),
    );
  }

  Future<void> _refresh() => _controller.reload(refreshing: true);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: AppText.titleLarge(t('profile.title')),
          actions: [
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: t('common.refresh'),
            ),
          ],
        ),
        // Prominent and always reachable — the officer should never have to
        // scroll or change tab to find what he came here to do.
        floatingActionButton: Obx(() {
          final card = _controller.card.value;
          if (card == null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () {
              AppHaptics.select();
              _openActions(card);
            },
            icon: const Icon(Icons.bolt_rounded),
            label: Text(t('actions.title')),
          );
        }),
        body: Obx(() {
          final card = _controller.card.value;

          if (card == null) {
            if (_controller.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.all(18),
                child: AppSkeletonList(count: 3),
              );
            }
            return AppEmptyState(
              illustration: AppIllustrationKind.disconnected,
              title: t('profile.couldNotLoad'),
              message: _controller.failure.value?.message,
              actionLabel: t('common.retry'),
              onAction: _controller.reload,
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, _) => [
              // The identity and the figure, always on screen: a
              // SliverToBoxAdapter rather than a FlexibleSpaceBar because
              // its height depends on how many facts the server sent, and a
              // fixed expandedHeight would clip a shop with a long name.
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(18, 4, 18, 18),
                  child: _Head(
                    card: card,
                    controller: _controller,
                    heroPrefix: widget.heroPrefix,
                    onAct: () => _openActions(card),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabsHeader(
                  colour: Theme.of(context).scaffoldBackgroundColor,
                  tabBar: TabBar(
                    tabs: [
                      Tab(text: t('profile.tabOverview')),
                      Tab(text: t('profile.tabMoney')),
                      Tab(text: t('profile.tabHistory')),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _OverviewTab(
                  card: card,
                  controller: _controller,
                  onRefresh: _refresh,
                ),
                _MoneyTab(controller: _controller, onRefresh: _refresh),
                _HistoryTab(controller: _controller, onRefresh: _refresh),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Name, unit, the stay warning, and the one big figure.
class _Head extends StatelessWidget {
  const _Head({
    required this.card,
    required this.controller,
    required this.heroPrefix,
    required this.onAct,
  });

  final FieldCard card;
  final ShopProfileController controller;
  final String heroPrefix;
  final VoidCallback onAct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileHero(card: card, heroPrefix: heroPrefix),
        if (controller.hasLiveStay) ...[
          const SizedBox(height: 16),
          // Loudly, as the brief asks. A stay order blocks the seal, the
          // fine and the magistrate assignment, and an officer should not
          // walk to the shop in the first place.
          AppBanner(
            tone: AppStatusTone.warning,
            icon: Icons.balance_rounded,
            title: t('actions.stayTitle'),
            message: t('actions.stayBlocks'),
          ),
        ],
        const SizedBox(height: 18),
        _Money(card: card, heroPrefix: heroPrefix),
        if (controller.shouldSuggestEscalation) ...[
          const SizedBox(height: 14),
          _EscalationSuggestion(
            promises: controller.promisesMade,
            onAct: onAct,
          ),
        ],
      ],
    );
  }
}

/// The one large figure, on the surface it deserves.
class _Money extends StatelessWidget {
  const _Money({required this.card, required this.heroPrefix});

  final FieldCard card;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    // The same tag the card's amount carries, so the figure the officer
    // tapped visibly grows into the panel rather than being redrawn.
    return Hero(
      tag: '$heroPrefix-amount-${card.propertyId}',
      child: Material(
        type: MaterialType.transparency,
        child: AppMoneyPanel(
          label:
              card.isVacant ? t('profile.nobodyHolds') : t('profile.owesNow'),
          amount: card.outstanding,
          // Absent is not zero. A vacant unit owes nothing because nobody
          // holds it; a tenant who is up to date owes nothing because he
          // paid. Only one of those is good news.
          absentLabel: t('card.vacant'),
          tone: card.isVacant
              ? AppTone.info
              : (card.outstanding?.isZero ?? false)
                  ? AppTone.success
                  : AppTone.danger,
          facts: [
            if (card.monthsBehind > 0)
              AppPill(
                icon: Icons.event_busy_rounded,
                tone: AppTone.warning,
                label: t('card.monthsBehind',
                    args: {'months': '${card.monthsBehind}'}),
              ),
            if (card.daysOverdue != null && card.daysOverdue! > 0)
              AppPill(
                icon: Icons.schedule_rounded,
                tone: AppTone.danger,
                label: t('card.daysOverdue',
                    args: {'days': '${card.daysOverdue}'}),
              ),
            AppPill(
              icon:
                  card.neverPaid ? Icons.block_rounded : Icons.payments_rounded,
              tone: card.neverPaid ? AppTone.danger : AppTone.success,
              emphasis: card.neverPaid,
              // Never paid, in words. Not a bare 0.00 where the real
              // answer is "we have never received anything".
              label: card.neverPaid
                  ? t('card.neverPaid')
                  : card.lastPaymentDate == null
                      ? t('profile.lastPaymentUnknown')
                      : t('profile.lastPaid', args: {
                          'date': Formatters.date(card.lastPaymentDate!)
                        }),
            ),
          ],
          footnote: t('profile.rentAndFinesSeparate'),
        ),
      ),
    );
  }
}

/// Who, where, on what agreement.
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.card,
    required this.controller,
    required this.onRefresh,
  });

  final FieldCard card;
  final ShopProfileController controller;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppRefresh(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 120),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AppSectionHeader(
            title: t('profile.facts'),
            icon: Icons.badge_outlined,
          ),
          _Facts(card: card, controller: controller),
        ],
      ),
    );
  }
}

/// Rent and fines, side by side and **never summed**.
class _MoneyTab extends StatelessWidget {
  const _MoneyTab({required this.controller, required this.onRefresh});

  final ShopProfileController controller;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rent = controller.rentChallans;
      final fines = controller.fineChallans;
      final challans = [...rent, ...fines];

      return AppRefresh(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 120),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (challans.isEmpty)
              AppEmptyState(
                illustration: AppIllustrationKind.allClear,
                title: t('profile.obligations'),
                message: t('profile.obligationsNote'),
                compact: true,
              )
            else ...[
              AppSectionHeader(
                title: t('profile.obligations'),
                // The single most common argument at the counter, answered
                // on the screen before it starts.
                subtitle: t('profile.obligationsNote'),
                icon: Icons.receipt_long_rounded,
              ),
              for (var i = 0; i < challans.length; i++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 10),
                  child: AppStaggerIn(
                    index: i,
                    child: ChallanTile(challan: challans[i]),
                  ),
                ),
            ],
          ],
        ),
      );
    });
  }
}

/// Every previous visit and action, newest first, on a rail.
///
/// This is where a magistrate sees that somebody has promised twice and
/// broken it twice — which is exactly what justifies a seal. Drawn as a
/// [AppTimeline] rather than a stack of cards because the question asked of
/// it is always about *order and gaps*, and a rail answers that at a glance
/// where a list of dates does not.
class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.controller, required this.onRefresh});

  final ShopProfileController controller;
  final Future<void> Function() onRefresh;

  /// The glyph for each action, so an event is identifiable without its
  /// colour and without reading its label.
  static IconData _icon(String type) => switch (type) {
        'site_visit' => Icons.directions_walk_rounded,
        'reminder_visit_set' => Icons.event_repeat_rounded,
        'payment_promised' => Icons.handshake_rounded,
        'verbal_warning' => Icons.campaign_rounded,
        'final_warning' => Icons.warning_amber_rounded,
        'notice_served' => Icons.description_rounded,
        'seal' => Icons.lock_rounded,
        'unseal' => Icons.lock_open_rounded,
        _ => Icons.history_rounded,
      };

  /// The tone is the *kind* of event, never a judgement invented here.
  static AppTone _tone(String type) => switch (type) {
        'seal' || 'final_warning' => AppTone.danger,
        'verbal_warning' || 'notice_served' || 'payment_promised' =>
          AppTone.warning,
        'unseal' => AppTone.success,
        _ => AppTone.info,
      };

  static bool _emphasis(String type) =>
      type == 'seal' || type == 'unseal' || type == 'final_warning';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final actions = controller.timeline;

      return AppRefresh(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 120),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (controller.promisesMade > 0) ...[
              AppBanner(
                tone: AppStatusTone.warning,
                icon: Icons.handshake_rounded,
                message: t('profile.promisesMade',
                    args: {'n': '${controller.promisesMade}'}),
              ),
              const SizedBox(height: 16),
            ],
            if (controller.isLoadingTimeline.value && actions.isEmpty)
              const AppSkeletonList(count: 3)
            else if (actions.isEmpty)
              AppEmptyState(
                illustration: AppIllustrationKind.nothingToChase,
                title: controller.openCaseId == null
                    ? t('profile.noCaseNoTimeline')
                    : t('profile.noActionsYet'),
                compact: true,
              )
            else
              AppTimeline(
                entries: [
                  for (final action in actions)
                    AppTimelineEntry(
                      icon: _icon(action.actionType.value),
                      tone: _tone(action.actionType.value),
                      emphasis: _emphasis(action.actionType.value),
                      child: ActionTimelineTile(action: action),
                    ),
                ],
              ),
          ],
        ),
      );
    });
  }
}

/// Agreement, unit, market, rent — the two-column facts card.
class _Facts extends StatelessWidget {
  const _Facts({required this.card, required this.controller});

  final FieldCard card;
  final ShopProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final property = controller.property.value;
      final rows = <(String, String?, IconData)>[
        (t('profile.agreementNo'), card.allotmentNo, Icons.description_outlined),
        (t('profile.propertyCode'), card.propertyCode, Icons.tag_rounded),
        (t('profile.shopNo'), card.shopNo, Icons.storefront_outlined),
        (t('profile.market'), card.marketName, Icons.store_mall_directory_outlined),
        (t('profile.area'), card.areaName, Icons.place_outlined),
        if (property != null) ...[
          (t('profile.category'), property.category.label, Icons.category_outlined),
          (
            t('profile.monthlyRent'),
            property.monthlyRent?.withSymbol(),
            Icons.payments_outlined
          ),
          (t('profile.status'), property.status.label, Icons.info_outline_rounded),
        ],
      ];

      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(color: Theme.of(context).dividerColor),
              _Fact(row: rows[i]),
            ],
          ],
        ),
      );
    });
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.row});

  final (String, String?, IconData) row;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final value = (row.$2 ?? '').trim();

    // A definition list, not a paragraph: label on the leading side, value
    // on the trailing side, so the officer's eye runs down one column of
    // answers rather than reading nine sentences.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(row.$3, size: 18, color: muted),
          const SizedBox(width: 11),
          Expanded(child: AppText.bodySmall(row.$1, color: muted)),
          const SizedBox(width: 12),
          Flexible(
            child: UserText.body(
              value.isEmpty ? t('common.notRecorded') : value,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// "He has promised twice and broken it twice."
///
/// None of this was asked for and all of it is already in the payload. The
/// officer should not have to count the timeline to reach the conclusion
/// the timeline supports.
class _EscalationSuggestion extends StatelessWidget {
  const _EscalationSuggestion({required this.promises, required this.onAct});

  final int promises;
  final VoidCallback onAct;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppTone.danger,
      rail: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.trending_up_rounded, color: AppTone.danger.on(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium(
                  t('profile.escalate'),
                  color: AppTone.danger.on(context),
                ),
                const SizedBox(height: 4),
                AppText.body(t('profile.escalateHelp', args: {'n': '$promises'})),
                const SizedBox(height: 12),
                AppButton(
                  label: t('actions.title'),
                  icon: Icons.gavel_rounded,
                  variant: AppButtonVariant.danger,
                  height: 46,
                  fullWidth: false,
                  onPressed: onAct,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pins the tab bar under the head block as the page scrolls.
class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader({required this.tabBar, required this.colour});

  final TabBar tabBar;
  final Color colour;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    // An opaque background, or the cards scroll visibly through the tabs.
    return ColoredBox(color: colour, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabsHeader old) =>
      old.tabBar != tabBar || old.colour != colour;
}
