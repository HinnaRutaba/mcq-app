import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/field_beat.dart';
import '../../../widgets/widgets.dart';

/// One work queue on the home screen: how many are waiting, and what they are
/// worth where that is a sum of money rather than a count of work.
///
/// The server owns the queue list, so a key this app has never seen still
/// draws — [_label] falls back to the key itself, spelled out. What it must
/// not do is guess where the tile goes: [FieldQueue.endpoint] is the list it
/// opens, and routing is the caller's job through `ApiPaths.resolve`.
class BeatQueueTile extends StatelessWidget {
  const BeatQueueTile({super.key, required this.queue, this.onTap});

  final FieldQueue queue;
  final VoidCallback? onTap;

  /// Fits the tallest tile — icon, count, label and an amount — so every tile
  /// in the grid is the same height whether or not it carries money.
  static const double extent = 136;

  @override
  Widget build(BuildContext context) {
    final tone = _tone(queue.tone);
    // An empty queue is nothing to be alarmed by, whatever tone the server put
    // on it: no defaulters left is the good outcome, and a red 0 reads as one
    // more thing to do.
    final shown = queue.isEmpty ? AppTone.neutral : tone;
    final amount = Formatters.money(queue.amount);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: shown.container(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon(queue.key), size: 19, color: shown.on(context)),
          ),
          const Spacer(),
          AppText.headlineSmall(
            '${queue.count}',
            color: queue.isEmpty ? null : shown.on(context),
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          AppText.caption(_label(queue.key), maxLines: 1),
          if (amount != null) ...[
            const SizedBox(height: 3),
            AppText.caption(amount, fontWeight: FontWeight.w700, maxLines: 1),
          ],
        ],
      ),
    );
  }

  static AppTone _tone(String? tone) => switch (tone) {
    'danger' => AppTone.danger,
    'warning' => AppTone.warning,
    'info' => AppTone.info,
    'primary' => AppTone.primary,
    _ => AppTone.neutral,
  };

  static IconData _icon(String key) => switch (key) {
    'defaulters' => Icons.person_off_outlined,
    'follow_ups_due' => Icons.event_repeat_outlined,
    'awaiting_unseal' => Icons.lock_open_outlined,
    'sealed_shops' => Icons.lock_outline_rounded,
    'open_cases' => Icons.folder_open_outlined,
    'assigned_to_me' => Icons.assignment_ind_outlined,
    _ => Icons.list_alt_outlined,
  };

  static String _label(String key) => switch (key) {
    'defaulters' => 'Defaulters',
    'follow_ups_due' => 'Follow-ups due',
    'awaiting_unseal' => 'Awaiting unseal',
    'sealed_shops' => 'Sealed shops',
    'open_cases' => 'Open cases',
    'assigned_to_me' => 'Assigned to me',
    _ => humanise(key),
  };

  /// `follow_ups_due` -> `Follow ups due`. For a queue the server added after
  /// this build shipped.
  static String humanise(String key) {
    if (key.isEmpty) return 'Queue';
    final words = key.replaceAll('_', ' ').trim();
    return words[0].toUpperCase() + words.substring(1);
  }
}
