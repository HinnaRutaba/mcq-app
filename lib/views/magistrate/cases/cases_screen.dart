import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/cases_controller.dart';
import '../../../controllers/property_profile_controller.dart';
import '../../../models/enforcement_case.dart';
import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';
import '../shared/widgets/case_card.dart';

/// The case register: every enforcement file open across the beat, and the
/// ones the taxation branch put in this officer's name.
///
/// Reached from the two case queues on Home and from the More hub. A row goes
/// through to the shop the case is about, on its Cases tab — the file itself
/// is read there, against the rest of the shop's paperwork.
class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key});

  /// A title and nothing else, so no taller than the title needs: the count
  /// is at the foot of the list, where the officer finishes reading it.
  static const double _headerHeight = 86;

  static const double _prefetchExtent = 600;

  @override
  Widget build(BuildContext context) {
    final CasesController controller = Get.find<CasesController>();

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
                const AppSliverHeroHeader(
                  title: 'Cases',
                  expandedHeight: _headerHeight,
                  compactTitle: true,
                  leading: BackToHomeButton(),
                ),
                AppPinnedBar(
                  height: _Filters.height,
                  child: _Filters(controller: controller),
                ),
                ..._slivers(context, controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _slivers(BuildContext context, CasesController controller) {
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
          title: 'Could not load the cases',
          message: error,
          onRetry: controller.load,
        ),
      ),
    ];
  }

  final List<EnforcementCase> rows = controller.cases.toList();

  if (rows.isEmpty) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        // Read here, inside the `Obx`, and handed over as plain values.
        child: _Nothing(
          filter: controller.filter.value,
          onShowAll: () => controller.showFilter(CaseFilter.all),
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

          final EnforcementCase file = rows[index - lead.length];
          final int? propertyId = file.property?.id;

          // Keyed by the file, so a row keeps its element as pages append:
          // unkeyed, every rebuild would restart the entrance and the list
          // would flicker each time the next page lands.
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppEntrance(
              key: ValueKey<Object>(file.id ?? file.caseNo ?? index),
              index: index,
              child: CaseCard(
                file: file,
                // The register spans the beat, so every row has to say which
                // shopfront it is about.
                showSubject: true,
                hint: propertyId == null ? null : 'tap to open the shop',
                onTap: propertyId == null
                    ? null
                    : () => context.push(
                        // Straight to the shop's own cases: the officer got
                        // here by tapping one of them.
                        AppRoutes.propertyProfilePath(
                          propertyId,
                          tab: ProfileTab.cases.name,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
      sliver: SliverToBoxAdapter(
        child: AppListFooter(
          hasMore: controller.hasMore,
          isLoadingMore: controller.isLoadingMore.value,
          total: controller.total,
          onLoadMore: controller.loadMore,
        ),
      ),
    ),
  ];
}

/// The bar over the list: the whole register, or this officer's own files.
///
/// No counts on the chips — each is a different request to the server, so the
/// rows for the one an officer is not looking at are not in hand and a figure
/// here would be a guess.
class _Filters extends StatelessWidget {
  const _Filters({required this.controller});

  final CasesController controller;

  /// 14 over the chips, a compact chip row, 10 under it, and the progress hair.
  static const double height = 58;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AppChipTabs<CaseFilter>(
              items: CaseFilter.values,
              itemLabel: (CaseFilter filter) => filter.label,
              selected: controller.filter.value,
              onChanged: controller.showFilter,
              compact: true,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 2,
            child: controller.isLoading.value && controller.hasData
                ? const LinearProgressIndicator(minHeight: 2)
                : null,
          ),
        ],
      ),
    );
  }
}

/// An empty list, which here means one of two different things.
class _Nothing extends StatelessWidget {
  const _Nothing({required this.filter, required this.onShowAll});

  final CaseFilter filter;

  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    if (filter == CaseFilter.all) {
      return const AppEmptyState(
        icon: Icons.folder_off_outlined,
        title: 'No cases are open',
        message: 'No enforcement file is open in your bazaars.',
      );
    }

    // Not a dead end: the register itself may well have rows in it, and the
    // way onto them belongs where the officer met the empty list.
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const AppEmptyState(
            icon: Icons.assignment_ind_outlined,
            title: 'Nothing in your name',
            message: 'No case has been assigned to you.',
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Show all cases',
            icon: Icons.filter_alt_off_outlined,
            variant: AppButtonVariant.outline,
            fullWidth: false,
            onPressed: onShowAll,
          ),
        ],
      ),
    );
  }
}
