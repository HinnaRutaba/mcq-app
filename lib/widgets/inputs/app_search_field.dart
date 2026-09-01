import 'dart:async';

import 'package:flutter/material.dart';

import 'app_text_field.dart';

/// The search input every list uses: a search icon up front, a clear button
/// once there is something to clear, and — the part that matters — a
/// **debounce**.
///
/// Without it, every keystroke re-filters (and on the search screen,
/// re-requests). On a bazaar connection that is a request in flight for
/// every letter of a shopkeeper's name, all but the last of them wasted,
/// each one able to arrive out of order and overwrite the results of the
/// one after it. 300ms is the standard figure and it is right here: it is
/// under the threshold at which a person notices a delay, and it is longer
/// than the gap between keystrokes of anybody typing an Urdu name on a
/// phone keyboard.
///
/// [onChanged] still fires immediately for callers that need the raw text
/// (to show the clear button, to drive a local highlight); [onDebounced] is
/// the one that should do the work.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.onDebounced,
    this.onSubmitted,
    this.autofocus = false,
    this.debounce = const Duration(milliseconds: 300),
  });

  final TextEditingController? controller;
  final String hint;

  /// Fires on every keystroke.
  final ValueChanged<String>? onChanged;

  /// Fires once the officer has stopped typing for [debounce].
  final ValueChanged<String>? onDebounced;

  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final Duration debounce;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  Timer? _debounce;
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

  void _onChanged(String value) {
    widget.onChanged?.call(value);
    final debounced = widget.onDebounced;
    if (debounced == null) return;
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => debounced(value));
  }

  void _clear() {
    _controller.clear();
    // Clearing is deliberate and instant — there is nothing to wait for.
    _debounce?.cancel();
    widget.onChanged?.call('');
    widget.onDebounced?.call('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_handleTextChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      hint: widget.hint,
      prefixIcon: Icons.search_rounded,
      textInputAction: TextInputAction.search,
      autofocus: widget.autofocus,
      onChanged: _onChanged,
      onFieldSubmitted: (value) {
        // Submitting jumps the queue: the officer has said he is finished.
        _debounce?.cancel();
        widget.onDebounced?.call(value);
        widget.onSubmitted?.call(value);
      },
      suffixIcon: _hasText
          ? IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              onPressed: _clear,
            )
          : null,
    );
  }
}
