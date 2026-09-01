import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/offline/queued_write.dart';
import '../../../../widgets/widgets.dart';

/// One record waiting to reach the server.
///
/// A stuck item names its shop and its allottee, carries the server's own
/// sentence when there is one, and offers "send again" and "discard" — the
/// officer decides, nothing is dropped for them.
class QueuedWriteTile extends StatelessWidget {
  const QueuedWriteTile({
    super.key,
    required this.write,
    this.onRetry,
    this.onDiscard,
  });

  final QueuedWrite write;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  AppStatusTone get _tone => switch (write.status) {
        QueuedWriteStatus.needsAttention => AppStatusTone.danger,
        QueuedWriteStatus.sending => AppStatusTone.info,
        QueuedWriteStatus.sent => AppStatusTone.success,
        QueuedWriteStatus.pending => AppStatusTone.warning,
      };

  String get _statusKey => switch (write.status) {
        QueuedWriteStatus.needsAttention => 'queue.conflict',
        QueuedWriteStatus.sending => 'queue.sending',
        QueuedWriteStatus.sent => 'queue.synced',
        QueuedWriteStatus.pending => 'queue.pending',
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppText.titleMedium(t(write.kind.labelKey), maxLines: 2),
              ),
              AppStatusBadge(label: t(_statusKey), tone: _tone),
            ],
          ),
          const SizedBox(height: 6),
          UserText.body('${write.shopLabel} — ${write.allotteeLabel}',
              maxLines: 2),
          const SizedBox(height: 6),
          AppText.caption(
            t('queue.recordedAt',
                args: {'time': Formatters.stamp(write.recordedAt)}),
          ),
          if (write.hasPendingPhoto) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.photo_camera_outlined, size: 14),
                const SizedBox(width: 6),
                AppText.caption(t('action.pendingUpload')),
              ],
            ),
          ],
          if (write.isBlocked) ...[
            const SizedBox(height: 12),
            AppBanner(
              tone: AppStatusTone.danger,
              icon: Icons.report_gmailerrorred_rounded,
              // The server's sentence, verbatim: it names what was refused
              // and usually what to do instead.
              message: write.serverMessage ?? t('queue.conflictHelp'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: t('queue.retry'),
                    variant: AppButtonVariant.outline,
                    height: 44,
                    onPressed: onRetry,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: t('queue.discard'),
                    variant: AppButtonVariant.danger,
                    height: 44,
                    onPressed: onDiscard,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
