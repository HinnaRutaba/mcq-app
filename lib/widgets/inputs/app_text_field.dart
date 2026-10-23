import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme/app_radius.dart';
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
    this.optional = false,
    this.inlineLabel = false,
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

  /// Says so beside the label. A form that marks what may be left out is
  /// faster than one where every blank field looks like an unfinished one.
  final bool optional;

  /// Puts [label] inside a filled, borderless field instead of above it — the
  /// wide sign-in layout. The outline still shows on focus and on error.
  final bool inlineLabel;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.obscureText;

  /// The theme's border for a state, redrawn so the label stays inside.
  InputBorder? _inline(InputBorder? border) => widget.inlineLabel
      ? _InlineLabelBorder(borderSide: border?.borderSide ?? BorderSide.none)
      : null;

  @override
  Widget build(BuildContext context) {
    final themed = Theme.of(context).inputDecorationTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null && !widget.inlineLabel) ...[
          Row(
            children: [
              // Flexible, so a label longer than the field wraps rather than
              // overflowing — which on a narrow handset it otherwise does.
              Flexible(child: AppText.label(widget.label!)),
              if (widget.optional) ...[
                const SizedBox(width: 6),
                AppText.caption(
                  'Optional',
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
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
            labelText: widget.inlineLabel ? widget.label : null,
            floatingLabelBehavior: widget.inlineLabel
                ? FloatingLabelBehavior.always
                : null,
            fillColor: widget.inlineLabel
                ? Theme.of(context).colorScheme.surfaceContainer
                : null,
            border: widget.inlineLabel ? const _InlineLabelBorder() : null,
            enabledBorder: widget.inlineLabel
                ? const _InlineLabelBorder()
                : null,
            disabledBorder: widget.inlineLabel
                ? const _InlineLabelBorder()
                : null,
            focusedBorder: _inline(themed.focusedBorder),
            errorBorder: _inline(themed.errorBorder),
            focusedErrorBorder: _inline(themed.focusedErrorBorder),
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

/// A rounded outline that reports itself as *not* an outline, so the
/// decorator floats the label inside the fill rather than onto the edge.
class _InlineLabelBorder extends OutlineInputBorder {
  const _InlineLabelBorder({super.borderSide = BorderSide.none})
    : super(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
      );

  @override
  bool get isOutline => false;

  @override
  _InlineLabelBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) => _InlineLabelBorder(borderSide: borderSide ?? this.borderSide);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is OutlineInputBorder
      ? _InlineLabelBorder(
          borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is OutlineInputBorder
      ? _InlineLabelBorder(
          borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        )
      : super.lerpTo(b, t);
}
