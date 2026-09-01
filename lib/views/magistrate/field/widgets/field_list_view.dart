import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/widgets.dart';
import '../../api/widgets/stale_data_banner.dart';

/// The frame every field list is built in.
///
/// It exists to hold one rule in a single place, where it cannot be
/// forgotten on the seventh screen:
///
/// > **The rows stay on screen during a refresh and on a failure.**
///
/// A list that empties itself because a request timed out is
/// indistinguishable from "nobody owes anything" — which is a false
/// statement about the register, and one an officer might repeat to a
/// shopkeeper. So a failure with rows already loaded draws a banner
/// *above* them and leaves them alone; only a failure with nothing to show
/// takes the whole screen.
///
/// It also settles the other three states consistently: skeletons on a
/// first load, a designed empty state with an illustration when the answer
/// really is "nothing", and the cached-data stamp whenever what is on
/// screen did not come from the network.
class FieldListView extends StatelessWidget {
  const FieldListView({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.onRefresh,
    required this.children,
    this.header = const [],
    this.pinnedHeader,
    this.failureMessage,
    this.emptyState,
    this.fetchedAt,
    this.isStale = false,
    this.skeletonCount = 4,
    this.padding =
        const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 36),
  });

  /// True while the first request is in flight.
  final bool isLoading;

  /// True when the last successful read genuinely returned nothing.
  final bool isEmpty;

  final Future<void> Function() onRefresh;

  /// The rows.
  final List<Widget> children;

  /// Scrolls with the list — a search field, filter chips, a summary.
  final List<Widget> header;

  /// Stays above the list — used where the filters must not scroll away.
  final Widget? pinnedHeader;

  /// The server's own sentence, when the last read failed. Shown verbatim.
  final String? failureMessage;

  final Widget? emptyState;

  final DateTime? fetchedAt;
  final bool isStale;

  final int skeletonCount;
  final EdgeInsetsGeometry padding;

  bool get _hasRows => children.isNotEmpty;

  /// Which of the four states is on screen. The row *count* is part of it,
  /// so a refresh that returns a different list still cross-fades, while a
  /// rebuild that changes nothing does not restart the transition.
  String get _stateKey {
    if (isLoading && !_hasRows) return 'loading';
    if (failureMessage != null && !_hasRows) return 'failed';
    if (!_hasRows && isEmpty) return 'empty';
    return 'rows-${children.length}';
  }

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ...header,

        // A failure with rows behind it is a banner, not a blank screen.
        if (failureMessage != null && _hasRows) ...[
          AppBanner(
            tone: AppStatusTone.danger,
            icon: Icons.cloud_off_rounded,
            message: failureMessage!,
            action: AppButton(
              label: t('common.retry'),
              variant: AppButtonVariant.outline,
              fullWidth: false,
              height: 44,
              onPressed: onRefresh,
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (isStale && fetchedAt != null && _hasRows) ...[
          StaleDataBanner(fetchedAt: fetchedAt!, onRetry: onRefresh),
          const SizedBox(height: 16),
        ],

        // The four states cross-fade into one another rather than snapping.
        // Skeletons becoming rows in a single frame reads as a flicker on a
        // slow connection — which is the only connection this app has.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) => Stack(
            alignment: AlignmentDirectional.topCenter,
            children: [...previous, ?current],
          ),
          child: KeyedSubtree(
            key: ValueKey(_stateKey),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isLoading && !_hasRows)
                  AppSkeletonList(count: skeletonCount)
                else if (failureMessage != null && !_hasRows)
                  AppEmptyState(
                    illustration: AppIllustrationKind.disconnected,
                    title: t('list.couldNotLoad'),
                    message: failureMessage,
                    actionLabel: t('common.retry'),
                    onAction: onRefresh,
                  )
                else if (!_hasRows && isEmpty)
                  emptyState ??
                      AppEmptyState(
                        illustration: AppIllustrationKind.allClear,
                        title: t('list.nothingHere'),
                      )
                else
                  ...children,
              ],
            ),
          ),
        ),
      ],
    );

    final refreshable = AppRefresh(onRefresh: onRefresh, child: list);

    if (pinnedHeader == null) return refreshable;
    return Column(
      children: [
        pinnedHeader!,
        Expanded(child: refreshable),
      ],
    );
  }
}
