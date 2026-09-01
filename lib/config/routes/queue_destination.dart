import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../models/field/beat.dart';
import '../../views/magistrate/field/widgets/beat_queue_meta.dart';
import 'app_routes.dart';

/// Where a beat tile goes when it is tapped.
///
/// MCQ was explicit: **no number on the dashboard may be a dead end.** The
/// server hands the route over in each queue's `endpoint` field precisely
/// so the app does not hard-code paths.
///
/// So this resolves in two steps. The six queues the app has designed
/// screens for open those screens — a purpose-built list beats a generic
/// one every time. Anything else falls through to [AppRoutes.queueList],
/// which fetches the server's own `endpoint` and renders whatever cards
/// come back. A queue MCQ adds next month opens on the handsets already in
/// the field, without waiting for a release.
class QueueDestination {
  QueueDestination._();

  static void open(BuildContext context, BeatQueue queue) {
    switch (queue.key) {
      case BeatQueueMeta.keyDefaulters:
        // A shell branch, so `go` rather than `push` — the officer lands
        // on the tab and its back button is the tab bar.
        GoRouter.of(context).go(AppRoutes.defaulters);
        return;
      case BeatQueueMeta.keyFollowUpsDue:
        GoRouter.of(context).push(AppRoutes.followUpsPath(state: 'due'));
        return;
      case BeatQueueMeta.keyAwaitingUnseal:
        GoRouter.of(context).push(AppRoutes.sealsPath(readyOnly: true));
        return;
      case BeatQueueMeta.keySealedShops:
        GoRouter.of(context).push(AppRoutes.sealsPath());
        return;
      case BeatQueueMeta.keyOpenCases:
        GoRouter.of(context).push(AppRoutes.casesPath());
        return;
      case BeatQueueMeta.keyAssignedToMe:
        GoRouter.of(context).push(AppRoutes.casesPath(assignedToMe: true));
        return;
      default:
        GoRouter.of(context).push(
          AppRoutes.queueList,
          extra: QueueListArgs(
            endpoint: queue.endpoint,
            title: BeatQueueMeta.of(queue.key).label,
          ),
        );
    }
  }
}

/// What the generic queue screen needs: the server's endpoint, and
/// something to put at the top of it.
class QueueListArgs {
  const QueueListArgs({required this.endpoint, required this.title});

  final String endpoint;
  final String title;
}
