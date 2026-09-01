import 'package:flutter/material.dart';

import '../motion/app_pressable.dart';

/// Pull to refresh.
///
/// The platform's own [RefreshIndicator], themed to the brand — which is
/// the right trade: it already knows the drag distances, the edge cases
/// (nested scrollables, an over-scroll that becomes a fling, a refresh
/// cancelled mid-pull) and the accessibility affordances that a hand-rolled
/// pull gesture spends a release getting wrong. What it does not do out of
/// the box is *speak to the thumb*, so a selection haptic fires the moment
/// the gesture is accepted; the officer knows the pull took without
/// watching for it.
///
/// **Nothing is cleared while this runs.** The rows stay on screen through
/// a refresh and through a failure — a list that empties itself because a
/// request timed out is indistinguishable from "nobody owes anything",
/// which is a false statement about the register. That rule is held by
/// `FieldListView`; this widget simply never unmounts its child.
class AppRefresh extends StatelessWidget {
  const AppRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
  });

  final Future<void> Function() onRefresh;

  /// The scrollable. It must be scrollable even when short — every list in
  /// this app passes `AlwaysScrollableScrollPhysics` — or there is nothing
  /// to over-scroll and the gesture never starts.
  final Widget child;

  /// Pushes the spinner below a pinned header or an app bar.
  final double edgeOffset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () {
        AppHaptics.select();
        return onRefresh();
      },
      edgeOffset: edgeOffset,
      displacement: 28,
      strokeWidth: 2.6,
      color: theme.colorScheme.primary,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      child: child,
    );
  }
}
