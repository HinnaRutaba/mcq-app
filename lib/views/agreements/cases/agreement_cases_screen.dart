import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/agreement_cases_controller.dart';
import '../../../models/agreement_case.dart';
import '../../../models/agreement_requests.dart';
import '../../../widgets/widgets.dart';
import '../agreements_shell.dart';
import '../shared/widgets/intake_card.dart';

/// The reviewer's case lists: `allotment/intakes?scope=…`, paged.
class AgreementCasesScreen extends StatelessWidget {
  const AgreementCasesScreen({super.key});

  static const double _headerHeight = 130;
  static const double _prefetchExtent = 600;

  @override
  Widget build(BuildContext context) {
    final AgreementCasesController controller =
        Get.find<AgreementCasesController>();

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
                  title: 'Cases',
                  expandedHeight: _headerHeight,
                  compactTitle: true,
                  leading: AppHeaderBackButton(
                    onTap: () => AgreementsShell.goHome(context),
                  ),
                  bottom: AppSearchField(
                    controller: controller.searchController,
                    hint: 'Case no, applicant, CNIC or shop',
                    onChanged: controller.setSearch,
                  ),
                ),
                AppPinnedBar(
                  height: _Tabs.height,
                  child: _Tabs(controller: controller),
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

List<Widget> _slivers(
  BuildContext context,
  AgreementCasesController controller,
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

  final List<AgreementCase> rows = controller.cases.toList();
  if (rows.isEmpty) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: controller.isSearching
            ? const AppEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No case matches',
                message: 'Try the case number, a CNIC (5+ digits) or the shop.',
              )
            : AppEmptyState(
                icon: Icons.inbox_outlined,
                title: 'No cases here',
                message: _emptyLine(controller.query.value),
              ),
      ),
    ];
  }

  // Old rows stay up under a failed refresh, with the retry over them.
  final List<Widget> lead = <Widget>[
    if (error != null)
      AppPress(
        onTap: controller.load,
        child: AppAlert(
          message: '$error Tap to retry.',
          tone: AppTone.warning,
          icon: Icons.refresh_rounded,
        ),
      ),
  ];

  return <Widget>[
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      sliver: AppSliverTiles(
        lead: lead,
        itemCount: rows.length,
        itemBuilder: (BuildContext context, int index) {
          final AgreementCase file = rows[index];
          return AppEntrance(
            key: ValueKey<String>(file.id),
            index: index,
            child: IntakeCard(
              file: file,
              onTap: () => context.push(
                AppRoutes.agreementCasePath(file.id),
                extra: file,
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

String _emptyLine(IntakeListQuery query) => switch (query.scope) {
  'awaiting_me' => 'Nothing is waiting for you.',
  'returned_by_me' => 'Nothing you returned or queried is still away.',
  'decided_by_me' => 'You have not decided a case yet.',
  _ => 'No case in this list.',
};

class _Tabs extends StatelessWidget {
  const _Tabs({required this.controller});

  final AgreementCasesController controller;

  static const double height = 58;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AppChipTabs<IntakeListQuery>(
                items: controller.tabs,
                itemLabel: (IntakeListQuery q) => q.label,
                selected: controller.query.value,
                onChanged: controller.showQuery,
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
      ),
    );
  }
}
