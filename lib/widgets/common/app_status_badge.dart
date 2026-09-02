import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../text/app_text.dart';
import '../../config/theme/app_radius.dart';

/// The single status-pill widget every screen should use to show a state
/// (chalaan status, seal status, etc). Status is always paired with a text
/// [label] — never color alone.
///
/// Colors come from [AppTone], i.e. the theme's status palette, so this pill
/// is the same red as every other red in the app and re-steps itself for
/// dark mode.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppTone.neutral,
  });

  final String label;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone.on(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone.container(context),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: AppText.caption(label, color: color, fontWeight: FontWeight.w700),
    );
  }
}
