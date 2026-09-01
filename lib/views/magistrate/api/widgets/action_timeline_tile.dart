import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/enforcement/enforcement_case.dart';
import '../../../../widgets/widgets.dart';

/// One entry on a case's timeline: what was done, when it happened, and the
/// evidence that came with it.
class ActionTimelineTile extends StatelessWidget {
  const ActionTimelineTile({super.key, required this.action});

  final CaseAction action;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return AppCard(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText.titleMedium(
                  action.actionType.isEmpty
                      ? t('actionType.other')
                      : action.actionType.label,
                  maxLines: 2,
                ),
              ),
              if (action.actionDate != null)
                AppText.caption(Formatters.date(action.actionDate!)),
            ],
          ),
          if ((action.remarks ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            UserText.body(action.remarks),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              if (action.hasPhoto)
                _fact(context, Icons.photo_camera_outlined, t('action.photo')),
              if ((action.signaturePath ?? '').isNotEmpty)
                _fact(context, Icons.draw_outlined, t('action.signature')),
              if (action.hasCoordinates)
                _fact(
                  context,
                  Icons.place_outlined,
                  action.locationAccuracyM == null
                      ? t('action.location')
                      : t('action.locationFix', args: {
                          'accuracy':
                              action.locationAccuracyM!.toStringAsFixed(0),
                        }),
                ),
              if ((action.witnessName ?? '').isNotEmpty)
                _fact(context, Icons.person_outline_rounded, action.witnessName!),
              if (action.recordedOffline)
                _fact(context, Icons.cloud_off_rounded, t('common.offlineRecord')),
            ],
          ),
          if ((action.recordedBy ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            AppText.caption(
              t('common.recordedBy', args: {'name': action.recordedBy!}),
              color: muted,
            ),
          ],
        ],
      ),
    );
  }

  Widget _fact(BuildContext context, IconData icon, String label) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: muted),
        const SizedBox(width: 4),
        AppText.caption(label, color: muted),
      ],
    );
  }
}
