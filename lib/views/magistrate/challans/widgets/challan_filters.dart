import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/challans_controller.dart';
import '../../../../widgets/widgets.dart';

/// The bar over the challan list: rent bills, penalties, or both.
///
/// No counts on the chips. Two of the three are a different request to the
/// server, so the rows for the queue an officer is *not* looking at are not in
/// hand — a figure here would be a guess.
class ChallanFilters extends StatelessWidget {
  const ChallanFilters({super.key, required this.controller});

  final ChallansController controller;

  /// 14 over the chips, a compact chip row, 10 under it, and the progress hair.
  static const double height = 58;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AppChipTabs<ChallanFilter>(
              items: ChallanFilter.values,
              itemLabel: (ChallanFilter filter) => filter.label,
              selected: controller.filter.value,
              onChanged: controller.showFilter,
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
      ),
    );
  }
}
