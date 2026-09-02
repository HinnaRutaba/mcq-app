import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../config/theme/app_brand.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';

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
      icon: Icons.add_card,
      label: 'Fine',
      size: size,
      color: context.brand.accent,
      foregroundColor: AppColors.onAccent,
      onTap: () => context.push(AppRoutes.createFine),
    );
  }
}
