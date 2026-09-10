import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/follow_ups_controller.dart';
import '../../../data/repositories/defaulters_repository.dart';
import '../../../models/defaulter_card.dart';
import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';
import '../shared/widgets/defaulter_tile.dart';

/// The promises: the ones due or already broken, and the ones still ahead.
///
/// Reached from the follow-ups queue on Home and from the More hub. Its rows
/// are the same cards the defaulter list draws, because they are the same
/// shape from the same beat — but they are this endpoint's own rows, so the
/// figure on the tile and the length of this list are the same fact.
class FollowUpsScreen extends StatelessWidget {
  const FollowUpsScreen({super.key});

  /// A title and nothing else.
  static const double _headerHeight = 86;

  @override
  Widget build(BuildContext context) {
    final FollowUpsController controller = Get.find<FollowUpsController>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(
          () => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              const AppSliverHeroHeader(
                title: 'Follow-ups',
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
    );
  }
}

List<Widget> _slivers(BuildContext context, FollowUpsController controller) {
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
          title: 'Could not load the follow-ups',
          message: error,
          onRetry: controller.load,
        ),
      ),
    ];
  }

  final List<DefaulterCard> rows = controller.followUps.toList();

  if (rows.isEmpty) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        // Read here, inside the `Obx`, and handed over as a plain value.
        child: _Nothing(state: controller.state.value),
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

          // Keyed by the unit, so a row keeps its element when the reading is
          // switched: unkeyed, every rebuild would restart the entrance.
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

/// The bar over the list: the promises that have come due, or those still to
/// come.
///
/// No counts on the chips — each is a different request to the server, so the
/// rows for the one an officer is not looking at are not in hand and a figure
/// here would be a guess.
class _Filters extends StatelessWidget {
  const _Filters({required this.controller});

  final FollowUpsController controller;

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
            child: AppChipTabs<FollowUpState>(
              items: FollowUpState.values,
              itemLabel: _label,
              selected: controller.state.value,
              onChanged: controller.showState,
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

  static String _label(FollowUpState state) => switch (state) {
    FollowUpState.due => 'Due now',
    FollowUpState.upcoming => 'Still ahead',
  };
}

/// An empty list, which here means one of two different things.
class _Nothing extends StatelessWidget {
  const _Nothing({required this.state});

  final FollowUpState state;

  @override
  Widget build(BuildContext context) => switch (state) {
    FollowUpState.due => const AppEmptyState(
      icon: Icons.event_available_outlined,
      title: 'Nothing due',
      message: 'No promise has come due, and none has been broken.',
    ),
    FollowUpState.upcoming => const AppEmptyState(
      icon: Icons.event_repeat_outlined,
      title: 'Nothing promised ahead',
      message: 'No shopkeeper has promised to pay on a date still to come.',
    ),
  };
}
