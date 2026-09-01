import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/field/field_seal.dart';
import '../../../../widgets/widgets.dart';

/// One sealed shop — and, when the fine has been paid, one job waiting.
///
/// `ready_to_release` is the server's rule, in MCQ's own words: *"after the
/// allottee submits and pays that challan of fine, magistrate is
/// responsible to unseal it"*. It is true when no fine on the unit is still
/// outstanding and at least one has actually been paid. It is never
/// recomputed here.
///
/// `outstanding_now` is shown but **does not gate the release**, and the
/// card says so. Sealing answers the offence the fine names; holding the
/// shutter closed until the whole arrears history is cleared is a much
/// heavier decision, and not one the app should make quietly on an
/// officer's behalf.
class FieldSealCard extends StatelessWidget {
  const FieldSealCard({
    super.key,
    required this.seal,
    this.onTap,
    this.onRelease,
    this.onCall,
  });

  final FieldSeal seal;
  final VoidCallback? onTap;
  final VoidCallback? onRelease;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final ready = seal.readyToRelease;
    final tone = ready ? AppTone.success : AppTone.danger;
    final colour = tone.on(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return AppCard(
      onTap: onTap,
      tone: tone,
      rail: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The banner is the whole point of the list: this one is a job.
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
            color: colour.withValues(alpha: 0.14),
            child: Row(
              children: [
                Icon(
                  ready ? Icons.lock_open_rounded : Icons.lock_rounded,
                  size: 17,
                  color: colour,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppText.titleSmall(
                    ready ? t('seals.readyBanner') : t('seals.stillSealed'),
                    color: colour,
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: AppText.caption(seal.sealNo, color: colour),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserText.headline(seal.allotteeName, maxLines: 2),
                          const SizedBox(height: 3),
                          AppText.bodySmall(seal.unitLabel,
                              color: muted, maxLines: 1),
                          UserText.caption(seal.areaName, color: muted),
                        ],
                      ),
                    ),
                    if (seal.outstandingNow != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppText.bodySmall(t('seals.owedNow'), color: muted),
                          MoneyText(
                            seal.outstandingNow!,
                            variant: AppTextVariant.titleMedium,
                            color: AppTone.danger.on(context),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                AppPillStrip(
                  pills: [
                    if (seal.sealedOn != null)
                      AppPill(
                        icon: Icons.event_rounded,
                        tone: AppTone.neutral,
                        label: t('seals.sealedOn',
                            args: {'date': Formatters.date(seal.sealedOn!)}),
                      ),
                    if (seal.finesPaid > 0)
                      AppPill(
                        icon: Icons.receipt_long_rounded,
                        tone: AppTone.success,
                        label: t('seals.finesPaid',
                            args: {'n': '${seal.finesPaid}'}),
                      ),
                    if (seal.finesUnpaid > 0)
                      AppPill(
                        icon: Icons.report_gmailerrorred_rounded,
                        tone: AppTone.danger,
                        emphasis: true,
                        label: t('seals.finesUnpaid',
                            args: {'n': '${seal.finesUnpaid}'}),
                      ),
                    if ((seal.caseNo ?? '').isNotEmpty)
                      AppPill(
                        icon: Icons.folder_open_rounded,
                        tone: AppTone.info,
                        label: seal.caseNo!,
                      ),
                  ],
                ),
                if ((seal.sealReason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  UserText.body(seal.sealReason!, color: muted, maxLines: 3),
                ],
                if (ready) ...[
                  const SizedBox(height: 12),
                  // Said in plain words, because it is the argument the
                  // officer will have at the shutter.
                  AppText.bodySmall(t('seals.arrearsDoNotGate'), color: muted),
                ],
                if (onRelease != null || onCall != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (onCall != null) ...[
                        FieldCallSmall(onTap: onCall!),
                        const SizedBox(width: 10),
                      ],
                      if (onRelease != null)
                        Expanded(
                          child: AppButton(
                            label: t('seals.release'),
                            icon: Icons.lock_open_rounded,
                            height: 46,
                            // Releasing a seal is the officer finishing a
                            // job. It should feel like one.
                            destructive: true,
                            variant: ready
                                ? AppButtonVariant.primary
                                : AppButtonVariant.outline,
                            onPressed: onRelease,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A round call button, for a row that already has a primary action.
class FieldCallSmall extends StatelessWidget {
  const FieldCallSmall({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = AppTone.success.on(context);
    return AppPressable(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: colour.withValues(alpha: 0.3)),
        ),
        child: Icon(Icons.phone_rounded, color: colour, size: 21),
      ),
    );
  }
}
