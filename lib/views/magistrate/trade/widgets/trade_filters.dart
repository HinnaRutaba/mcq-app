import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/trade_licences_controller.dart';
import '../../../../widgets/widgets.dart';

/// The bar over the licence list: which bazaar, and which of the three queues.
///
/// While the officer is looking a shop up it says something else entirely —
/// the lookup is not area-scoped, and a bazaar picker sitting over an answer
/// about the next bazaar would be a lie.
class TradeFilters extends StatelessWidget {
  const TradeFilters({super.key, required this.controller});

  final TradeLicencesController controller;

  static double heightFor({
    required bool withAreaPicker,
    required bool lookingUp,
  }) => lookingUp ? 56 : (withAreaPicker ? 62 : 16) + 56;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLookingUp) return const _LookupNote();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!controller.hasAreaChoice)
            const SizedBox(height: 16)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              child: AppDropdown<int>(
                items: controller.areaOptions,
                itemLabel: controller.areaLabel,
                value: controller.areaId.value,
                onChanged: controller.setArea,
                prefixIcon: Icons.place_outlined,
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AppChipTabs<TradeQueue>(
              items: TradeQueue.values,
              itemLabel: (TradeQueue queue) =>
                  '${queue.label} · ${controller.countOf(queue)}',
              selected: controller.queue.value,
              onChanged: controller.showQueue,
              compact: true,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 2,
            child: controller.isLoading.value && controller.hasData
                ? const LinearProgressIndicator(minHeight: 2)
                : null,
          ),
        ],
      );
    });
  }
}

/// What the search box is actually doing, said out loud: the doorway lookup
/// covers the whole city on purpose, so an officer standing in front of a shop
/// gets the true answer rather than the one their posting allows.
class _LookupNote extends StatelessWidget {
  const _LookupNote();

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: Row(
        children: <Widget>[
          Icon(Icons.travel_explore_outlined, size: 16, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: AppText.caption(
              'Looking across the whole city — a licence issued in the next '
              'bazaar is still valid.',
              color: muted,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
