import 'package:flutter/material.dart';

import '../buttons/app_button.dart';
import 'app_empty_state.dart';

/// The state a screen falls back to when its own load failed and there is
/// nothing behind the failure to show — the message the server or the radio
/// gave, and one button to try again.
///
/// Not a scroll view of its own: it is meant to sit inside the page's, which
/// is what keeps pull-to-refresh working on the very state an officer most
/// wants to retry from.
class AppErrorRetry extends StatelessWidget {
  const AppErrorRetry({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  /// What failed, in the screen's own words ("Could not load your beat").
  final String title;

  /// Why — the message off the failure, not a rewrite of it.
  final String message;

  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AppEmptyState(icon: icon, title: title, message: message),
          const SizedBox(height: 8),
          AppButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            fullWidth: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
