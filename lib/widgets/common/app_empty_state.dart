import 'package:flutter/material.dart';

import '../buttons/app_button.dart';
import '../motion/app_stagger.dart';
import '../text/app_text.dart';
import 'app_illustration.dart';

/// The single "nothing here" placeholder every empty list uses.
///
/// **Never a blank screen and never "No data".** An empty list is an
/// answer, and which answer it is matters: "no shop in Circular Road is
/// past due today" is good news and must look like it, while "you hold no
/// area posting" is a problem for the Estate Branch. Both are drawn here,
/// with an animated illustration and a sentence in plain language.
///
/// The illustration, the heading and the sentence fade up in sequence, so
/// the officer's eye lands on the picture and is walked down to the words —
/// which is the difference between a designed state and three widgets in a
/// column.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.illustration,
    this.icon,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.compact = false,
  });

  final String title;

  /// The animated illustration. Prefer this — an icon is a fallback for a
  /// state too small to deserve one.
  final AppIllustrationKind? illustration;

  final IconData? icon;
  final String? message;

  /// The one thing to do about it, when there is one.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A second, quieter way out — "clear the filters" beside "try again".
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// A tighter version for an empty section inside a screen rather than an
  /// empty screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 28,
          vertical: compact ? 20 : 36,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              AppFadeIn(
                child: AppIllustration(
                  illustration!,
                  size: compact ? 112 : 156,
                ),
              )
            else if (icon != null)
              AppFadeIn(child: Icon(icon, size: 52, color: muted)),
            SizedBox(height: compact ? 12 : 18),
            AppFadeIn(
              delay: const Duration(milliseconds: 90),
              child: AppText.titleLarge(title, textAlign: TextAlign.center),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              AppFadeIn(
                delay: const Duration(milliseconds: 150),
                child: ConstrainedBox(
                  // A sentence measured to about 40 characters. Full-width
                  // body text on a phone is a paragraph nobody finishes.
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: AppText.body(
                    message!,
                    color: muted,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 16 : 24),
              AppFadeIn(
                delay: const Duration(milliseconds: 210),
                child: AppButton(
                  label: actionLabel!,
                  // Tonal, not filled: an empty state offers a way out, it
                  // does not demand one.
                  variant: AppButtonVariant.tonal,
                  fullWidth: false,
                  onPressed: onAction,
                ),
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 4),
              AppFadeIn(
                delay: const Duration(milliseconds: 250),
                child: TextButton(
                  onPressed: onSecondary,
                  child: AppText.label(secondaryLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
