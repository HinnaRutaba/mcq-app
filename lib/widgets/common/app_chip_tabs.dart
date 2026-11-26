import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../text/app_text.dart';
import '../../config/theme/app_radius.dart';

class AppChipTabs<T> extends StatefulWidget {
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
  State<AppChipTabs<T>> createState() => _AppChipTabsState<T>();
}

class _AppChipTabsState<T> extends State<AppChipTabs<T>> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _revealSelected(animate: false);
  }

  @override
  void didUpdateWidget(AppChipTabs<T> old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) _revealSelected();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Centres the selected chip, e.g. one picked by a dashboard tile far off
  /// to the right. Scrolls this row only, never the page around it.
  void _revealSelected({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderObject? chip = _selectedKey.currentContext
          ?.findRenderObject();
      if (!mounted || chip == null || !_scroll.hasClients) return;
      final ScrollPosition position = _scroll.position;
      final double target = RenderAbstractViewport.of(chip)
          .getOffsetToReveal(chip, 0.5)
          .offset
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      if (animate) {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final AppChipTabs<T> w = widget;

    // A Row, not a lazy list: a chip far off-screen must exist to scroll to.
    return SizedBox(
      height: w.compact ? 32 : 38,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (int index = 0; index < w.items.length; index++) ...<Widget>[
              if (index > 0) const SizedBox(width: 8),
              _chip(context, scheme, w, w.items[index]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    ColorScheme scheme,
    AppChipTabs<T> w,
    T item,
  ) {
    final isSelected = item == w.selected;
    final bool compact = w.compact;
    return GestureDetector(
      key: isSelected ? _selectedKey : null,
      onTap: () => w.onChanged(item),
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
            color: isSelected ? scheme.primary : Theme.of(context).dividerColor,
          ),
        ),
        child: Builder(
          builder: (BuildContext context) {
            final Color? ink = isSelected ? scheme.onPrimary : null;
            final IconData? icon = w.itemIcon?.call(item);
            final label = compact
                ? AppText.label(
                    w.itemLabel(item),
                    color: ink,
                    fontWeight: FontWeight.w700,
                  )
                : AppText.label(w.itemLabel(item), color: ink);
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
  }
}
