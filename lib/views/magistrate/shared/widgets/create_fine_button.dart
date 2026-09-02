import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../config/theme/app_brand.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';

/// The create button in the middle of the bar, and the gap the bar leaves for
/// it.
///
/// One definition so the button and the notch cut around it cannot drift: the
/// shell docks this and asks it for [notchGap] and [notchRadius], and the
/// widget preview does the same.
class CreateFineButton extends StatelessWidget {
  const CreateFineButton({super.key});

  static const double size = 56;

  /// The width the bar leaves in the middle of its row.
  static double get notchGap => AppBottomNavBar.notchGapFor(size);

  /// The cut's corner radius, matched to the button's own.
  static double get notchRadius =>
      AppBottomNavBar.notchRadiusFor(AppFab.defaultCornerRadius);

  @override
  Widget build(BuildContext context) {
    return AppFab(
      icon: Icons.add_rounded,
      label: 'Fine',
      size: size,
      color: context.brand.accent,
      // Not `brand.onAccent`, which is derived by luminance and lands on white
      // for the light gold — 2.3:1 under the label. This is the ink the
      // palette authored for gold: 6.9:1 light, 8.7:1 dark.
      foregroundColor: AppColors.onAccent,
      onTap: () => context.push(AppRoutes.createFine),
    );
  }
}
