import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/seal_controller.dart';
import '../../widgets/widgets.dart';
import 'widgets/seal_tile.dart';

class SealedScreen extends StatelessWidget {
  const SealedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SealController>();

    return Scaffold(
      appBar: AppBar(title: const AppText.titleLarge('Sealed Properties')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              Obx(
                () => AppChipTabs<SealFilter>(
                  items: SealFilter.values,
                  itemLabel: (f) => f.label,
                  selected: controller.filter.value,
                  onChanged: controller.setFilter,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  final seals = controller.filtered;
                  if (seals.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.lock_open_rounded,
                      title: 'Nothing here',
                      message: 'Sealed properties will show up here.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => controller.reload(),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: seals.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final seal = seals[index];
                        return SealTile(
                          seal: seal,
                          isProcessing: controller.isProcessing.value,
                          onRemove: () => controller.removeSeal(seal.id),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
