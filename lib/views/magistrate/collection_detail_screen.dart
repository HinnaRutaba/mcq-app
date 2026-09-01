import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme/app_colors.dart';
import '../../controllers/collections_controller.dart';
import '../../controllers/magistrate_home_controller.dart';
import '../../controllers/seal_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/get_helpers.dart';
import '../../data/repositories/chalaan_repository.dart';
import '../../models/chalaan.dart';
import '../../widgets/widgets.dart';
import 'widgets/chalaan_tile.dart';

/// Full shopkeeper + chalaan history for one property, with the magistrate's
/// "Mark Collected" and "Seal Shop" actions.
class CollectionDetailScreen extends StatelessWidget {
  const CollectionDetailScreen({super.key, required this.chalaanId});

  final String chalaanId;

  void _refreshRelatedScreens() {
    if (Get.isRegistered<MagistrateHomeController>()) {
      Get.find<MagistrateHomeController>().reload();
    }
    if (Get.isRegistered<CollectionsController>()) {
      Get.find<CollectionsController>().reload();
    }
  }

  Future<void> _markCollected(BuildContext context, Chalaan chalaan) async {
    await getOrPut(() => CollectionsController()).markCollected(chalaan.id);
    _refreshRelatedScreens();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${chalaan.tenantName} — payment collected')));
      context.pop();
    }
  }

  Future<void> _sealShop(BuildContext context, Chalaan chalaan) async {
    final reasonController = TextEditingController(text: chalaan.description ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AppText.titleLarge('Seal this shop?'),
        content: AppTextField(
          label: 'Reason',
          hint: 'e.g. Non-payment of fine',
          controller: reasonController,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const AppText.label('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const AppText.label('Seal', color: AppColors.error),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    await Get.find<SealController>().sealProperty(
      propertyId: chalaan.propertyId,
      propertyName: chalaan.propertyName,
      tenantName: chalaan.tenantName,
      reason: reasonController.text.trim(),
      relatedChalaanId: chalaan.id,
    );
    _refreshRelatedScreens();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${chalaan.propertyName} sealed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chalaanRepository = Get.find<ChalaanRepository>();
    final chalaan = chalaanRepository.getById(chalaanId);
    final history = chalaanRepository.getByTenant(chalaan.tenantId)
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));

    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(chalaan.tenantName)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleMedium(chalaan.propertyName),
                  const SizedBox(height: 4),
                  AppText.body(chalaan.propertyAddress),
                  const SizedBox(height: 12),
                  AppText.caption('Outstanding: ${Formatters.currency(chalaan.amount)}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Mark Collected',
                    variant: AppButtonVariant.secondary,
                    onPressed: chalaan.isSettled ? null : () => _markCollected(context, chalaan),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Seal Shop',
                    variant: AppButtonVariant.danger,
                    onPressed: () => _sealShop(context, chalaan),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const AppText.titleMedium('Chalaan History'),
            const SizedBox(height: 12),
            for (final item in history) ...[
              ChalaanTile(chalaan: item),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
