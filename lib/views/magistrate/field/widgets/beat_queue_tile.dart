import 'package:flutter/material.dart';

import '../../../../models/field/beat.dart';
import '../../../../widgets/widgets.dart';
import 'beat_queue_meta.dart';

/// One of the six tiles on the home screen.
///
/// All of the drawing is [AppStatCard]'s — the accent rail, the tinted
/// plate behind the icon, the count that counts up, the amount beneath it,
/// the title and the sub-label. What lives here is only the mapping from a
/// server queue to that anatomy, which is the part that is specific to the
/// beat:
///
/// * the **plain-language label** for a key like `follow_ups_due`, which is
///   a database word and is never rendered raw;
/// * the **tone**, forced to success at zero — a tile that stays red when
///   the queue is empty teaches the officer that the colours mean nothing;
/// * the fact that `amount: null` draws **no figure at all**, because that
///   queue is not measured in rupees.
class BeatQueueTile extends StatelessWidget {
  const BeatQueueTile({
    super.key,
    required this.queue,
    required this.onTap,
    this.animate = true,
  });

  final BeatQueue queue;
  final VoidCallback onTap;

  /// False on a refresh, so a figure the officer already read does not
  /// count itself up again.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final meta = BeatQueueMeta.of(queue.key);

    return AppStatCard(
      icon: meta.icon,
      count: queue.count,
      amount: queue.amount,
      title: meta.label,
      subtitle: meta.subLabel,
      tone: BeatQueueMeta.toneFor(queue),
      animate: animate,
      onTap: onTap,
      // A cleared queue shows a tick and says so in words. The *shape*
      // changes, not only the colour — this has to read in greyscale and
      // in sunlight.
      clearLabel: meta.clearLabel,
      clearIcon: Icons.check_rounded,
    );
  }
}
