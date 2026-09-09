import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/seals_controller.dart';
import '../../../models/field_seal.dart';
import '../../../widgets/widgets.dart';
import 'widgets/seal_tile.dart';

class SealedScreen extends StatelessWidget {
  const SealedScreen({super.key});

  static const double _headerHeight = 130;

  @override
  Widget build(BuildContext context) {
    final SealsController controller = Get.find<SealsController>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(
          () => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              AppSliverHeroHeader(
                title: 'Sealed Shops',
                expandedHeight: _headerHeight,
                compactTitle: true,
                bottom: AppSearchField(
                  controller: controller.searchController,
                  hint: 'Shop, holder, seal or case number',
                  onChanged: controller.search,
                ),
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
    );
  }
}

List<Widget> _slivers(BuildContext context, SealsController controller) {
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
          title: 'Could not load the seals',
          message: error,
          onRetry: controller.load,
        ),
      ),
    ];
  }

  final List<FieldSeal> rows = controller.visible;
  if (rows.isEmpty) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        // Read here, inside the `Obx`, and handed over as plain values.
        child: _Nothing(
          queue: controller.queue.value,
          searching: controller.isSearching,
          onClear: controller.clearSearch,
        ),
      ),
    ];
  }

  // A failure over rows that are already up rides at the top of the list: it
  // is a note, not a wall, and the rows below it are the last good ones.
  final int alert = error == null ? 0 : 1;

  return <Widget>[
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
      sliver: SliverList.builder(
        itemCount: rows.length + alert,
        itemBuilder: (BuildContext context, int index) {
          if (index < alert) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppAlert(
                message: error!,
                tone: AppTone.warning,
                icon: Icons.wifi_off_rounded,
              ),
            );
          }

          final FieldSeal seal = rows[index - alert];
          final int? propertyId = seal.propertyId;

          // Keyed by the seal, so a row keeps its element as the officer
          // types: unkeyed, every rebuild would restart the entrance and the
          // list would flicker on each keystroke.
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppEntrance(
              key: ValueKey<Object>(seal.id ?? seal.sealNo ?? index),
              index: index,
              child: SealTile(
                seal: seal,
                readyToRelease: controller.isReady(seal),
                // Through to the shop: this screen reads the register.
                onTap: propertyId == null
                    ? null
                    : () => context.push(
                        AppRoutes.propertyProfilePath(propertyId),
                      ),
              ),
            ),
          );
        },
      ),
    ),
  ];
}

/// The two readings of the register, and the thin bar that says a refresh is
/// in flight over rows already up.
class _Filters extends StatelessWidget {
  const _Filters({required this.controller});

  final SealsController controller;

  /// Fixed: nothing here grows, unlike the defaulters bar and its bazaars.
  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 28),
        Obx(() {
          final Map<SealQueue, int> counts = <SealQueue, int>{
            for (final SealQueue queue in SealQueue.values)
              queue: controller.countOf(queue),
          };

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AppChipTabs<SealQueue>(
              items: SealQueue.values,
              itemLabel: (SealQueue queue) =>
                  '${queue.label} · ${counts[queue]}',
              selected: controller.queue.value,
              onChanged: controller.showQueue,
              compact: true,
            ),
          );
        }),
        const SizedBox(height: 10),
        Obx(
          () => SizedBox(
            height: 2,
            child: controller.isLoading.value && controller.hasData
                ? const LinearProgressIndicator(minHeight: 2)
                : null,
          ),
        ),
      ],
    );
  }
}

/// An empty list, which here means one of three different things.
class _Nothing extends StatelessWidget {
  const _Nothing({
    required this.queue,
    required this.searching,
    required this.onClear,
  });

  final SealQueue queue;

  /// Whether the search box is what emptied the list.
  final bool searching;

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (searching) {
      // The box that emptied the list is above this, but the way out of a dead
      // end belongs in the dead end.
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No seals match',
              message: 'Nothing on this list answers to that.',
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Clear search',
              icon: Icons.filter_alt_off_outlined,
              variant: AppButtonVariant.outline,
              fullWidth: false,
              onPressed: onClear,
            ),
          ],
        ),
      );
    }

    // Not a dead end but an answer, and the two queues answer differently.
    return switch (queue) {
      SealQueue.all => const AppEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Nothing is sealed',
        message: 'No shop in your bazaars is under seal.',
      ),
      SealQueue.ready => const AppEmptyState(
        icon: Icons.lock_open_outlined,
        title: 'Nothing to release',
        message:
            'A seal appears here once every fine on the unit is settled and '
            'one has been paid.',
      ),
    };
  }
}
