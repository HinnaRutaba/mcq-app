import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';

import '../../../../models/agreement_dashboard.dart';
import '../../../../widgets/widgets.dart';
import '../../shared/intake_labels.dart';

/// One dashboard figure that opens the list it counted.
class IntakeTileCard extends StatelessWidget {
  const IntakeTileCard({
    super.key,
    required this.tile,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final IntakeTile tile;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  static const double extent = AppStatTile.extent;

  @override
  Widget build(BuildContext context) {
    final int? acts = tile.acts;
    // A case endorsed, returned and endorsed again is 1 case, 2 acts.
    final String shown = acts != null && acts != tile.count
        ? '$label · $acts acts'
        : label;
    return AppPress(
      onTap: onTap,
      child: AppStatTile.count(
        tile.count,
        label: shown,
        icon: icon,
        tone: tile.isEmpty ? null : toneFor(tile.key),
      ),
    );
  }

  /// The queue keys and acts the server publishes; anything newer is
  /// humanised rather than hidden.
  static String labelFor(IntakeTile tile) {
    // Our own names for these acts win over the server's label.
    switch (tile.key) {
      case 'endorsed':
        return 'Sent to Admin';
      case 'dispatched':
        return 'Sent from Admin';
      case 'responded':
        return 'Queries Answered';
    }
    if (tile.label != null) return tile.label!;
    if (tile.status != null) return IntakeLabels.status(tile.status!);
    return switch (tile.key) {
      IntakeScope.awaitingMe => 'All waiting',
      IntakeScope.returnedByMe => 'Returned by you',
      'review' => 'To review',
      'queries' => 'Queries to answer',
      'dispatch' => 'To dispatch',
      'decision' => 'To decide',
      'execution_handoff' => 'Hand to Estate',
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      'returned' => 'Returned or queried',
      'taxation_forwarded' => 'Forwarded by Taxation',
      'execution_forwarded' => 'Handed to Estate',
      _ => IntakeLabels.humanise(tile.key),
    };
  }

  /// "What you did", grouped by where those cases now stand. Acts not listed
  /// here are not shown; Cancelled follows on its own.
  static const List<(String, AppTone, List<String>)> doneGroups =
      <(String, AppTone, List<String>)>[
        ('Pending', AppTone.warning, <String>['endorsed', 'responded']),
        ('Forwarded', AppTone.info, <String>['dispatched', 'returned']),
      ];

  /// What a non-zero figure means. Zero is never toned.
  static AppTone? toneFor(String key) => switch (key) {
    IntakeScope.awaitingMe => AppTone.primary,
    'review' || 'decision' => AppTone.warning,
    // A case stuck until you answer.
    'queries' => AppTone.danger,
    'dispatch' || 'execution_handoff' => AppTone.success,
    IntakeScope.returnedByMe => AppTone.info,
    _ => null,
  };

  static IconData iconFor(String key) => switch (key) {
    IntakeScope.awaitingMe => Icons.inbox_outlined,
    IntakeScope.returnedByMe => Icons.undo_rounded,
    'review' => Icons.rate_review_outlined,
    'queries' => Icons.help_outline_rounded,
    'dispatch' => Icons.local_shipping_outlined,
    'decision' => Icons.gavel_rounded,
    'endorsed' => Icons.thumb_up_alt_outlined,
    'approved' => Icons.verified_outlined,
    'rejected' => Icons.block_rounded,
    'returned' => Icons.undo_rounded,
    'responded' => Icons.question_answer_outlined,
    'dispatched' => Icons.send_outlined,
    'activated' => Icons.task_alt_rounded,
    'cancelled' => Icons.cancel_outlined,
    'pending' => Icons.hourglass_top_rounded,
    'forwarded' => Icons.fast_forward_rounded,
    _ => Icons.folder_open_outlined,
  };
}
