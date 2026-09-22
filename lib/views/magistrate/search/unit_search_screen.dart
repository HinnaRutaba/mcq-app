import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/unit_search_controller.dart';
import '../../../models/map_pins.dart';
import '../../../models/unit_card.dart';
import '../../../widgets/widgets.dart';
import 'widgets/pin_card.dart';
import 'widgets/unit_map.dart';
import 'widgets/unit_tile.dart';

/// Finding any shop on the register — `enforcement/field/units`.
///
/// Its own page rather than a box on Home, because a search is a list: the
/// officer types a shop number, reads what came back and opens one of them.
/// It grows out of Home's search action (see `AppContainerPage`), so the page
/// is plainly that circle opened rather than a screen arriving over it.
///
/// The same shops can be read as a map instead — `reporting/map`, one pin per
/// unit the register could place. The search box does not change: it finds the
/// shop and the camera flies to it.
class UnitSearchScreen extends StatefulWidget {
  const UnitSearchScreen({super.key});

  /// The title line and the search box under it.
  static const double _headerHeight = 118;

  @override
  State<UnitSearchScreen> createState() => _UnitSearchScreenState();
}

class _UnitSearchScreenState extends State<UnitSearchScreen> {
  late final UnitSearchController controller = Get.put(UnitSearchController());

  final FocusNode _focus = FocusNode();

  /// The route's own opening animation, held so the listener can be taken off
  /// it again — the officer may leave before the page has finished arriving.
  Animation<double>? _opening;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnceOpen());
  }

  /// The keyboard waits for the page to finish growing out of the circle that
  /// opened it: raised on the first frame it fights the transition, and the
  /// officer watches a search box jump.
  void _focusOnceOpen() {
    if (!mounted) return;
    final Animation<double>? opening = ModalRoute.of(context)?.animation;
    if (opening == null || opening.isCompleted) {
      _focus.requestFocus();
      return;
    }
    _opening = opening..addStatusListener(_handleOpened);
  }

  void _handleOpened(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _opening?.removeStatusListener(_handleOpened);
    _opening = null;
    if (mounted) _focus.requestFocus();
  }

  @override
  void dispose() {
    _opening?.removeStatusListener(_handleOpened);
    _focus.dispose();
    Get.delete<UnitSearchController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(() {
          final bool onMap = controller.onMap.value;

          return CustomScrollView(
            // The map owns the whole viewport and every drag across it; there
            // is nothing under it to scroll to.
            physics: onMap
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              AppSliverHeroHeader(
                title: 'Find a shop',
                expandedHeight: UnitSearchScreen._headerHeight,
                compactTitle: true,
                leading: AppHeaderBackButton(onTap: () => context.pop()),
                trailing: AppCircleIconButton(
                  icon: onMap
                      ? Icons.format_list_bulleted_rounded
                      : Icons.map_outlined,
                  onTap: () => controller.showMap(!onMap),
                ),
                bottomSpacing: 16,
                // The circle on Home stretches into this box — see
                // [AppSearchHero].
                bottom: AppSearchHero(
                  child: AppSearchField(
                    controller: controller.searchController,
                    focusNode: _focus,
                    hint: 'Shop, code, holder or CNIC',
                    onChanged: controller.search,
                  ),
                ),
              ),
              AppPinnedBar(
                height: _Summary.height,
                // Read here, inside the `Obx`, and handed over as plain values.
                child: _Summary(
                  line: _summary(controller),
                  // Only over something that is already up — with nothing on
                  // screen the body has a spinner of its own.
                  showProgress: onMap
                      ? controller.isLoadingPins.value && controller.hasPins
                      : controller.isLoading.value && controller.hasData,
                ),
              ),
              if (onMap)
                ..._mapSlivers(context, controller)
              else
                ..._listSlivers(context, controller),
            ],
          );
        }),
      ),
    );
  }
}

/// What is on screen, over what is on screen.
String _summary(UnitSearchController controller) {
  if (controller.onMap.value) {
    if (controller.isLoadingPins.value && !controller.hasPins) {
      return 'Placing the shops…';
    }
    // The search still runs on the map; it just moves the camera instead of
    // shortening a list, so a term that found nothing has to be said here.
    if (controller.isSearching &&
        controller.units.isEmpty &&
        !controller.isLoading.value) {
      return 'No shop matches';
    }
    if (!controller.hasPins) return '';

    final int placed = controller.placed.length;
    final int unmapped = controller.pins.value?.meta.unmapped ?? 0;
    final String pins = '$placed ${placed == 1 ? 'shop' : 'shops'} placed';
    return unmapped == 0 ? pins : '$pins · $unmapped without a fix';
  }

  if (controller.isLoading.value && !controller.hasData) {
    return 'Reading the register…';
  }
  // Nothing on the list: the empty state under this says it better than a
  // count of nothing does.
  if (!controller.hasData) return '';

  final int count = controller.units.length;
  if (controller.isSearching) {
    return '$count ${count == 1 ? 'match' : 'matches'}';
  }
  return '$count ${count == 1 ? 'shop' : 'shops'} on your beat';
}

class _Summary extends StatelessWidget {
  const _Summary({required this.line, required this.showProgress});

  final String line;
  final bool showProgress;

  /// A caption line and the progress hair under it.
  static const double height = 34;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppText.caption(line, color: muted, maxLines: 1),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 2,
          child: showProgress
              ? const LinearProgressIndicator(minHeight: 2)
              : null,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// The bazaar as a map

List<Widget> _mapSlivers(
  BuildContext context,
  UnitSearchController controller,
) {
  if (controller.isLoadingPins.value && !controller.hasPins) {
    return const <Widget>[
      SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
    ];
  }

  final String? error = controller.pinsError.value;
  if (error != null && !controller.hasPins) {
    return <Widget>[
      SliverFillRemaining(
        child: AppErrorRetry(
          title: 'Could not place the shops',
          message: error,
          onRetry: controller.loadPins,
        ),
      ),
    ];
  }

  if (!controller.hasPins) {
    return <Widget>[
      SliverFillRemaining(
        child: AppEmptyState(
          icon: Icons.location_off_outlined,
          title: 'Nothing to place',
          message:
              'No unit in your bazaars carries coordinates yet'
              '${_unmappedNote(controller)}.',
        ),
      ),
    ];
  }

  final MapPin? selected = controller.selectedPin.value;
  final UnitCard? unit = selected == null ? null : controller.unitFor(selected);

  return <Widget>[
    SliverFillRemaining(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: UnitMap(
              pins: controller.placed,
              selected: selected,
              onTapPin: controller.selectPin,
              onTapMap: () => controller.selectPin(null),
            ),
          ),
          if (selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              // Keyed by the pin, so moving from one shop to the next brings
              // the card in again rather than swapping the words inside it.
              child: AppEntrance(
                key: ValueKey<Object>(
                  selected.propertyId ?? selected.propertyCode ?? 'pin',
                ),
                child: PinCard(
                  pin: selected,
                  unit: unit,
                  onClose: () => controller.selectPin(null),
                  onOpen: selected.propertyId == null
                      ? null
                      : () => context.push(
                          AppRoutes.propertyProfilePath(selected.propertyId!),
                          // The profile draws its header from this while its
                          // own calls are still out. Null where the pin came
                          // back from a list the search has not read.
                          extra: unit?.asDefaulterCard(),
                        ),
                ),
              ),
            ),
        ],
      ),
    ),
  ];
}

String _unmappedNote(UnitSearchController controller) {
  final int unmapped = controller.pins.value?.meta.unmapped ?? 0;
  return unmapped == 0 ? '' : ' — $unmapped are on the register without one';
}

// ---------------------------------------------------------------------------
// The bazaar as a list

List<Widget> _listSlivers(
  BuildContext context,
  UnitSearchController controller,
) {
  // Nothing on screen yet: one spinner, not a half-drawn list.
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
          title: 'Could not search the register',
          message: error,
          onRetry: controller.load,
        ),
      ),
    ];
  }

  final List<UnitCard> rows = controller.units;
  if (rows.isEmpty) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: controller.isSearching
            ? const AppEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No shop matches',
                message:
                    'Try the shop number, the property code, the holder’s '
                    'name or their CNIC.',
              )
            : const AppEmptyState(
                icon: Icons.storefront_outlined,
                title: 'Nothing on the register',
                message: 'No units came back for your bazaars.',
              ),
      ),
    ];
  }

  // A failure over rows that are already up rides at the top of the list: it
  // is a note, not a wall, and the rows below it are the last good ones.
  final int alert = error == null ? 0 : 1;

  return <Widget>[
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
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

          final UnitCard card = rows[index - alert];
          final int? propertyId = card.propertyId;

          // Keyed by the unit, so a row keeps its element as the officer
          // types: unkeyed, every rebuild would restart the entrance and the
          // list would flicker on each keystroke.
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppEntrance(
              key: ValueKey<Object>(
                propertyId ?? card.propertyCode ?? card.allotmentNo ?? index,
              ),
              index: index,
              child: UnitTile(
                card: card,
                onTap: propertyId == null
                    ? null
                    : () => context.push(
                        AppRoutes.propertyProfilePath(propertyId),
                        // The profile draws its header from this while its own
                        // calls are still out.
                        extra: card.asDefaulterCard(),
                      ),
              ),
            ),
          );
        },
      ),
    ),
  ];
}
