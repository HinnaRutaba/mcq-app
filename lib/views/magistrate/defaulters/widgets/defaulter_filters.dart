import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/defaulters_controller.dart';
import '../../../../widgets/widgets.dart';

class DefaulterFilters extends StatelessWidget {
  const DefaulterFilters({super.key, required this.controller});

  final DefaultersController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Obx(() {
          final List<int> options = controller.areaOptions;
          // Nothing to pick between until the beat's scope has landed, and
          // nothing worth showing if it never does.
          if (options.length < 2) return const SizedBox(height: 16);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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
          // Counted here rather than inside `itemLabel`: that callback is run
          // by the chip row's own builder, after this one has returned, so a
          // count read in it registers with no observable and the figures sit
          // stale until something else rebuilds the row.
          final Map<DefaulterState, int> counts = <DefaulterState, int>{
            for (final DefaulterState state in DefaulterState.values)
              state: controller.countOf(state),
          };

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
