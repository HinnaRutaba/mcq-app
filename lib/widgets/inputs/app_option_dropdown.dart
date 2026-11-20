import 'package:flutter/material.dart';

import '../../config/theme/app_radius.dart';
import '../text/app_text.dart';

/// A dropdown whose options need saying: each has an icon, a bold title and a
/// line under it. The menu opens below the field, as wide as the field.
///
/// For a plain list of names, [AppDropdown] is enough.
class AppOptionDropdown<T> extends StatefulWidget {
  const AppOptionDropdown({
    super.key,
    required this.items,
    required this.itemTitle,
    required this.itemIcon,
    this.itemDescription,
    this.value,
    this.onChanged,
    this.hint = 'Choose',
    this.validator,
  });

  final List<T> items;
  final String Function(T item) itemTitle;
  final IconData Function(T item) itemIcon;
  final String? Function(T item)? itemDescription;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String hint;
  final String? Function(T?)? validator;

  @override
  State<AppOptionDropdown<T>> createState() => _AppOptionDropdownState<T>();
}

class _AppOptionDropdownState<T> extends State<AppOptionDropdown<T>> {
  bool _open = false;

  void _choose(FormFieldState<T> field, T item) {
    field.didChange(item);
    widget.onChanged?.call(item);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool enabled = widget.onChanged != null;

    // [value] is the truth, read fresh each build; the field only carries the
    // error message.
    return FormField<T>(
      initialValue: widget.value,
      validator: (_) => widget.validator?.call(widget.value),
      builder: (FormFieldState<T> field) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final T? selected = widget.value;
          return MenuAnchor(
            onOpen: () => setState(() => _open = true),
            onClose: () => setState(() => _open = false),
            alignmentOffset: const Offset(0, 6),
            style: MenuStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(
                theme.colorScheme.surface,
              ),
              surfaceTintColor: const WidgetStatePropertyAll<Color>(
                Colors.transparent,
              ),
              elevation: const WidgetStatePropertyAll<double>(4),
              shadowColor: WidgetStatePropertyAll<Color>(
                Colors.black.withValues(alpha: 0.2),
              ),
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(vertical: 6),
              ),
              shape: WidgetStatePropertyAll<OutlinedBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: theme.dividerColor),
                ),
              ),
            ),
            menuChildren: <Widget>[
              for (final T item in widget.items)
                MenuItemButton(
                  onPressed: () => _choose(field, item),
                  style: const ButtonStyle(
                    padding: WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  child: SizedBox(
                    // Menu as wide as the field, less its own padding.
                    width: box.maxWidth - 24,
                    child: _Option(
                      icon: widget.itemIcon(item),
                      title: widget.itemTitle(item),
                      description: widget.itemDescription?.call(item),
                      selected: item == selected,
                    ),
                  ),
                ),
            ],
            builder: (BuildContext context, MenuController menu, _) => InkWell(
              onTap: !enabled
                  ? null
                  : () => menu.isOpen ? menu.close() : menu.open(),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InputDecorator(
                isEmpty: selected == null,
                isFocused: _open,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  errorText: field.errorText,
                  enabled: enabled,
                  prefixIcon: selected == null
                      ? null
                      : Icon(
                          widget.itemIcon(selected),
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                  suffixIcon: AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ),
                child: selected == null
                    ? null
                    : AppText.body(
                        widget.itemTitle(selected),
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final String? description;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.6,
    );

    return Row(
      children: <Widget>[
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: selected ? 0.18 : 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 19, color: primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppText.body(title, fontWeight: FontWeight.w700),
              if (description != null)
                AppText.caption(description!, color: muted),
            ],
          ),
        ),
        if (selected) ...<Widget>[
          const SizedBox(width: 8),
          Icon(Icons.check_rounded, size: 20, color: primary),
        ],
      ],
    );
  }
}
