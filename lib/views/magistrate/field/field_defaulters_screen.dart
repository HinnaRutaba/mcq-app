import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/field/beat_controller.dart';
import '../../../controllers/field/field_defaulters_controller.dart';
import '../../../core/utils/dialer.dart';
import '../../../core/utils/get_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/field/beat.dart';
import '../../../widgets/widgets.dart';
import 'widgets/beat_header.dart';
import 'widgets/field_card_tile.dart';
import 'widgets/field_list_view.dart';

/// The defaulters list — the heart of the app.
///
/// Every row is a card that carries everything needed to decide **without
/// opening anything**, and among the pills on it is the commitment: who
/// promised what, on which date, and how many days are left. That is the
/// whole reason this list was worth rebuilding.
///
/// The controls above it are a search field and a row of filter chips, both
/// pinned — a filter the officer has to scroll back up to change is a
/// filter he leaves wrong. **Every chip carries its count**, so he learns
/// that a filter is empty before he taps into an empty list rather than
/// after.
class FieldDefaultersScreen extends StatefulWidget {
  const FieldDefaultersScreen({super.key});

  @override
  State<FieldDefaultersScreen> createState() => _FieldDefaultersScreenState();
}

class _FieldDefaultersScreenState extends State<FieldDefaultersScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(FieldDefaultersController.resolve);
    // The area chips come from the beat's scope — a convenience on top of
    // a server control, never a substitute for it.
    final beat = Get.isRegistered<BeatController>()
        ? Get.find<BeatController>()
        : null;

    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge(t('defaulters.title')),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.map),
            icon: const Icon(Icons.map_outlined),
            tooltip: t('map.title'),
          ),
        ],
      ),
      body: Obx(() {
        final rows = controller.visible;
        final animate = controller.isFirstLoad.value;
        final areas = beat?.scope.areas ?? const <BeatArea>[];

        return FieldListView(
          isLoading: controller.isLoading.value,
          isEmpty: rows.isEmpty && !controller.isLoading.value,
          isStale: controller.isStale.value,
          fetchedAt: controller.fetchedAt.value,
          failureMessage: controller.failure.value?.message,
          onRefresh: () => controller.reload(refreshing: true),
          padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 36),
          pinnedHeader: _Filters(
            controller: controller,
            search: _search,
            areas: areas,
          ),
          header: [
            if (beat != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 12),
                child: ScopeChips(scope: beat.scope, onBand: false),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 12),
              child: Row(
                children: [
                  AppText.bodySmall(
                    t('defaulters.count', args: {'n': '${rows.length}'}),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const Spacer(),
                  if (controller.isFiltered)
                    TextButton.icon(
                      onPressed: () {
                        _search.clear();
                        controller.clearFilters();
                      },
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                      label: AppText.label(t('defaulters.clearFilters')),
                    ),
                ],
              ),
            ),
          ],
          emptyState: _emptyState(controller),
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              // Real spacing between cards, and real elevation on each, so
              // one row is visibly one row. A divider alone gives a list
              // where nothing separates from anything.
              if (i > 0) const SizedBox(height: 12),
              AppStaggerIn(
                index: i,
                enabled: animate,
                child: FieldCardTile(
                  card: rows[i],
                  heroPrefix: 'defaulters',
                  onTap: () => context.push(
                    AppRoutes.propertyProfilePath(rows[i].propertyId),
                    extra: rows[i],
                  ),
                  onCall: rows[i].isCallable
                      ? () => Dialer.call(rows[i].mobileNo)
                      : null,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  /// An empty list is an answer, and which answer it is matters. "Nothing
  /// matched that search" is a different fact from "nobody in your areas is
  /// behind today", and the second one is good news.
  Widget _emptyState(FieldDefaultersController controller) {
    if (controller.isFiltered) {
      return AppEmptyState(
        illustration: AppIllustrationKind.noResults,
        title: t('defaulters.noMatch'),
        message: t('defaulters.noMatchHelp'),
        actionLabel: t('defaulters.clearFilters'),
        onAction: () {
          _search.clear();
          controller.clearFilters();
        },
      );
    }
    return AppEmptyState(
      illustration: AppIllustrationKind.allClear,
      title: t('defaulters.allClear'),
      message: t('defaulters.allClearHelp'),
    );
  }
}

/// Search and the filter chips. Pinned, on the page's own surface, with a
/// hairline under them so they read as a control strip rather than as the
/// first row of the list.
class _Filters extends StatelessWidget {
  const _Filters({
    required this.controller,
    required this.search,
    required this.areas,
  });

  final FieldDefaultersController controller;
  final TextEditingController search;
  final List<BeatArea> areas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 12),
            child: AppSearchField(
              controller: search,
              hint: t('defaulters.searchHint'),
              // The controller already debounces the request by 300ms, so
              // this hands it every keystroke rather than debouncing twice
              // and making the officer wait 600ms for his own list.
              onChanged: controller.searchChanged,
            ),
          ),
          Obx(
            () => AppFilterBar<DefaulterFilter>(
              selected: controller.filter.value,
              onChanged: controller.filterChanged,
              options: [
                for (final filter in DefaulterFilter.values)
                  AppFilterOption(
                    value: filter,
                    label: t('defaulters.filter.${filter.name}'),
                    icon: _iconOf(filter),
                    tone: _toneOf(filter),
                    count: _countOf(controller, filter),
                  ),
              ],
              trailing: [
                for (final area in areas)
                  AppFilterChip(
                    label: area.areaName,
                    icon: Icons.place_rounded,
                    selected: controller.area.value?.id == area.id,
                    onSelected: () => controller.areaChanged(
                      controller.area.value?.id == area.id ? null : area,
                    ),
                  ),
              ],
            ),
          ),
          Divider(color: theme.dividerColor, height: 1),
        ],
      ),
    );
  }

  /// What each chip would leave.
  ///
  /// `never_paid` is a **server** filter — the count for it is not knowable
  /// without asking, and a number invented on the handset here would be a
  /// figure an officer reads as the register's. So it shows none.
  static int? _countOf(
    FieldDefaultersController controller,
    DefaulterFilter filter,
  ) {
    switch (filter) {
      case DefaulterFilter.all:
        return controller.rows.length;
      case DefaulterFilter.promiseBroken:
        return controller.rows.where((row) => row.promiseBroken).length;
      case DefaulterFilter.sealed:
        return controller.rows.where((row) => row.isSealed).length;
      case DefaulterFilter.neverPaid:
        return null;
    }
  }

  static IconData _iconOf(DefaulterFilter filter) {
    switch (filter) {
      case DefaulterFilter.all:
        return Icons.select_all_rounded;
      case DefaulterFilter.neverPaid:
        return Icons.block_rounded;
      case DefaulterFilter.promiseBroken:
        return Icons.warning_amber_rounded;
      case DefaulterFilter.sealed:
        return Icons.lock_rounded;
    }
  }

  /// A selected chip wears the tone of what it selects, so the filter row
  /// speaks the same colour language as the cards under it.
  static AppTone? _toneOf(DefaulterFilter filter) {
    switch (filter) {
      case DefaulterFilter.all:
        return null;
      case DefaulterFilter.neverPaid:
      case DefaulterFilter.sealed:
        return AppTone.danger;
      case DefaulterFilter.promiseBroken:
        return AppTone.warning;
    }
  }
}
