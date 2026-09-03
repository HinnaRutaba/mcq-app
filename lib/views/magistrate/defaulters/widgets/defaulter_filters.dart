import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/defaulters_controller.dart';
import '../../../../widgets/widgets.dart';

class DefaulterFilters extends StatelessWidget {
  const DefaulterFilters({super.key, required this.controller});

  final DefaultersController controller;

  static double heightFor({required bool withAreaPicker}) =>
      (withAreaPicker ? 62 : 16) + 56;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Obx(() {
          if (!controller.hasAreaChoice) return const SizedBox(height: 16);
          final List<int> options = controller.areaOptions;
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
            child: AppDropdown<int>(
              items: options,
              itemLabel: controller.areaLabel,
              value: controller.areaId.value,
              onChanged: controller.setArea,
              prefixIcon: Icons.place_outlined,
            ),
          );
        }),
        const SizedBox(height: 12),
        Obx(() {
          final Map<DefaulterState, int> counts = <DefaulterState, int>{
            for (final DefaulterState state in DefaulterState.values)
              state: controller.countOf(state),
          };

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AppChipTabs<DefaulterState>(
              items: DefaulterState.values,
              itemLabel: (DefaulterState state) =>
                  '${state.label} · ${counts[state]}',
              selected: controller.stateFilter.value,
              onChanged: controller.showState,
              compact: true,
            ),
          );
        }),
        const SizedBox(height: 10),
        Obx(
          () => SizedBox(
            height: 2,
            child: controller.isLoading.value && controller.hasData
                ? const LinearProgressIndicator(minHeight: 2)
                : null,
          ),
        ),
      ],
    );
  }
}
