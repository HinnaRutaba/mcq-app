import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/theme/app_colors.dart';
import '../../controllers/dashboard_controller.dart';
import '../../core/utils/formatters.dart';
import '../../models/auth_user.dart';
import '../../models/field_activity.dart';
import '../../models/field_beat.dart';
import '../../widgets/widgets.dart';
import 'widgets/action_breakdown.dart';
import 'widgets/beat_queue_tile.dart';
import 'widgets/defaulter_breakdown.dart';

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

  static const double _withScope = 196;
  static const double _nameOnly = 108;

  @override
  Widget build(BuildContext context) {
    return AppSliverHeroHeader(
      expandedHeight: scope == null ? _nameOnly : _withScope,
      subtitle: officer?.designation ?? 'Signed in',
      title: officer?.name ?? 'Home',
      trailing: const AppCircleIconButton(
        icon: Icons.notifications_none_rounded,
        badge: true,
      ),
      bottom: scope == null ? null : _ScopeStrip(scope: scope!),
    );
  }
}

/// The bazaars the figures cover, said out loud.
class _ScopeStrip extends StatelessWidget {
  const _ScopeStrip({required this.scope});

  final FieldScope scope;

  @override
  Widget build(BuildContext context) {
    final areas = scope.areaNames.isEmpty
        ? 'No bazaars assigned'
        : scope.areaNames.join(' · ');
    final muted = Colors.white.withValues(alpha: 0.75);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
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
        child: _Unreachable(message: error, onRetry: controller.load),
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
            if (i > 0) const SizedBox(height: 22),
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
        AppEntrance(index: titleIndex, child: AppText.titleMedium(title)),
        const SizedBox(height: 10),
        child,
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
    final fines = Formatters.money(activity.finesAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Grid(
          firstIndex: firstIndex,
          extent: AppStatTile.extent,
          children: [
            AppStatTile(
              label: 'Visits',
              value: '${activity.visits}',
              icon: Icons.directions_walk_rounded,
            ),
            AppStatTile(
              label: 'Fines imposed',
              value: '${activity.finesImposed}',
              icon: Icons.gavel_rounded,
            ),
            AppStatTile(
              label: 'Shops sealed',
              value: '${activity.shopsSealed}',
              icon: Icons.lock_outline_rounded,
            ),
            AppStatTile(
              label: 'Seals released',
              value: '${activity.sealsReleased}',
              icon: Icons.lock_open_outlined,
            ),
          ],
        ),
        if (fines != null) ...[
          const SizedBox(height: 12),
          _MoneyCard(
            icon: Icons.gavel_rounded,
            title: 'Value of fines imposed',
            value: fines,
            notes: <String>[
              'Across ${activity.finesImposed} fines in the last '
                  '${activity.periodDays} days.',
            ],
          ),
        ],
        if (activity.collectedInYourAreas != null) ...[
          const SizedBox(height: 12),
          _CollectedCard(activity: activity, scope: scope),
        ],
        if (activity.byActionType.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionTitle('How far things went'),
          const SizedBox(height: 12),
          ActionBreakdown(byActionType: activity.byActionType),
        ],
      ],
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.notes,
  });

  final IconData icon;
  final String title;
  final String value;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(child: AppText.titleMedium(title, maxLines: 1)),
            ],
          ),
          const SizedBox(height: 12),
          AppText.headlineMedium(value, maxLines: 1),
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
      value: Formatters.money(activity.collectedInYourAreas)!,
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
        for (final FieldQueue queue in queues) BeatQueueTile(queue: queue),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => AppText.titleMedium(title);
}

/// The whole screen failed and there is nothing to show behind it.
class _Unreachable extends StatelessWidget {
  const _Unreachable({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    // Not a scroll view of its own: it sits inside the page's, which is what
    // keeps pull-to-refresh working on the very state an officer most wants to
    // retry from.
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load your beat',
            message: message,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            fullWidth: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
