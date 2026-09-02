import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/field_beat.dart';
import '../../../../widgets/widgets.dart';
import '../../../../config/theme/app_radius.dart';

class BeatQueueTile extends StatelessWidget {
  const BeatQueueTile({super.key, required this.queue, this.onTap});

  final FieldQueue queue;
  final VoidCallback? onTap;
  static const double extent = 100;

  @override
  Widget build(BuildContext context) {
    final tone = AppToneColors.fromApi(queue.tone);
    final shown = queue.isEmpty ? AppTone.neutral : tone;
    final amount = Formatters.money(queue.amount);
    final ink = shown.on(context);
    final toned = shown != AppTone.neutral;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      // Every tile sits on its tone's light plate, so the grid reads as one
      // set rather than two coloured cards among four white ones. A queue
      // with no tone — or an empty one, since nought defaulters is not a
      // danger — gets the neutral plate.
      color: shown.container(context),
      borderColor: ink.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 26,
                width: 26,
                decoration: BoxDecoration(
                  // Filled for a real tone; a deeper wash of the same grey
                  // for neutral. A *filled* neutral chip is light-on-black in
                  // dark mode, which would make the empty queues the loudest
                  // thing on the grid.
                  color: toned ? ink : ink.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  _icon(queue.key),
                  size: 15,
                  color: toned ? shown.onFilled(context) : ink,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: AppText.headlineSmall(
                  '${queue.count}',
                  // Default ink on a neutral plate: a faint grey wash is not
                  // enough contrast to also drop the count to secondary.
                  color: toned ? ink : null,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Flexible(
            child: AppText.caption(
              _label(queue.key),
              color: toned ? ink : null,
              maxLines: 2,
            ),
          ),
          if (amount != null) ...[
            const SizedBox(height: 2),
            AppText.caption(
              amount,
              color: toned ? ink : null,
              fontWeight: FontWeight.w700,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }

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
