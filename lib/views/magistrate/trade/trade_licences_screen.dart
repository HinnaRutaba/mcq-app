import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/trade_licences_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/trade_application.dart';
import '../../../models/trade_licence.dart';
import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';
import 'widgets/capture_sheet.dart';
import 'widgets/capture_tile.dart';
import 'widgets/licence_sheet.dart';
import 'widgets/licence_tile.dart';
import 'widgets/lookup_answer.dart';
import 'widgets/trade_filters.dart';

class TradeLicencesScreen extends StatelessWidget {
  const TradeLicencesScreen({super.key});

  /// Two heights: the scope line only appears once the beat has landed, and a
  /// header sized for it before then leaves a gap under the title.
  static const double _headerHeight = 130;
  static const double _headerWithScope = 152;

  @override
  Widget build(BuildContext context) {
    final TradeLicencesController controller =
        Get.find<TradeLicencesController>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(() {
          final String? scope = controller.scopeSentence;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              AppSliverHeroHeader(
                title: 'Trade Licences',
                subtitle: scope,
                expandedHeight: scope == null
                    ? _headerHeight
                    : _headerWithScope,
                compactTitle: true,
                // Room for the labelled button below, which is wider than the
                // circle action the header reserves for by default.
                trailingInset: 162,
                leading: const BackToHomeButton(),
                trailing: SizedBox(
                  // The height the header's own circle actions have, so the
                  // button sits on the toolbar's centre line like them.
                  height: 42,
                  child: Center(
                    child: AppHeroAction(
                      icon: Icons.add_business_outlined,
                      label: 'Capture',
                      // Filled, not a wash: this is what the screen is for,
                      // and a translucent pill up here read as a chip.
                      solid: true,
                      onTap: () => _capture(context, controller),
                    ),
                  ),
                ),
                bottom: AppSearchField(
                  controller: controller.searchController,
                  hint: 'CNIC, mobile, licence no or code',
                  onChanged: controller.search,
                ),
              ),
              AppPinnedBar(
                height: TradeFilters.heightFor(
                  withAreaPicker: controller.hasAreaChoice,
                  lookingUp: controller.isLookingUp,
                ),
                child: TradeFilters(controller: controller),
              ),
              ..._slivers(context, controller),
            ],
          );
        }),
      ),
    );
  }
}

Future<void> _capture(
  BuildContext context,
  TradeLicencesController controller, {
  String? searched,
}) async {
  final bool? changed = await context.push<bool>(
    AppRoutes.tradeCapturePath(
      searched: searched,
      areaId: controller.areaId.value == TradeLicencesController.allAreas
          ? null
          : controller.areaId.value,
    ),
  );
  if (changed ?? false) {
    controller.clearSearch();
    controller.showQueue(TradeQueue.captures);
    await controller.reloadCaptures();
  }
}

List<Widget> _slivers(
  BuildContext context,
  TradeLicencesController controller,
) {
  // Nothing on screen yet: one spinner, not a half-drawn page that shuffles as
  // each of the four calls lands.
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
          title: 'Could not load the licence queues',
          message: error,
          onRetry: controller.load,
        ),
      ),
    ];
  }

  return controller.isLookingUp
      ? _lookupSlivers(context, controller)
      : _queueSlivers(context, controller, error);
}

// ---------------------------------------------------------------------------
// The doorway lookup
// ---------------------------------------------------------------------------

List<Widget> _lookupSlivers(
  BuildContext context,
  TradeLicencesController controller,
) {
  if (!controller.hasFullQuery) {
    return const <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          icon: Icons.pin_outlined,
          title: 'Keep going',
          message:
              'A licence is found by a whole CNIC, mobile number, licence '
              'number or verification code — not by the start of one.',
        ),
      ),
    ];
  }

  final String? failed = controller.lookupError.value;
  if (failed != null) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorRetry(
          title: 'Could not look that up',
          message: failed,
          onRetry: controller.retryLookup,
        ),
      ),
    ];
  }

  final TradeLicenceLookup? answer = controller.answer.value;
  if (answer == null) {
    // A whole query with no answer is one on its way. The lookup is debounced,
    // so this covers the wait before the call as well as the call itself —
    // without it the screen is blank for the pause after the last keystroke.
    return const <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ];
  }

  final List<TradeLicence> licences = answer.licences;

  return <Widget>[
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      sliver: SliverList.list(
        children: <Widget>[
          AppEntrance(
            key: ValueKey<String>('answer-${answer.searched}'),
            child: LookupAnswer(
              answer: answer,
              onCapture: () => _capture(
                context,
                controller,
                searched: answer.searched ?? controller.query.value,
              ),
            ),
          ),
          for (int i = 0; i < licences.length; i++) ...<Widget>[
            const SizedBox(height: 12),
            AppEntrance(
              key: ValueKey<Object>(licences[i].id ?? i),
              index: i + 1,
              child: LicenceTile(
                licence: licences[i],
                onTap: () => LicenceSheet.show(context, licence: licences[i]),
              ),
            ),
          ],
        ],
      ),
    ),
  ];
}

// ---------------------------------------------------------------------------
// The three queues
// ---------------------------------------------------------------------------

List<Widget> _queueSlivers(
  BuildContext context,
  TradeLicencesController controller,
  String? error,
) {
  final TradeQueue queue = controller.queue.value;
  final List<TradeLicence> licences = queue == TradeQueue.captures
      ? const <TradeLicence>[]
      : controller.visibleLicences;
  final List<TradeApplication> captures = queue == TradeQueue.captures
      ? controller.visibleCaptures
      : const <TradeApplication>[];

  if (licences.isEmpty && captures.isEmpty) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        // Read here, inside the `Obx`, and handed over as plain values.
        child: _Nothing(
          queue: queue,
          narrowed: controller.isNarrowed,
          onClear: controller.clearFilters,
          onCapture: () => _capture(context, controller),
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
    if (controller.liveCount != null && queue != TradeQueue.captures)
      _LiveStrip(
        live: controller.liveCount!,
        generatedAt: controller.generatedAt,
      ),
  ];

  final int rows = licences.length + captures.length;

  return <Widget>[
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
      sliver: SliverList.builder(
        itemCount: lead.length + rows,
        itemBuilder: (BuildContext context, int index) {
          if (index < lead.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: lead[index],
            );
          }

          final int row = index - lead.length;

          // Keyed by the record, so a row keeps its element as the queue
          // reloads: unkeyed, every rebuild would restart the entrance and the
          // list would flicker each time a figure lands.
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppEntrance(
              key: ValueKey<String>(
                row < licences.length
                    ? 'licence-${licences[row].id ?? row}'
                    : 'capture-${captures[row - licences.length].id ?? row}',
              ),
              index: index,
              child: row < licences.length
                  ? LicenceTile(
                      licence: licences[row],
                      onTap: () =>
                          LicenceSheet.show(context, licence: licences[row]),
                    )
                  : CaptureTile(
                      capture: captures[row - licences.length],
                      onTap: () => CaptureSheet.show(
                        context,
                        application: captures[row - licences.length],
                      ),
                    ),
            ),
          );
        },
      ),
    ),
  ];
}

/// The one figure the beat carries that no list here repeats: how many
/// licences are live in the officer's bazaars.
///
/// Only over the licence queues. The officer's own captures are a different
/// register — a live-licence count above them was read as a count of them.
class _LiveStrip extends StatelessWidget {
  const _LiveStrip({required this.live, required this.generatedAt});

  final int live;
  final DateTime? generatedAt;

  @override
  Widget build(BuildContext context) {
    final Color ink = AppTone.success.on(context);
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Icon(Icons.verified_outlined, size: 20, color: ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppText.titleMedium(
                  '$live live ${live == 1 ? 'licence' : 'licences'}',
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                AppText.caption(
                  // "All", because the bazaar picker above may have narrowed
                  // the rows under this: the beat carries no per-bazaar figure
                  // and this one never follows the filter.
                  generatedAt == null
                      ? 'Across all your bazaars'
                      : 'Across all your bazaars, as of '
                            '${Formatters.dateTime(generatedAt!.toLocal())}',
                  color: muted,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An empty queue, which means one of three different things.
class _Nothing extends StatelessWidget {
  const _Nothing({
    required this.queue,
    required this.narrowed,
    required this.onClear,
    required this.onCapture,
  });

  final TradeQueue queue;

  /// Whether a filter is what emptied the list.
  final bool narrowed;

  final VoidCallback onClear;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    if (queue == TradeQueue.captures) {
      // Nothing to clear here: the captures list is scoped to the officer, not
      // to the bazaar, so a filter never empties it.
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const AppEmptyState(
              icon: Icons.add_business_outlined,
              title: 'Nothing captured',
              message:
                  'Shops you write up in the field appear here until their '
                  'challan is paid.',
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Capture a shop',
              icon: Icons.add_business_outlined,
              variant: AppButtonVariant.outline,
              fullWidth: false,
              onPressed: onCapture,
            ),
          ],
        ),
      );
    }

    if (!narrowed) {
      return const AppEmptyState(
        icon: Icons.verified_outlined,
        title: 'Nothing running out',
        message: 'Every licence in your bazaars is current.',
      );
    }

    // The filters that emptied the list are above this, but the way out of a
    // dead end belongs in the dead end.
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AppEmptyState(
            icon: Icons.search_off_rounded,
            title: queue == TradeQueue.lapsed
                ? 'Nothing lapsed'
                : 'Nothing expiring',
            message: 'No licence in this bazaar is in that state.',
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
