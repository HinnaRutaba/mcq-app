import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_style.dart';
import '../../../models/chalaan.dart';
import '../../../widgets/widgets.dart';

/// A single outstanding chalaan/fine, from the magistrate's point of view —
/// who to collect from, where, and how much.
class CollectionTile extends StatelessWidget {
  const CollectionTile({super.key, required this.chalaan, this.onTap});

  final Chalaan chalaan;
  final VoidCallback? onTap;

  Future<void> _openInMaps() async {
    final query = Uri.encodeComponent(chalaan.propertyAddress);
    final uri = Uri.parse('https://maps.google.com/?q=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: AppText.titleMedium(chalaan.tenantName, maxLines: 1)),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: chalaan.status.label,
                tone: StatusStyle.chalaanTone(chalaan.status),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppText.caption(chalaan.propertyName, maxLines: 1),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, size: 15, color: AppColors.lightTextHint),
              const SizedBox(width: 4),
              Expanded(child: AppText.caption(chalaan.propertyAddress, maxLines: 2)),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _openInMaps,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined, size: 15, color: scheme.primary),
                const SizedBox(width: 4),
                AppText.label('Open in Maps', color: scheme.primary),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              AppText.titleLarge(Formatters.currency(chalaan.amount)),
              const Spacer(),
              AppText.caption(
                Formatters.dueIn(chalaan.dueDate),
                color: chalaan.status == ChalaanStatus.overdue ? AppColors.error : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
