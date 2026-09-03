import 'package:flutter/material.dart';

import '../text/app_text.dart';
import '../../config/theme/app_radius.dart';

class AppChipTabs<T> extends StatelessWidget {
  const AppChipTabs({
    super.key,
    required this.items,
    required this.itemLabel,
    required this.selected,
    required this.onChanged,
    this.itemIcon,
    this.compact = false,
  });

  final List<T> items;
  final String Function(T item) itemLabel;
  final T selected;
  final ValueChanged<T> onChanged;

  /// An optional leading glyph per chip. The label always stays — the icon is
  /// a second reading of the choice, never the only one.
  final IconData? Function(T item)? itemIcon;

  /// A tighter chip, for a filter bar that sits over a list rather than a
  /// single choice a page is built around.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: compact ? 32 : 38,
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
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected
                      ? scheme.primary
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Builder(
                builder: (BuildContext context) {
                  final Color? ink = isSelected ? scheme.onPrimary : null;
                  final IconData? icon = itemIcon?.call(item);
                  final label = compact
                      ? AppText.label(
                          itemLabel(item),
                          color: ink,
                          fontWeight: FontWeight.w700,
                        )
                      : AppText.label(itemLabel(item), color: ink);
                  if (icon == null) return label;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(icon, size: compact ? 14 : 16, color: ink),
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
