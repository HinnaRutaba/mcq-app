import 'package:flutter/material.dart';

import '../text/app_text.dart';

/// A short message at the foot of the screen.
///
/// Painted in the bar's own ink: [AppText] otherwise takes the page's body
/// colour, which is dark on the dark bar and unreadable.
class AppSnackBar {
  AppSnackBar._();

  static void show(BuildContext context, String message) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: AppText.body(message, color: scheme.onInverseSurface)),
    );
  }
}
