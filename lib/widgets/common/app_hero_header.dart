import 'package:flutter/material.dart';

import '../../config/theme/app_brand.dart';
import '../text/app_text.dart';
import 'app_hero_ornament.dart';
import '../../config/theme/app_radius.dart';

class AppHeroHeader extends StatelessWidget {
  const AppHeroHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.bottom,
    this.horizontalInset = 20,
  });

  final String title;
  final String? subtitle;

  final Widget? leading;

  final Widget? trailing;
  final Widget? bottom;

  /// How far the block is inset from the screen edges. The app's 20 by
  /// default; a screen on a different horizontal rhythm passes its own, so the
  /// header lines up with the content under it.
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

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
                horizontalInset,
                MediaQuery.paddingOf(context).top + 18,
                horizontalInset,
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
                  if (bottom != null) ...[const SizedBox(height: 6), bottom!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
