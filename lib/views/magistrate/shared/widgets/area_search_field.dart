import 'package:flutter/material.dart';

import '../../../../config/theme/app_radius.dart';
import '../../../../models/field_beat.dart';
import '../../../../widgets/widgets.dart';

/// A search box for the officer's bazaars, with the matches offered under the
/// box itself rather than laid out down the form.
///
/// The list belongs to the field: on a form with four other blocks on it, a
/// run of tiles under a search box reads as content, and an officer scrolling
/// past it loses the box they were typing in.
class AreaSearchField extends StatefulWidget {
  const AreaSearchField({
    super.key,
    required this.controller,
    required this.optionsFor,
    required this.onSelected,
    required this.onChanged,
    this.hint = 'Search the bazaar',
  });

  /// The text being searched with, held by the fine's own controller so a
  /// rebuild does not lose it.
  final TextEditingController controller;

  /// The bazaars matching what has been typed. Called with an empty string
  /// when the box is focused and empty, which is what offers the whole beat.
  final List<FieldArea> Function(String term) optionsFor;

  final ValueChanged<FieldArea> onSelected;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  State<AreaSearchField> createState() => _AreaSearchFieldState();
}

class _AreaSearchFieldState extends State<AreaSearchField> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The overlay is measured against the field, so the suggestions line up
    // with the box instead of the screen.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return RawAutocomplete<FieldArea>(
          textEditingController: widget.controller,
          focusNode: _focus,
          displayStringForOption: (FieldArea area) => area.areaName,
          optionsBuilder: (TextEditingValue value) =>
              widget.optionsFor(value.text),
          onSelected: widget.onSelected,
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController textController,
                FocusNode node,
                VoidCallback onFieldSubmitted,
              ) => AppSearchField(
                controller: textController,
                focusNode: node,
                hint: widget.hint,
                onChanged: widget.onChanged,
                onSubmitted: (_) => onFieldSubmitted(),
              ),
          optionsViewBuilder:
              (
                BuildContext context,
                AutocompleteOnSelected<FieldArea> onSelected,
                Iterable<FieldArea> options,
              ) => _Suggestions(
                width: constraints.maxWidth,
                options: options.toList(),
                onSelected: onSelected,
              ),
        );
      },
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.width,
    required this.options,
    required this.onSelected,
  });

  final double width;
  final List<FieldArea> options;
  final AutocompleteOnSelected<FieldArea> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Material(
          elevation: 4,
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: width,
            // Four rows and a bit: enough to show there is more to scroll,
            // without the box covering the whole form.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 232),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: theme.dividerColor),
                itemBuilder: (BuildContext context, int index) {
                  final FieldArea area = options[index];
                  return InkWell(
                    onTap: () => onSelected(area),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: AppText.body(area.areaName)),
                          if (area.zoneName != null)
                            AppText.caption(area.zoneName!, color: muted),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
