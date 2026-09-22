import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/round_controller.dart';
import '../../../../widgets/widgets.dart';

/// The bar over the round: which bazaar to walk.
///
/// The counts are honest here without a call — the whole round arrived in one
/// payload — and each chip counts the markets it would actually leave on
/// screen. The markets' own figures are on their heads, not here: they are
/// four facts about a bazaar, not four things to filter by.
class RoundFilters extends StatelessWidget {
  const RoundFilters({super.key, required this.controller});

  final RoundController controller;

  /// 14 over the chips, a compact chip row, 10 under it, and the progress hair
  /// — or the hair alone on a beat with one bazaar, where there is nothing to
  /// pick between and an empty bar would just push the round down the screen.
  static double heightFor({required bool withAreaChips}) =>
      (withAreaChips ? 56 : 6) + 2;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (controller.hasAreaChoice) ...<Widget>[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AppChipTabs<int>(
                items: controller.areaOptions,
                itemLabel: (int id) =>
                    '${controller.areaLabel(id)} · ${controller.marketsIn(id)}',
                selected: controller.areaId.value,
                onChanged: controller.showArea,
                compact: true,
              ),
            ),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 6),
          SizedBox(
            height: 2,
            child: controller.isLoading.value && controller.hasData
                ? const LinearProgressIndicator(minHeight: 2)
                : null,
          ),
        ],
      ),
    );
  }
}
