import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/collections_controller.dart';
import '../../core/utils/get_helpers.dart';
import '../../widgets/widgets.dart';
import 'widgets/collection_tile.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => CollectionsController());

    return Scaffold(
      body: Column(
        children: [
          const AppHeroHeader(title: 'Collections'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  AppSearchField(
                    hint: 'Search tenant, shop, address…',
                    onChanged: controller.setQuery,
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => AppChipTabs<CollectionsFilter>(
                      items: CollectionsFilter.values,
                      itemLabel: (f) => f.label,
                      selected: controller.filter.value,
                      onChanged: controller.setFilter,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Obx(() {
                      final chalaans = controller.filtered;
                      if (chalaans.isEmpty) {
                        return const AppEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No collections found',
                          message: 'Try a different search or filter.',
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async => controller.reload(),
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: chalaans.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final chalaan = chalaans[index];
                            return CollectionTile(
                              chalaan: chalaan,
                              onTap: () =>
                                  context.push(AppRoutes.collectionDetailPath(chalaan.id)),
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
        ],
      ),
    );
  }
}
