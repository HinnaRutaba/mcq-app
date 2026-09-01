import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../motion/app_pressable.dart';
import '../text/app_text.dart';

/// One option in a filter row.
class AppFilterOption<T> {
  const AppFilterOption({
    required this.value,
    required this.label,
    this.icon,
    this.count,
    this.tone,
  });

  final T value;
  final String label;

  /// An icon makes the row scannable at a glance and keeps the chip
  /// legible when the label is truncated on a narrow handset.
  final IconData? icon;

  /// How many rows this filter would leave. Shown on the chip, so the
  /// officer knows a filter is empty *before* he taps into an empty list.
  final int? count;

  /// Colours the chip when selected — a "sealed" filter selects red, a
  /// "promise broken" filter selects amber. Null uses the brand.
  final AppTone? tone;
}

/// The horizontal filter row every list uses.
///
/// Real Material [FilterChip]s in a scrolling row: they bring the selected
/// state, the ink, the 48dp target, the disabled treatment and the
/// `checkbox`/`selected` semantics a screen reader needs. What is added on
/// top is the two things Material has no opinion about — an icon and a
/// count on every chip, so the row is scannable and no filter is a
/// surprise.
///
/// The row scrolls rather than wrapping. A filter row that wraps to three
/// lines pushes the list itself off the screen, and the filters are not the
/// content.
class AppFilterBar<T> extends StatelessWidget {
  const AppFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsetsDirectional.symmetric(horizontal: 18),
    this.trailing = const [],
  });

  final List<AppFilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final EdgeInsetsGeometry padding;

  /// A second group after a divider — the officer's areas, typically.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              AppFilterChip(
                label: options[i].label,
                icon: options[i].icon,
                count: options[i].count,
                tone: options[i].tone,
                selected: options[i].value == selected,
                onSelected: () => onChanged(options[i].value),
              ),
            ],
            if (trailing.isNotEmpty) ...[
              const SizedBox(width: 10),
              const _Separator(),
              const SizedBox(width: 10),
              for (var i = 0; i < trailing.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                trailing[i],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// A single filter chip, toned and counted.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.count,
    this.tone,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;
  final int? count;
  final AppTone? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = tone?.on(context) ?? scheme.primary;
    final onAccent = tone == null
        ? scheme.onPrimary
        : tone!.onFilled(context);
    final foreground = selected ? onAccent : scheme.onSurfaceVariant;

    return FilterChip(
      selected: selected,
      onSelected: (_) {
        AppHaptics.select();
        onSelected();
      },
      selectedColor: accent,
      side: BorderSide(
        color: selected ? accent : scheme.outline,
      ),
      avatar: icon == null
          ? null
          : Icon(icon, size: 18, color: foreground),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.labelMedium(label, color: foreground, maxLines: 1),
          if (count != null) ...[
            const SizedBox(width: 7),
            // The count rides in its own capsule so it reads as a figure
            // rather than as part of the word.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? onAccent.withValues(alpha: 0.20)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AppText.caption('$count', color: foreground),
            ),
          ],
        ],
      ),
    );
  }
}

/// A generic single-select row of choice chips (a status filter, a period
/// picker, a theme switch) where there is no count to show.
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
  final IconData? Function(T item)? itemIcon;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item == selected;
          final icon = itemIcon?.call(item);
          return ChoiceChip(
            selected: isSelected,
            onSelected: (_) {
              AppHaptics.select();
              onChanged(item);
            },
            selectedColor: scheme.primary,
            side: BorderSide(
              color: isSelected ? scheme.primary : scheme.outline,
            ),
            avatar: icon == null
                ? null
                : Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
            label: AppText.labelMedium(
              itemLabel(item),
              color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
              maxLines: 1,
            ),
          );
        },
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      color: Theme.of(context).dividerColor,
    );
  }
}
