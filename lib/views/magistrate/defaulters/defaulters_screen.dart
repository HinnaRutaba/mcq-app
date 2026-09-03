import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/defaulters_controller.dart';
import '../../../models/defaulter_card.dart';
import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';
import 'widgets/defaulter_filters.dart';
import 'widgets/defaulter_tile.dart';

class DefaultersScreen extends StatelessWidget {
  const DefaultersScreen({super.key});

  static const double _headerHeight = 130;

  @override
  Widget build(BuildContext context) {
    final DefaultersController controller = Get.find<DefaultersController>();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(
          () => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              AppSliverHeroHeader(
                title: 'Defaulters',
                expandedHeight: _headerHeight,
                compactTitle: true,
                leading: const BackToHomeButton(),
                bottom: AppSearchField(
                  controller: controller.searchController,
                  hint: 'Shop, code, allottee or CNIC',
                  onChanged: controller.search,
                ),
              ),
              AppPinnedBar(
                height: DefaulterFilters.heightFor(
                  withAreaPicker: controller.hasAreaChoice,
                ),
                child: DefaulterFilters(controller: controller),
              ),
              ..._slivers(context, controller),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> _slivers(BuildContext context, DefaultersController controller) {
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
          title: 'Could not load the defaulters',
          message: error,
          onRetry: controller.load,
        ),
      ),
    ];
  }

  final List<DefaulterCard> rows = controller.visible;
  if (rows.isEmpty) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        // Read here, inside the `Obx`, and handed over as a plain value.
        child: _Nothing(
          narrowed: controller.isNarrowed,
          onClear: controller.clearFilters,
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

          final DefaulterCard card = rows[index - alert];
          final int? propertyId = card.propertyId;

          // Keyed by the unit, so a row keeps its element as the officer
          // types: unkeyed, every rebuild would restart the entrance and the
          // list would flicker on each keystroke. New rows still arrive with
          // one, because a new unit is a new key.
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppEntrance(
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
                        // The profile draws its header from this while its own
                        // calls are still out.
                        extra: card,
                      ),
              ),
            ),
          );
        },
      ),
    ),
  ];
}

/// An empty list, which means one of two very different things.
class _Nothing extends StatelessWidget {
  const _Nothing({required this.narrowed, required this.onClear});

  /// Whether a filter is what emptied the list.
  final bool narrowed;

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (!narrowed) {
      return const AppEmptyState(
        icon: Icons.storefront_outlined,
        title: 'Nobody is behind',
        message: 'Every shop in your bazaars is paid up.',
      );
    }

    // The filters that emptied the list are above this, but the way out of a
    // dead end belongs in the dead end.
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No shops match',
            message: 'Nothing in this bazaar is in that state.',
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
