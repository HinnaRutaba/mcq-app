import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/enforcement_action.dart';
import '../../../../widgets/widgets.dart';

/// What the server wrote, read back at the shopfront.
///
/// On a promise the date is the whole point — it is the day the shopkeeper has
/// been held to, and the day this shop comes back onto the follow-up list — so
/// it is said once in full rather than left as one row among the rest.
class ActionRecordedSheet extends StatelessWidget {
  const ActionRecordedSheet({super.key, required this.action});

  final EnforcementAction action;

  static Future<void> show(
    BuildContext context, {
    required EnforcementAction action,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (BuildContext context) => ActionRecordedSheet(action: action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.6,
    );
    final DateTime? promised = action.promisedPaymentDate?.toLocal();
    final String? owed = Formatters.money(action.amounts.outstandingAtAction);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppTone.success.container(context),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: AppTone.success.on(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const AppText.titleLarge('Recorded'),
                    const SizedBox(height: 2),
                    // The server's own wording for what went on the timeline,
                    // not the button the officer pressed.
                    AppText.caption(
                      action.actionType?.label ?? 'On the case timeline',
                      color: muted,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (promised != null) ...<Widget>[
            const SizedBox(height: 18),
            AppAlert(
              tone: AppTone.success,
              icon: Icons.handshake_outlined,
              message:
                  'They have promised to pay by '
                  '${Formatters.date(promised)}. '
                  '${Formatters.dueIn(promised)}.',
            ),
          ],

          const SizedBox(height: 14),

          if (action.actionDate != null)
            AppDetailRow(
              icon: Icons.event_available_outlined,
              value: 'Called ${Formatters.date(action.actionDate!.toLocal())}',
            ),
          if (action.nextVisitDate != null)
            AppDetailRow(
              icon: Icons.event_repeat_outlined,
              value:
                  'Back on '
                  '${Formatters.date(action.nextVisitDate!.toLocal())}',
            ),
          if (owed != null)
            // What was owed at the moment of the visit — the figure quoted to
            // the shopkeeper on the day, kept with the record.
            AppDetailRow(
              icon: Icons.account_balance_wallet_outlined,
              value: '$owed owed when you called',
              maxLines: 2,
            ),
          if (action.remarks != null)
            AppDetailRow(
              icon: Icons.notes_rounded,
              value: action.remarks!,
              maxLines: 4,
            ),
          if (action.performedBy != null)
            AppDetailRow(
              icon: Icons.assignment_ind_outlined,
              value: 'Recorded by ${action.performedBy!.name}',
            ),

          const SizedBox(height: 22),
          AppButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
