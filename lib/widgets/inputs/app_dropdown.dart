import 'package:flutter/material.dart';

import '../text/app_text.dart';

/// The single dropdown widget every screen should use.
///
/// Generic over [T] — pass [itemLabel] to describe how each item is
/// displayed, so it works for enums, models, or plain strings alike.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.itemLabel,
    this.value,
    this.onChanged,
    this.label,
    this.hint = 'Select',
    this.enabled = true,
    this.prefixIcon,
    this.validator,
  });

  final List<T> items;
  final String Function(T item) itemLabel;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String hint;
  final bool enabled;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          AppText.label(label!),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: AppText(itemLabel(item)),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          validator: validator,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          ),
        ),
      ],
    );
  }
}
