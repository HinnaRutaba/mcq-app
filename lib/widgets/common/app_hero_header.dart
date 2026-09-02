import 'package:flutter/material.dart';

import '../../config/theme/app_brand.dart';
import '../text/app_text.dart';
import 'app_hero_ornament.dart';
import '../../config/theme/app_radius.dart';

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
    this.leading,
    this.trailing,
    this.bottom,
  });

  final String title;
  final String? subtitle;

  /// Sits before the title — a back arrow on a pushed screen. Screens reached
  /// from the bottom bar leave it null; there is nothing to go back to.
  final Widget? leading;

  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    // Clipped rather than merely rounded: the ornament is pinned past the
    // bottom-right corner, and a `BoxDecoration` radius shapes the paint, not
    // the children drawn over it.
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.xl),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[brand.headerFrom, brand.headerTo],
          ),
        ),
        child: Stack(
          children: <Widget>[
            const Positioned(right: -26, bottom: -44, child: AppHeroOrnament()),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 18,
                20,
                26,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (subtitle != null) ...[
                              AppText.body(
                                subtitle!,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                              const SizedBox(height: 2),
                            ],
                            // `titleLarge` because that is what this app already
                            // calls an app-bar title — `appBarTheme.titleTextStyle`
                            // is the same style, so the gradient block and the one
                            // plain `AppBar` in the app agree on a title's size.
                            AppText.titleLarge(
                              title,
                              color: Colors.white,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  if (bottom != null) ...[const SizedBox(height: 20), bottom!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
