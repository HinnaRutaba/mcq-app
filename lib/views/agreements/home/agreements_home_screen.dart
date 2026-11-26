import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_radius.dart';
import '../../../controllers/agreement_cases_controller.dart';
import '../../../controllers/agreement_dashboard_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/screen_type.dart';
import '../../../models/agreement_dashboard.dart';
import '../../../widgets/widgets.dart';
import 'widgets/intake_series.dart';
import 'widgets/intake_tile_card.dart';

/// The CMO's and the Administrator's home: `allotment/intakes/dashboard`.
class AgreementsHomeScreen extends StatelessWidget {
  const AgreementsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AgreementDashboardController controller =
        Get.find<AgreementDashboardController>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(
          () => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              AppSliverHeroHeader(
                expandedHeight: 86,
                subtitle: controller.officer?.designation ?? 'Signed in',
                title: controller.officer?.name ?? 'Home',
                trailing: AppCircleIconButton(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.dangerOnDark,
                  onTap: () => AppSignOutDialog.confirmAndSignOut(context),
                ),
              ),
              ..._body(context, controller),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> _body(
  BuildContext context,
  AgreementDashboardController controller,
) {
  if (controller.isLoading.value && !controller.hasData) {
    return const <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ];
  }

  final String? error = controller.errorMessage.value;
  final AgreementDashboard? data = controller.dashboard.value;
  if (data == null) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorRetry(
          title: 'Could not load your cases',
          message: error ?? 'Nothing came back.',
          onRetry: controller.load,
        ),
      ),
    ];
  }

  final int columns = context.isMobile ? 2 : 4;
  void open(IntakeTile tile, String label) {
    AgreementCasesController.open(controller.queryFor(tile, label: label));
    context.go(AppRoutes.agreementsCases);
  }

  Widget card(IntakeTile tile) => IntakeTileCard(
    tile: tile,
    label: IntakeTileCard.labelFor(tile),
    icon: IntakeTileCard.iconFor(tile.key),
    onTap: () => open(tile, IntakeTileCard.labelFor(tile)),
  );

  Widget tiles(List<IntakeTile> source, {required int first}) => _Grid(
    columns: columns,
    firstIndex: first,
    children: <Widget>[for (final IntakeTile tile in source) card(tile)],
  );

  final IntakeTile waiting = IntakeTile(
    key: IntakeScope.awaitingMe,
    count: data.waitingTotal,
    scope: data.waitingScope,
  );
  final List<IntakeTile> now = <IntakeTile>[
    ...data.queues,
    // Unsplit by the server: the total is the only tile there is.
    if (data.queues.isEmpty && data.waitingTotal > 0) waiting,
    ?data.returnedByMe,
  ];
  final IntakeRegister? register = data.register;

  final List<Widget> sections = <Widget>[];
  int step = 0;

  if (error != null) {
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

  sections.add(
    _Section(
      key: const ValueKey<String>('waiting'),
      title: 'Waiting for you',
      titleIndex: step++,
      trailing: data.waitingTotal > 0
          ? AppPress(
              onTap: () => open(waiting, IntakeTileCard.labelFor(waiting)),
              child: AppStatusBadge(
                label: 'All',
                count: data.waitingTotal,
                tone: AppTone.primary,
                filled: true,
                minWidth: 80,
              ),
            )
          : null,
      child: data.nothingWaiting
          ? AppEntrance(
              index: step,
              child: const AppEmptyState.compact(
                art: AppCaughtUpArt(),
                title: 'You’re all caught up',
                message:
                    'Nothing is waiting for you. Cases sent to you '
                    'for review appear here.',
              ),
            )
          : tiles(now, first: step),
    ),
  );
  step += now.length;

  sections.add(
    _Section(
      key: const ValueKey<String>('done'),
      title: 'What you did',
      titleIndex: step++,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppChipTabs<IntakePeriod>(
            items: IntakePeriod.values,
            itemLabel: (IntakePeriod p) => p.label,
            selected: controller.period.value,
            onChanged: controller.setPeriod,
            compact: true,
          ),
          const SizedBox(height: 12),
          if (data.myActions.isEmpty)
            const AppEmptyState(
              icon: Icons.history_rounded,
              title: 'Nothing in this period',
              message: 'The acts you take on cases are counted here.',
            )
          else
            AppEntrance(
              index: step,
              child: _ChartCard(
                padding: EdgeInsets.zero,
                // Keeps the end rows' ripples inside the rounded corners.
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Column(
                    children: <Widget>[
                      for (final IntakeTile a in data.myActions) ...<Widget>[
                        _actionTile(context, a, open),
                        const Divider(height: 1, indent: 70),
                      ],
                      _actionTile(context, data.cancelled, open),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
  step += 2;

  if (register != null) {
    final List<IntakeTile> statuses =
        register.byStatus.where((IntakeTile t) => !t.isEmpty).toList()..sort(
          (IntakeTile a, IntakeTile b) => IntakeSeries.statusOrder(
            a.key,
          ).compareTo(IntakeSeries.statusOrder(b.key)),
        );
    sections.add(
      _Section(
        key: const ValueKey<String>('register'),
        title: 'The register',
        titleIndex: step++,
        child: Column(
          children: <Widget>[
            AppEntrance(
              index: step,
              child: AppFigureStrip(
                figures: <StripFigure>[
                  StripFigure(
                    value: register.inProgress,
                    label: 'In progress',
                    icon: Icons.pending_actions_rounded,
                    tone: AppTone.info,
                  ),
                  StripFigure(
                    value: register.activatedCases,
                    label: 'Activated',
                    icon: Icons.task_alt_rounded,
                    tone: AppTone.success,
                  ),
                  // A fact, not a state: it wears the plate's ink.
                  StripFigure(
                    value: register.agreementsLive,
                    label: 'Agreements live',
                    icon: Icons.handshake_outlined,
                  ),
                ],
              ),
            ),
            if (statuses.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              AppEntrance(
                index: step + 1,
                child: _ChartCard(
                  child: AppDonutChart(
                    total: register.total,
                    totalLabel: 'cases',
                    slices: <DonutSlice>[
                      for (final IntakeTile t in statuses)
                        DonutSlice(
                          label: IntakeTileCard.labelFor(t),
                          value: t.count,
                          color: IntakeSeries.status(context, t.key),
                          onTap: () => open(t, IntakeTileCard.labelFor(t)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  if (data.generatedAt != null) {
    sections.add(
      AppText.caption(
        'Figures as of ${Formatters.dateTime(data.generatedAt!.toLocal())}',
        textAlign: TextAlign.center,
      ),
    );
  }

  return <Widget>[
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      sliver: SliverList.list(
        children: <Widget>[
          for (int i = 0; i < sections.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 22),
            sections[i],
          ],
        ],
      ),
    ),
  ];
}

Widget _actionTile(
  BuildContext context,
  IntakeTile a,
  void Function(IntakeTile, String) open,
) {
  final String label = IntakeTileCard.labelFor(a);
  final int? acts = a.acts;
  // A case endorsed, returned and endorsed again is 1 case, 2 acts.
  final String note = acts != null && acts != a.count
      ? '${IntakeTileCard.noteFor(a.key)} · $acts acts'
      : IntakeTileCard.noteFor(a.key);
  final Color muted =
      Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5) ??
      Colors.grey;
  final String? tag = IntakeTileCard.tagFor(a.key);
  return MoreMenuTile(
    icon: IntakeTileCard.iconFor(a.key),
    title: label,
    subtitle: note,
    badge: tag == null
        ? null
        : AppStatusBadge(
            label: tag,
            tone: tag == 'Pending' ? AppTone.warning : AppTone.info,
            minHeight: 22,
          ),
    tint: a.isEmpty ? muted : null,
    bare: true,
    trailing: AppText.titleLarge(
      '${a.count}',
      color: a.isEmpty ? muted : null,
      fontWeight: FontWeight.w700,
    ),
    onTap: () => open(a, label),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    required this.titleIndex,
    required this.child,
    this.trailing,
  });

  final String title;
  final int titleIndex;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppEntrance(
          index: titleIndex,
          child: AppSectionTitle(title, trailing: trailing),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

/// The plate a chart sits on — the stat tiles' own lift and corner.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      lift: AppLift.soft,
      radius: AppRadius.lg,
      padding: padding,
      borderColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
      child: child,
    );
  }
}

/// Fixed-height cells, so a tile with a two-line label lines up with its
/// neighbour.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.children,
    required this.columns,
    required this.firstIndex,
  });

  final List<Widget> children;
  final int columns;
  final int firstIndex;

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
        mainAxisExtent: IntakeTileCard.extent,
      ),
      itemBuilder: (BuildContext context, int index) =>
          AppEntrance(index: firstIndex + index, child: children[index]),
    );
  }
}
