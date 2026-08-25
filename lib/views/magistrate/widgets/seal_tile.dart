import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_style.dart';
import '../../../models/seal_record.dart';
import '../../../widgets/widgets.dart';

/// A single seal record — sealed, ready to unseal, or removed.
class SealTile extends StatelessWidget {
  const SealTile({super.key, required this.seal, this.onRemove, this.isProcessing = false});

  final SealRecord seal;
  final VoidCallback? onRemove;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: AppText.titleMedium(seal.propertyName, maxLines: 1)),
              const SizedBox(width: 8),
              AppStatusBadge(label: seal.status.label, tone: StatusStyle.sealTone(seal.status)),
            ],
          ),
          const SizedBox(height: 4),
          AppText.caption(seal.tenantName),
          const SizedBox(height: 8),
          AppText.body(seal.reason),
          const SizedBox(height: 10),
          AppText.caption('Sealed on ${Formatters.date(seal.sealedDate)}'),
          if (seal.removedDate != null) ...[
            const SizedBox(height: 2),
            AppText.caption('Removed on ${Formatters.date(seal.removedDate!)}'),
          ],
          if (seal.status == SealStatus.readyToUnseal && onRemove != null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'Remove Seal',
              height: 42,
              isLoading: isProcessing,
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}
