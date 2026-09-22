import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/field_seal.dart';
import '../../../../widgets/widgets.dart';

/// The seal the server has just taken off, read back at the shutter.
///
/// The number is the point: it is what was on the physical seal being cut, and
/// what the shopkeeper will quote if the release is ever questioned.
class SealReleasedSheet extends StatelessWidget {
  const SealReleasedSheet({super.key, required this.seal});

  final FieldSeal seal;

  static Future<void> show(BuildContext context, {required FieldSeal seal}) {
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
      builder: (BuildContext context) => SealReleasedSheet(seal: seal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.6,
    );

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
                  Icons.lock_open_rounded,
                  color: AppTone.success.on(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const AppText.titleLarge('Seal released'),
                    const SizedBox(height: 2),
                    AppText.caption(
                      seal.sealNo ?? 'Seal #${seal.id}',
                      color: muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (seal.status != null)
                AppStatusBadge(
                  label: seal.status!.label,
                  tone: AppToneColors.fromApi(seal.status!.tone),
                ),
              if (!seal.isSealed)
                const AppStatusBadge(
                  label: 'Open for trade',
                  tone: AppTone.success,
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (seal.releasedOn != null)
            AppDetailRow(
              icon: Icons.event_available_outlined,
              value: 'Released ${Formatters.date(seal.releasedOn!.toLocal())}',
            ),
          if (seal.unsealReason != null)
            AppDetailRow(
              icon: Icons.notes_rounded,
              value: seal.unsealReason!,
              maxLines: 3,
            ),
          if (seal.shopNo != null)
            AppDetailRow(
              icon: Icons.storefront_outlined,
              value: seal.marketName == null
                  ? seal.shopNo!
                  : '${seal.shopNo} · ${seal.marketName}',
              maxLines: 2,
            ),

          if (seal.isSealed) ...<Widget>[
            const SizedBox(height: 8),
            // The server had the last word and it did not open the shop. Said
            // plainly, because the officer is standing at a shutter deciding
            // whether to cut the seal.
            const AppAlert(
              tone: AppTone.warning,
              icon: Icons.lock_outline_rounded,
              message:
                  'MCQ still has this unit down as sealed. Do not cut the '
                  'seal until the register shows it open.',
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
