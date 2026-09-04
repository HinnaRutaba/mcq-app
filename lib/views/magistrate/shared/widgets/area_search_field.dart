import 'package:flutter/material.dart';

import '../../../../config/theme/app_radius.dart';
import '../../../../models/field_beat.dart';
import '../../../../widgets/widgets.dart';

class AreaSearchField extends StatefulWidget {
  const AreaSearchField({
    super.key,
    required this.controller,
    required this.optionsFor,
    required this.onSelected,
    required this.onChanged,
    required this.selected,
    required this.onCleared,
    this.note,
    this.hint = 'Search the area',
    this.error,
  });

  /// The text being searched with, held by the fine's own controller so a
  /// rebuild does not lose it.
  final TextEditingController controller;

  /// The areas matching what has been typed. Called with an empty string
  /// when the box is focused and empty, which is what offers the whole beat.
  final List<FieldArea> Function(String term) optionsFor;

  final ValueChanged<FieldArea> onSelected;
  final ValueChanged<String> onChanged;

  /// The area the fine will name, once one is taken.
  final FieldArea? selected;

  /// Cancelling it. The box takes the focus back, so the next one is one tap
  /// away rather than two.
  final VoidCallback onCleared;

  /// What taking this area does, under its name on the card — a fine is
  /// posted to one, a licence is priced for one.
  final String? note;

  final String hint;

  /// What the server said about the area, under the box that chose it. A
  /// refusal naming `area_id` is the officer's to fix, so it belongs on the
  /// field rather than only in the bar at the bottom.
  final String? error;

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

  void _cancel() {
    widget.onCleared();
    widget.controller.clear();
    _focus.requestFocus();
  }

  void _take(FieldArea area) {
    widget.onSelected(area);
    // Taken, so the suggestions have nothing left to offer: without this the
    // box reopens the moment the text is cleared behind the choice.
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _field(context),
        if (widget.selected != null) ...<Widget>[
          const SizedBox(height: 12),
          _SelectedArea(
            area: widget.selected!,
            note: widget.note,
            onCancel: _cancel,
          ),
        ],
        if (widget.error != null) ...<Widget>[
          const SizedBox(height: 6),
          AppText.caption(
            widget.error!,
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ],
    );
  }

  /// The box itself. The overlay is measured against it, so the suggestions
  /// line up with the field instead of the screen.
  Widget _field(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return RawAutocomplete<FieldArea>(
          textEditingController: widget.controller,
          focusNode: _focus,
          displayStringForOption: (FieldArea area) => area.areaName,
          optionsBuilder: (TextEditingValue value) =>
              widget.optionsFor(value.text),
          onSelected: _take,
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

/// The area the fine will be posted against, with what the beat knows about
/// it — and the way out of it.
class _SelectedArea extends StatelessWidget {
  const _SelectedArea({
    required this.area,
    required this.note,
    required this.onCancel,
  });

  final FieldArea area;
  final String? note;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.location_on_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppText.titleMedium(area.areaName),
                    if (note != null) ...<Widget>[
                      const SizedBox(height: 2),
                      AppText.caption(note!, color: muted),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: 'Choose another area',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (area.zoneName != null)
            AppDetailRow(icon: Icons.map_outlined, value: area.zoneName!),
        ],
      ),
    );
  }
}
