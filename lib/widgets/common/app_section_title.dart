import 'package:flutter/material.dart';

import '../../config/theme/app_brand.dart';
import '../../config/theme/app_radius.dart';
import '../text/app_text.dart';

/// A heading with the brand's rule stood on end beside it — enough to break a
/// long scroll into blocks without another card doing it.
class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.title, {super.key, this.trailing});

  final String title;

  /// Sits right after the title — a count badge, say.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 4,
          height: 17,
          decoration: BoxDecoration(
            color: context.brand.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(width: 9),
        Flexible(child: AppText.titleMedium(title, maxLines: 1)),
        if (trailing != null) ...<Widget>[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}
