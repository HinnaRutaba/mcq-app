import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/field_beat.dart';
import '../../../widgets/widgets.dart';

class BeatQueueTile extends StatelessWidget {
  const BeatQueueTile({super.key, required this.queue, this.onTap});

  final FieldQueue queue;
  final VoidCallback? onTap;
  static const double extent = 90;

  @override
  Widget build(BuildContext context) {
    final tone = _tone(queue.tone);
    final shown = queue.isEmpty ? AppTone.neutral : tone;
    final amount = Formatters.money(queue.amount);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 26,
                width: 26,
                decoration: BoxDecoration(
                  color: shown.container(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _icon(queue.key),
                  size: 15,
                  color: shown.on(context),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: AppText.headlineSmall(
                  '${queue.count}',
                  color: queue.isEmpty ? null : shown.on(context),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Flexible(child: AppText.caption(_label(queue.key), maxLines: 2)),
          if (amount != null) ...[
            const SizedBox(height: 2),
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
