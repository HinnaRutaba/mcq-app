import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../text/app_text.dart';

/// The single header every screen should use instead of the plain default
/// [AppBar] — a bold gradient block with rounded bottom corners.
///
/// Pass just [title] for a simple screen header (Payments, Profile, …), or
/// add [subtitle]/[trailing]/[bottom] for a richer dashboard header (Home)
/// that carries a headline stat or quick facts.
class AppHeroHeader extends StatelessWidget {
  const AppHeroHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 18, 20, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurfaceVariant, AppColors.primaryDark]
              : [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle != null) ...[
                      AppText.body(subtitle!, color: Colors.white.withValues(alpha: 0.75)),
                      const SizedBox(height: 2),
                    ],
                    AppText.headlineMedium(title, color: Colors.white, maxLines: 1),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: 20),
            bottom!,
          ],
        ],
      ),
    );
  }
}
