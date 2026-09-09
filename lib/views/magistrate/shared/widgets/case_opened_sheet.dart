import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/enforcement_case.dart';
import '../../../../widgets/widgets.dart';

/// The file the server just opened, read back at the shopfront: its number,
/// where it stands, and who it is with.
///
/// The number is the point — it is what the shopkeeper is told and what every
/// later visit is recorded against.
class CaseOpenedSheet extends StatelessWidget {
  const CaseOpenedSheet({super.key, required this.file});

  final EnforcementCase file;

  static Future<void> show(
    BuildContext context, {
    required EnforcementCase file,
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
      builder: (BuildContext context) => CaseOpenedSheet(file: file),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.6,
    );
    final String? owed = Formatters.money(file.amounts.outstandingAtOpen);

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
                    const AppText.titleLarge('Case opened'),
                    const SizedBox(height: 2),
                    AppText.caption(
                      file.caseNo ?? 'Case #${file.id}',
                      color: muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // The server's own labels, shown exactly as it sent them.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (file.status != null)
                AppStatusBadge(
                  label: file.status!.label,
                  tone: AppToneColors.fromApi(file.status!.tone),
                ),
              if (file.priority != null)
                AppStatusBadge(
                  label: file.priority!.label,
                  tone: AppToneColors.fromApi(file.priority!.tone),
                ),
              if (file.isConductCase)
                const AppStatusBadge(label: 'Conduct case'),
            ],
          ),
          const SizedBox(height: 14),

          if (file.openedOn != null)
            AppDetailRow(
              icon: Icons.folder_open_outlined,
              value: 'Opened ${Formatters.date(file.openedOn!.toLocal())}',
            ),
          if (file.property?.displayName != null)
            AppDetailRow(
              icon: Icons.storefront_outlined,
              value: file.property!.displayName!,
              maxLines: 2,
            ),
          if (owed != null)
            // Rent arrears the day the file opened — the figure the case is
            // measured against later, and not what the case is about.
            AppDetailRow(
              icon: Icons.account_balance_wallet_outlined,
              value: '$owed owed in rent when it opened',
              maxLines: 2,
            ),
          if (file.nextVisitDate != null)
            AppDetailRow(
              icon: Icons.event_outlined,
              value:
                  'Next visit ${Formatters.date(file.nextVisitDate!.toLocal())}',
            ),
          if (file.magistrate != null)
            AppDetailRow(
              icon: Icons.assignment_ind_outlined,
              value: 'With ${file.magistrate!.name}',
            ),

          if (!file.isAssigned) ...<Widget>[
            const SizedBox(height: 8),
            const AppAlert(
              tone: AppTone.info,
              icon: Icons.hourglass_empty_rounded,
              message:
                  'No magistrate is on this case yet. The taxation branch '
                  'assigns it — do not promise the shopkeeper a hearing date.',
            ),
          ],

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
