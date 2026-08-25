import 'package:flutter/material.dart';

import '../text/app_text.dart';

/// A generic single-select row of filter chips (Tenant Payments status
/// filter, Magistrate Collections filter, Sealed status filter, …).
class AppChipTabs<T> extends StatelessWidget {
  const AppChipTabs({
    super.key,
    required this.items,
    required this.itemLabel,
    required this.selected,
    required this.onChanged,
  });

  final List<T> items;
  final String Function(T item) itemLabel;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item == selected;
          return GestureDetector(
            onTap: () => onChanged(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? scheme.primary : Theme.of(context).dividerColor,
                ),
              ),
              child: AppText.label(
                itemLabel(item),
                color: isSelected ? scheme.onPrimary : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
