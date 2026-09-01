import 'package:flutter/material.dart';

/// Every text style the app uses, mapped 1:1 to [TextTheme] so a single
/// change in `AppTextTheme` restyles every [AppText] in the app.
enum AppTextVariant {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

/// The single [Text] widget every screen should use.
///
/// Never use the raw [Text] widget directly — go through [AppText] (or one
/// of its named constructors) so typography stays consistent and themeable.
class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.variant = AppTextVariant.bodyMedium,
    this.color,
    this.textAlign,
    this.fontWeight,
    this.maxLines,
    this.overflow,
    this.decoration,
    this.fontFeatures,
  });

  const AppText.displayLarge(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.displayLarge;

  const AppText.displayMedium(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.displayMedium;

  /// The big figure on a profile or a dashboard tile.
  const AppText.displaySmall(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.displaySmall;

  const AppText.headlineLarge(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.headlineLarge;

  const AppText.headlineMedium(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.headlineMedium;

  const AppText.headlineSmall(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.headlineSmall;

  const AppText.titleLarge(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.titleLarge;

  const AppText.titleMedium(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.titleMedium;

  const AppText.titleSmall(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.titleSmall;

  const AppText.body(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.bodyMedium;

  const AppText.bodyLarge(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.bodyLarge;

  const AppText.bodySmall(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.bodySmall;

  const AppText.label(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.labelLarge;

  const AppText.labelMedium(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.labelMedium;

  const AppText.caption(this.text, {super.key, this.color, this.textAlign, this.fontWeight, this.maxLines, this.overflow, this.decoration})
      : fontFeatures = null,
        variant = AppTextVariant.labelSmall;

  final String text;
  final AppTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final FontWeight? fontWeight;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDecoration? decoration;

  /// OpenType features, e.g. tabular figures so a column of amounts lines
  /// up. See [MoneyText], which is the only place that should need this.
  final List<FontFeature>? fontFeatures;

  TextStyle? _resolve(TextTheme theme) {
    switch (variant) {
      case AppTextVariant.displayLarge:
        return theme.displayLarge;
      case AppTextVariant.displayMedium:
        return theme.displayMedium;
      case AppTextVariant.displaySmall:
        return theme.displaySmall;
      case AppTextVariant.headlineLarge:
        return theme.headlineLarge;
      case AppTextVariant.headlineMedium:
        return theme.headlineMedium;
      case AppTextVariant.headlineSmall:
        return theme.headlineSmall;
      case AppTextVariant.titleLarge:
        return theme.titleLarge;
      case AppTextVariant.titleMedium:
        return theme.titleMedium;
      case AppTextVariant.titleSmall:
        return theme.titleSmall;
      case AppTextVariant.bodyLarge:
        return theme.bodyLarge;
      case AppTextVariant.bodyMedium:
        return theme.bodyMedium;
      case AppTextVariant.bodySmall:
        return theme.bodySmall;
      case AppTextVariant.labelLarge:
        return theme.labelLarge;
      case AppTextVariant.labelMedium:
        return theme.labelMedium;
      case AppTextVariant.labelSmall:
        return theme.labelSmall;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _resolve(Theme.of(context).textTheme) ?? const TextStyle();
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
      style: base.copyWith(
        color: color ?? base.color,
        fontWeight: fontWeight ?? base.fontWeight,
        decoration: decoration,
        fontFeatures: fontFeatures,
      ),
    );
  }
}
