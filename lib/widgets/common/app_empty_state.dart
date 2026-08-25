import 'package:flutter/material.dart';

import '../text/app_text.dart';

/// The single "nothing here" placeholder every empty list should use.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, required this.icon, required this.title, this.message});

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: muted),
            const SizedBox(height: 16),
            AppText.titleMedium(title, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 6),
              AppText.body(message!, color: muted, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
