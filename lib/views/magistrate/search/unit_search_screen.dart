import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/unit_search_controller.dart';
import '../../../models/unit_card.dart';
import '../../../widgets/widgets.dart';
import 'widgets/unit_tile.dart';


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

  /// The keyboard waits for the page to finish growing out of the box that
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
        child: Obx(
          () => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              AppSliverHeroHeader(
                title: 'Find a shop',
                expandedHeight: UnitSearchScreen._headerHeight,
                compactTitle: true,
                leading: AppHeaderBackButton(onTap: () => context.pop()),
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
                  count: controller.units.length,
                  isLoading: controller.isLoading.value,
                  isSearching: controller.isSearching,
                  hasData: controller.hasData,
                ),
              ),
              ..._slivers(context, controller),
            ],
          ),
        ),
      ),
    );
  }
}

/// What is on the list, over the list.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.count,
    required this.isLoading,
    required this.isSearching,
    required this.hasData,
  });

  final int count;
  final bool isLoading;
  final bool isSearching;
  final bool hasData;

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
          child: AppText.caption(_line, color: muted, maxLines: 1),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 2,
          // Only over rows that are already up — with nothing on screen the
          // list has a spinner of its own.
          child: isLoading && hasData
              ? const LinearProgressIndicator(minHeight: 2)
              : null,
        ),
      ],
    );
  }

  String get _line {
    if (isLoading && !hasData) return 'Reading the register…';
    // Nothing on the list: the empty state under this says it better than a
    // count of nothing does.
    if (!hasData) return '';
    if (isSearching) return '$count ${count == 1 ? 'match' : 'matches'}';
    return '$count ${count == 1 ? 'shop' : 'shops'} on your beat';
  }
}

List<Widget> _slivers(BuildContext context, UnitSearchController controller) {
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
