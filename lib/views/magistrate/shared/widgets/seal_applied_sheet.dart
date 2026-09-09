import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/field_seal.dart';
import '../../../../widgets/widgets.dart';

/// The seal the server just recorded, read back at the shopfront.
///
/// The number is the point: it is what goes on the physical seal and what the
/// release is later asked for, so it is offered to be copied rather than only
/// shown.
class SealAppliedSheet extends StatelessWidget {
  const SealAppliedSheet({super.key, required this.seal});

  final FieldSeal seal;

  static Future<void> show(BuildContext context, {required FieldSeal seal}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Not dismissible: the number has to be written on the seal, and a
      // sheet swiped away by accident cannot be got back.
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (BuildContext context) => SealAppliedSheet(seal: seal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.6,
    );
    final String? sealNo = seal.sealNo;
    final String shopLine = <String>[
      ?seal.shopNo,
      ?(seal.marketName ?? seal.areaName),
    ].join(' · ');

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
                  color: AppTone.danger.container(context),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: AppTone.danger.on(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const AppText.titleLarge('Shop sealed'),
                    const SizedBox(height: 2),
                    // The shop, not the seal number: the number has a card of
                    // its own below, and saying it twice reads as two.
                    AppText.caption(
                      shopLine.isEmpty ? 'The seal is on record' : shopLine,
                      color: muted,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (sealNo != null) ...<Widget>[
            AppCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppText.caption('Seal number', color: muted),
                        const SizedBox(height: 2),
                        AppText.titleMedium(sealNo),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: 'Copy the seal number',
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: sealNo)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (seal.status != null)
                AppStatusBadge(
                  label: seal.status!.label,
                  tone: AppToneColors.fromApi(seal.status!.tone),
                )
              else if (seal.isSealed)
                const AppStatusBadge(label: 'Sealed', tone: AppTone.danger),
              if (seal.readyToRelease)
                const AppStatusBadge(
                  label: 'Clear for release',
                  tone: AppTone.success,
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (seal.sealedOn != null)
            AppDetailRow(
              icon: Icons.event_available_outlined,
              value: 'Sealed ${Formatters.date(seal.sealedOn!.toLocal())}',
            ),
          if (seal.allotteeName != null)
            AppDetailRow(
              icon: Icons.person_outline_rounded,
              value: seal.allotteeName!,
            ),
          if (seal.sealReason != null)
            AppDetailRow(
              icon: Icons.notes_outlined,
              value: seal.sealReason!,
              maxLines: 3,
            ),

          const SizedBox(height: 18),
          AppButton(
            label: 'Done',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
