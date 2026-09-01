import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../controllers/field/beat_controller.dart';
import '../../../controllers/field/unit_search_controller.dart';
import '../../../core/utils/dialer.dart';
import '../../../core/utils/get_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/field/beat.dart';
import '../../../widgets/widgets.dart';
import 'widgets/field_card_tile.dart';
import 'widgets/field_list_view.dart';

/// Find a unit.
///
/// MCQ's second flow, in their own words: *"magistrate went to a shop and
/// its fine is paid but he still finds it in some illegal and unlawful
/// activity, so he searches for that property in his area and gives a
/// warning."*
///
/// A shop that is fully paid up does not appear in the defaulter list at
/// all, and it is exactly the one he is standing in front of. So there are
/// two tabs, and the second deliberately includes **vacant units**: an
/// encroachment, a hawker on a footpath, a stall in unauthorised use — none
/// of them has an agreement, and a fine against one is the commonest field
/// offence there is.
class UnitSearchScreen extends StatefulWidget {
  const UnitSearchScreen({super.key});

  @override
  State<UnitSearchScreen> createState() => _UnitSearchScreenState();
}

class _UnitSearchScreenState extends State<UnitSearchScreen> {
  final TextEditingController _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(UnitSearchController.resolve);
    final beat = Get.isRegistered<BeatController>()
        ? Get.find<BeatController>()
        : null;

    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(t('find.title'))),
      body: Obx(() {
        final results = controller.results;
        final areas = beat?.scope.areas ?? const <BeatArea>[];

        return FieldListView(
          isLoading: controller.isLoading.value,
          isEmpty: results.isEmpty && !controller.isLoading.value,
          failureMessage: controller.failure.value?.message,
          onRefresh: () => controller.search(refreshing: true),
          padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 36),
          pinnedHeader: _SearchBar(
            controller: controller,
            field: _field,
            areas: areas,
          ),
          emptyState: controller.isIdle
              // Nothing typed yet is not "nothing found". Showing an
              // empty-results illustration here answers a question the
              // officer has not asked.
              ? _Recents(controller: controller, field: _field)
              : AppEmptyState(
                  illustration: AppIllustrationKind.noResults,
                  title: t('find.noMatch'),
                  message: controller.scope.value == UnitSearchScope.behind
                      ? t('find.noMatchTryAll')
                      : t('find.noMatchHelp'),
                  actionLabel:
                      controller.scope.value == UnitSearchScope.behind
                          ? t('find.tabAll')
                          : null,
                  onAction: controller.scope.value == UnitSearchScope.behind
                      ? () =>
                          controller.scopeChanged(UnitSearchScope.allUnits)
                      : null,
                ),
          children: [
            if (results.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 12),
                child: AppText.bodySmall(
                  t('find.results', args: {'n': '${results.length}'}),
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.72),
                ),
              ),
            for (var i = 0; i < results.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              AppStaggerIn(
                index: i,
                child: FieldCardTile(
                  card: results[i],
                  heroPrefix: 'find',
                  onTap: () => context.push(
                    AppRoutes.propertyProfilePath(results[i].propertyId, from: 'find'),
                    extra: results[i],
                  ),
                  onCall: results[i].isCallable
                      ? () => Dialer.call(results[i].mobileNo)
                      : null,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

/// A big field, the scope switch, and the officer's areas.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.field,
    required this.areas,
  });

  final UnitSearchController controller;
  final TextEditingController field;
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
              controller: field,
              hint: t('find.hint'),
              // The controller debounces the request by 300ms of its own,
              // so this hands it every keystroke rather than waiting twice.
              onChanged: controller.queryChanged,
              onSubmitted: (_) => controller.search(),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
            // Two mutually exclusive readings of one query — which is
            // exactly what a segmented button is for, and what a pair of
            // hand-painted boxes only looked like.
            child: Obx(
              () => SizedBox(
                width: double.infinity,
                child: SegmentedButton<UnitSearchScope>(
                  segments: [
                    ButtonSegment(
                      value: UnitSearchScope.behind,
                      icon: const Icon(Icons.trending_down_rounded, size: 18),
                      label: Text(t('find.tabBehind')),
                    ),
                    ButtonSegment(
                      value: UnitSearchScope.allUnits,
                      icon: const Icon(Icons.storefront_rounded, size: 18),
                      label: Text(t('find.tabAll')),
                    ),
                  ],
                  selected: {controller.scope.value},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    AppHaptics.select();
                    controller.scopeChanged(selection.first);
                  },
                ),
              ),
            ),
          ),
          if (areas.isNotEmpty) ...[
            const SizedBox(height: 10),
            Obx(
              () => AppFilterBar<int?>(
                selected: controller.area.value?.id,
                onChanged: (id) => controller.areaChanged(
                  id == null
                      ? null
                      : areas.firstWhere((area) => area.id == id),
                ),
                options: [
                  AppFilterOption<int?>(
                    value: null,
                    label: t('beat.allAreas'),
                    icon: Icons.public_rounded,
                  ),
                  for (final area in areas)
                    AppFilterOption<int?>(
                      value: area.id,
                      label: area.areaName,
                      icon: Icons.place_rounded,
                    ),
                ],
              ),
            ),
          ],
          Divider(color: theme.dividerColor, height: 1),
        ],
      ),
    );
  }
}

/// What the officer searched for last. On a phone in a bazaar, retyping
/// "MCQ-CR-001001" is a minute he does not have.
class _Recents extends StatelessWidget {
  const _Recents({required this.controller, required this.field});

  final UnitSearchController controller;
  final TextEditingController field;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.recent.isEmpty) {
        return AppEmptyState(
          illustration: AppIllustrationKind.noResults,
          title: t('find.startTyping'),
          message: t('find.startTypingHelp'),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: t('find.recent'),
            actionLabel: t('find.clearRecent'),
            onAction: controller.clearRecent,
          ),
          for (final term in controller.recent)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 8),
              child: AppCard(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(14, 13, 14, 13),
                onTap: () {
                  field.text = term;
                  controller.useRecent(term);
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 19,
                      color: Theme.of(context).dividerColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: UserText.body(term, maxLines: 1)),
                    Icon(
                      Icons.north_west_rounded,
                      size: 17,
                      color: Theme.of(context).dividerColor,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}
