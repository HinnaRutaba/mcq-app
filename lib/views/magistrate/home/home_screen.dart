import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mcq_app/views/magistrate/home/widgets/defaulter_breakdown.dart';

import '../../../config/theme/app_brand.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_radius.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../core/utils/screen_type.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/auth_user.dart';
import '../../../models/field_activity.dart';
import '../../../models/field_beat.dart';
import '../../../widgets/widgets.dart';
import 'queue_destination.dart';
import 'widgets/action_breakdown.dart';
import 'widgets/beat_queue_tile.dart';
import 'widgets/brand_plate.dart';
import 'widgets/home_search_button.dart';

class MagistrateHomeScreen extends StatelessWidget {
  const MagistrateHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Scaffold(body: Obx(() => _page(controller)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.officer, required this.scope});

  final AuthUser? officer;
  final FieldScope? scope;

  static const double _nameOnly = 86;

  /// Where [AppSliverHeroHeader] sets the title under a subtitle.
  static const double _titleTop = 36;
  static const double _stripSpacing = 14;
  static const double _bottomMargin = 20;

  /// Room for two circles instead of one, or the title runs under the search
  /// action on a long name.
  static const double _twoActions = 128;

  @override
  Widget build(BuildContext context) {
    final scope = this.scope;

    return AppSliverHeroHeader(
      // A beat of one road and one of six differ by a line, so the strip is
      // measured rather than budgeted, or the long one rides into the name.
      expandedHeight: scope == null
          ? _nameOnly
          : _titleTop +
                _textHeight(
                  context,
                  'Hg',
                  Theme.of(context).textTheme.headlineLarge,
                ) +
                _stripSpacing +
                _ScopeStrip.heightFor(context, scope) +
                _bottomMargin,
      subtitle: officer?.designation ?? 'Signed in',
      title: officer?.name ?? 'Home',
      trailingInset: _twoActions,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const HomeSearchButton(),
          const SizedBox(width: 10),
          AppCircleIconButton(
            icon: Icons.logout_rounded,
            iconColor: AppColors.dangerOnDark,
            onTap: () => AppSignOutDialog.confirmAndSignOut(context),
          ),
        ],
      ),
      bottomSpacing: scope == null ? null : _stripSpacing,
      bottom: scope == null ? null : _ScopeStrip(scope: scope),
    );
  }
}

/// The bazaars the figures cover, said out loud.
class _ScopeStrip extends StatelessWidget {
  const _ScopeStrip({required this.scope});

  final FieldScope scope;

  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );
  static const double _iconWidth = 18 + 10;

  static String _areas(FieldScope scope) => scope.areaNames.isEmpty
      ? 'No bazaars assigned'
      : scope.areaNames.join(' · ');

  /// The strip's laid-out height at this screen width and text scale.
  static double heightFor(BuildContext context, FieldScope scope) {
    final text = Theme.of(context).textTheme;
    final width =
        MediaQuery.sizeOf(context).width -
        40 -
        _padding.horizontal -
        _iconWidth;

    double measure(String value, TextStyle? style, int maxLines) =>
        _textHeight(context, value, style, maxLines: maxLines, width: width);

    final caption = measure('Your beat', text.labelSmall, 1);
    return _padding.vertical +
        caption +
        3 +
        measure(
          _areas(scope),
          text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          2,
        ) +
        (scope.zoneNames.isEmpty ? 0 : 2 + caption);
  }

  @override
  Widget build(BuildContext context) {
    final areas = _areas(scope);
    final muted = Colors.white.withValues(alpha: 0.75);

    return Container(
      width: double.infinity,
      padding: _padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.place_outlined, size: 18, color: muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.caption(
                  scope.restricted ? 'Your beat' : 'Whole city',
                  color: muted,
                ),
                const SizedBox(height: 3),
                AppText.body(
                  areas,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                ),
                if (scope.zoneNames.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  AppText.caption(
                    scope.zoneNames.join(' · '),
                    color: muted,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How tall [value] lays out in [style] at the device's text scale.
double _textHeight(
  BuildContext context,
  String value,
  TextStyle? style, {
  int maxLines = 1,
  double width = double.infinity,
}) {
  final painter = TextPainter(
    text: TextSpan(text: value, style: style),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: maxLines,
  )..layout(maxWidth: width);
  final height = painter.height;
  painter.dispose();
  return height;
}

Widget _page(DashboardController controller) {
  return RefreshIndicator(
    onRefresh: controller.load,
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        _Header(
          officer: controller.officer,
          scope: controller.beat.value?.scope,
        ),
        ..._bodySlivers(controller),
      ],
    ),
  );
}

List<Widget> _bodySlivers(DashboardController controller) {
  // Nothing on screen yet: the officer gets one spinner, not a half-drawn
  // page that shuffles as each call lands.
  if (controller.isLoading.value && !controller.hasData) {
    return const <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ];
  }

  final error = controller.errorMessage.value;
  if (error != null && !controller.hasData) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorRetry(
          title: 'Could not load your beat',
          message: error,
          onRetry: controller.load,
        ),
      ),
    ];
  }

  final beat = controller.beat.value;
  final activity = controller.activity.value;

  // Built with a running step count so the whole page arrives in reading
  // order — and a grid hands its own count out tile by tile, so six queues
  // ripple in rather than landing as one slab.
  //
  // Keyed, because this screen rebuilds on every observable change and an
  // unkeyed element would be rebuilt, restarting the entrance every time a
  // figure lands.
  final sections = <Widget>[];
  var step = 0;

  if (error != null) {
    // A failure over figures that are already up is a note, not a wall — the
    // numbers below it are the last good ones.
    sections.add(
      AppEntrance(
        key: const ValueKey<String>('alert'),
        index: step++,
        child: AppAlert(
          message: error,
          tone: AppTone.warning,
          icon: Icons.wifi_off_rounded,
        ),
      ),
    );
  }

  if (beat != null) {
    sections.add(
      _Section(
        key: const ValueKey<String>('queues'),
        title: 'Waiting for you',
        titleIndex: step++,
        child: _QueueGrid(queues: beat.queues, firstIndex: step),
      ),
    );
    step += beat.queues.length;
  }

  if (controller.hasDefaulterBreakdown) {
    sections.add(
      _Section(
        key: const ValueKey<String>('arrears'),
        title: 'Where the arrears are',
        titleIndex: step++,
        child: AppEntrance(
          index: step++,
          child: DefaulterBreakdown(
            groups: controller.bazaarsByArrears,
            brokenPromises: controller.brokenPromises,
            neverPaid: controller.neverPaid,
            sealed: controller.sealedInRound,
            // The server's own total, not one added up here.
            totalOutstanding: beat?.queue('defaulters')?.amount,
          ),
        ),
      ),
    );
  }

  sections.add(
    _Section(
      key: const ValueKey<String>('work'),
      title: 'Your work',
      titleIndex: step++,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppEntrance(
            index: step++,
            child: AppChipTabs<int>(
              items: DashboardController.activityWindows,
              itemLabel: (int days) => 'Last $days',
              selected: controller.activityDays.value,
              onChanged: controller.setActivityWindow,
            ),
          ),
          const SizedBox(height: 14),
          if (controller.isReloadingActivity.value)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (activity != null)
            _ActivitySection(
              activity: activity,
              scope: beat?.scope,
              firstIndex: step,
            )
          else
            const AppEmptyState(
              icon: Icons.insights_outlined,
              title: 'No activity yet',
              message:
                  'Visits, fines and seals appear here as you record them.',
            ),
        ],
      ),
    ),
  );
  step += 6;

  if (beat?.generatedAt != null) {
    sections.add(
      AppEntrance(
        key: const ValueKey<String>('generated'),
        index: step++,
        child: AppText.caption(
          'Figures as of ${Formatters.dateTime(beat!.generatedAt!.toLocal())}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  return <Widget>[
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      sliver: SliverList.list(
        children: <Widget>[
          for (int i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 20),
            sections[i],
          ],
        ],
      ),
    ),
  ];
}

/// A titled block of the page.
class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    required this.titleIndex,
    required this.child,
  });

  final String title;

  /// Where the heading sits in the page's arrival order. The child brings its
  /// own, because only it knows whether it is one block or a grid of them.
  final int titleIndex;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppEntrance(index: titleIndex, child: _SectionTitle(title)),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

/// A heading with the brand's rule stood on end beside it — enough to break a
/// long scroll into blocks without another card doing it.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 4,
          height: 17,
          decoration: BoxDecoration(
            color: context.brand.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(width: 9),
        Flexible(child: AppText.titleMedium(title, maxLines: 1)),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.activity,
    required this.scope,
    required this.firstIndex,
  });

  final FieldActivity activity;
  final FieldScope? scope;

  /// Where this block's first tile falls in the page's arrival order.
  final int firstIndex;

  @override
  Widget build(BuildContext context) {
    final fines = activity.finesAmount;
    final collected = activity.collectedInYourAreas;
    final wide = !context.isMobile;

    final money = <Widget>[
      if (fines != null)
        _MoneyCard(
          icon: Icons.gavel_rounded,
          title: 'Value of fines imposed',
          amount: fines,
          notes: <String>[
            'Across ${activity.finesImposed} fines in the last '
                '${activity.periodDays} days.',
          ],
        ),
      if (collected != null) _CollectedCard(activity: activity, scope: scope),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Grid(
          // One row of four wider than a phone.
          columns: wide ? 4 : 2,
          firstIndex: firstIndex,
          extent: AppStatTile.extent,
          children: [
            AppStatTile.count(
              activity.visits,
              label: 'Visits',
              icon: Icons.directions_walk_rounded,
            ),
            AppStatTile.count(
              activity.finesImposed,
              label: 'Fines imposed',
              icon: Icons.gavel_rounded,
            ),
            AppStatTile.count(
              activity.shopsSealed,
              label: 'Shops sealed',
              icon: Icons.lock_outline_rounded,
            ),
            AppStatTile.count(
              activity.sealsReleased,
              label: 'Seals released',
              icon: Icons.lock_open_outlined,
            ),
          ],
        ),
        // Side by side wider than a phone, stretched to the taller card so
        // the two plates line up.
        if (wide && money.length == 2) ...[
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: money[0]),
                const SizedBox(width: 10),
                Expanded(child: money[1]),
              ],
            ),
          ),
        ] else
          for (final Widget card in money) ...[
            const SizedBox(height: 10),
            card,
          ],
        if (activity.byActionType.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle('How far things went'),
          const SizedBox(height: 10),
          ActionBreakdown(byActionType: activity.byActionType),
        ],
      ],
    );
  }
}

/// A money figure given the room a money figure is worth, on the brand plate
/// so the two figures an officer is actually judged on do not read as two
/// more rows.
class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.icon,
    required this.title,
    required this.amount,
    required this.notes,
  });

  final IconData icon;
  final String title;

  /// The server's own decimal string, printed by [AppCountUp.money] and never
  /// totalled with another.
  final String amount;

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final Color ink = BrandPlate.inkOf(context);
    final Color muted = ink.withValues(alpha: 0.72);

    return BrandPlate(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 16, color: ink),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppText.titleMedium(title, color: ink, maxLines: 1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppCountUp.money(
            amount,
            variant: AppTextVariant.headlineLarge,
            color: ink,
          ),
          for (final String note in notes) ...[
            const SizedBox(height: 5),
            AppText.caption(note, color: muted),
          ],
        ],
      ),
    );
  }
}

class _CollectedCard extends StatelessWidget {
  const _CollectedCard({required this.activity, required this.scope});

  final FieldActivity activity;
  final FieldScope? scope;

  @override
  Widget build(BuildContext context) {
    final areas = scope?.areaNames ?? const <String>[];

    return _MoneyCard(
      icon: Icons.payments_outlined,
      title: 'Collected in your areas',
      amount: activity.collectedInYourAreas!,
      notes: <String>[
        '${activity.receiptsInYourAreas} receipts over the last '
            '${activity.periodDays} days'
            '${areas.isEmpty ? '' : ' across ${areas.join(' and ')}'}.',
        'Everything paid in these bazaars — not only what you recovered.',
      ],
    );
  }
}

class _QueueGrid extends StatelessWidget {
  const _QueueGrid({required this.queues, required this.firstIndex});

  final List<FieldQueue> queues;

  /// Where this grid's first tile falls in the page's arrival order.
  final int firstIndex;

  @override
  Widget build(BuildContext context) {
    if (queues.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nothing waiting',
        message: 'No queues came back for your beat.',
      );
    }

    return _Grid(
      columns: 3,
      firstIndex: firstIndex,
      extent: BeatQueueTile.extent,
      children: <Widget>[
        for (final FieldQueue queue in queues)
          // Untappable where nothing answers the queue yet — see
          // [QueueDestination].
          BeatQueueTile(
            queue: queue,
            onTap: QueueDestination.exists(queue.key)
                ? () => QueueDestination.open(context, queue)
                : null,
          ),
      ],
    );
  }
}

/// A fixed-height grid, so a tile carrying money and one that is only a count
/// line up instead of ragging.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.children,
    required this.extent,
    this.columns = 2,
    this.firstIndex,
  });

  final List<Widget> children;

  /// Set to stagger the tiles in, one after the next, from this position in
  /// the page's arrival order. Null leaves them still.
  final int? firstIndex;
  final double extent;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: extent,
      ),
      itemBuilder: (BuildContext context, int index) => firstIndex == null
          ? children[index]
          : AppEntrance(index: firstIndex! + index, child: children[index]),
    );
  }
}
