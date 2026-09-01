import 'package:flutter/material.dart';

import '../text/app_text.dart';

/// A generic single-select row of filter chips (Collections filter, Sealed
/// status filter, the Profile screen's theme picker, …).
class AppChipTabs<T> extends StatelessWidget {
  const AppChipTabs({
    super.key,
    required this.items,
    required this.itemLabel,
    required this.selected,
    required this.onChanged,
    this.itemIcon,
  });

  final List<T> items;
  final String Function(T item) itemLabel;
  final T selected;
  final ValueChanged<T> onChanged;

  /// An optional leading glyph per chip. The label always stays — the icon is
  /// a second reading of the choice, never the only one.
  final IconData? Function(T item)? itemIcon;

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
              child: Builder(
                builder: (BuildContext context) {
                  final Color? ink = isSelected ? scheme.onPrimary : null;
                  final IconData? icon = itemIcon?.call(item);
                  final label = AppText.label(itemLabel(item), color: ink);
                  if (icon == null) return label;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(icon, size: 16, color: ink),
                      const SizedBox(width: 7),
                      label,
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
