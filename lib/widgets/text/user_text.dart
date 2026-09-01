import 'package:flutter/material.dart';

import 'app_text.dart';

/// Text that came from a person, not from us.
///
/// Allottee names, market names, remarks and addresses are user data and
/// may be Urdu, Latin or mixed — `Asfand (ایڈمن)`. Left alone, bidi
/// reorders the brackets and the name renders mangled, and a right-to-left
/// name in a left-to-right layout jumps to the wrong side of the row.
///
/// This is the `dir="auto"` equivalent: the paragraph direction is taken
/// from the first strong character in the string itself, and the run is
/// isolated so it cannot reorder the text around it.
class UserText extends StatelessWidget {
  const UserText(
    this.text, {
    super.key,
    this.variant = AppTextVariant.bodyMedium,
    this.color,
    this.fontWeight,
    this.maxLines,
    this.fallback = '—',
  });

  const UserText.name(
    this.text, {
    super.key,
    this.color,
    this.maxLines = 1,
    this.fallback = '—',
  })  : variant = AppTextVariant.titleMedium,
        fontWeight = null;

  /// A name at the top of a card, where it is the first thing read.
  const UserText.headline(
    this.text, {
    super.key,
    this.color,
    this.maxLines = 2,
    this.fallback = '—',
  })  : variant = AppTextVariant.titleLarge,
        fontWeight = null;

  /// A name at display size — the hero of a profile page.
  const UserText.display(
    this.text, {
    super.key,
    this.color,
    this.maxLines = 2,
    this.fallback = '—',
  })  : variant = AppTextVariant.headlineMedium,
        fontWeight = null;

  const UserText.body(
    this.text, {
    super.key,
    this.color,
    this.maxLines,
    this.fallback = '—',
  })  : variant = AppTextVariant.bodyMedium,
        fontWeight = null;

  /// A market name or an area under a card's headline.
  const UserText.caption(
    this.text, {
    super.key,
    this.color,
    this.maxLines = 1,
    this.fallback = '—',
  })  : variant = AppTextVariant.bodySmall,
        fontWeight = null;

  final String? text;
  final AppTextVariant variant;
  final Color? color;
  final FontWeight? fontWeight;
  final int? maxLines;
  final String fallback;

  /// U+2068 FIRST STRONG ISOLATE … U+2069 POP DIRECTIONAL ISOLATE — the
  /// characters Unicode provides for exactly this, so nothing inside the
  /// name can affect the direction of anything outside it.
  static const String _isolateStart = '\u2068';
  static const String _isolateEnd = '\u2069';

  static String isolate(String value) => '$_isolateStart$value$_isolateEnd';

  @override
  Widget build(BuildContext context) {
    final value = (text ?? '').trim();
    if (value.isEmpty) {
      return AppText(fallback, variant: variant, color: color, maxLines: maxLines);
    }
    return AppText(
      isolate(value),
      variant: variant,
      color: color,
      fontWeight: fontWeight,
      maxLines: maxLines,
      textAlign: TextAlign.start,
    );
  }
}
