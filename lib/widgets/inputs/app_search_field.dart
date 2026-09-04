import 'package:flutter/material.dart';

import 'app_text_field.dart';

/// A search input built on [AppTextField]: search icon up front, and a
/// clear ("x") button that appears once the user has typed something.
///
/// Shorter than a form field on purpose — see [AppTextField.dense]. The clear
/// button is tightened to match: an `IconButton` at its default 48pt would
/// set the height itself, and the box would grow the moment anything was
/// typed into it.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint = 'Search',
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;

  /// Passed in where something else owns the focus — a box whose suggestions
  /// open and close with it.
  final FocusNode? focusNode;

  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      focusNode: widget.focusNode,
      hint: widget.hint,
      prefixIcon: Icons.search_rounded,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      dense: true,
      suffixIcon: _hasText
          ? IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
              onPressed: _clear,
            )
          : null,
    );
  }
}
