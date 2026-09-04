import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../text/app_text.dart';

/// The single text input widget every screen should use.
///
/// Wraps a [TextFormField] with an optional caption [label] above the
/// field and a password visibility toggle when [obscureText] is true, and
/// otherwise relies on `InputDecorationTheme` (see `app_theme.dart`) so it
/// stays visually consistent app-wide.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.inputFormatters,
    this.autofillHints,
    this.dense = false,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;

  /// Passed in where something else owns the focus — a search box whose
  /// suggestions open and close with it.
  final FocusNode? focusNode;

  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  /// A shorter field — 48pt instead of the theme's 52. For an input that sits
  /// over a list rather than in a form: a search box in a header, where the
  /// height is spent on chrome and not on the answer.
  final bool dense;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          AppText.label(widget.label!),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          enabled: widget.enabled,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          inputFormatters: widget.inputFormatters,
          autofillHints: widget.autofillHints,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            // Null keeps `InputDecorationTheme`'s own padding, so an ordinary
            // form field is untouched by this.
            contentPadding: widget.dense
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
                : null,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20)
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}
