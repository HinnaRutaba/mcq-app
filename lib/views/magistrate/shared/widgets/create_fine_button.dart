import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../config/theme/app_brand.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../controllers/challans_controller.dart';
import '../../../../models/fine.dart';
import '../../../../widgets/widgets.dart';

class CreateFineButton extends StatelessWidget {
  const CreateFineButton({
    super.key,
    this.propertyId,
    this.allotmentId,
    this.onImposed,
  });

  /// The unit the fine is being imposed on, when the button is pressed from
  /// that unit's own screen. Null on the shell's bar, where the officer picks
  /// the shop on the form.
  final int? propertyId;

  /// The tenancy on that unit, which is what the fine is billed to. Null where
  /// nobody holds the unit, and on the shell's bar.
  final int? allotmentId;

  /// Re-reads the screen this button was pressed on, when a fine came back.
  ///
  /// The challan list is refreshed for every caller — a fine is a challan, so
  /// it is out of date wherever the fine was raised from. Only the screen that
  /// raised it knows what else the fine changed on it.
  final Future<void> Function()? onImposed;

  static const double size = 56;

  /// The width the bar leaves in the middle of its row.
  static double get notchGap => AppBottomNavBar.notchGapFor(size);

  /// The cut's corner radius, matched to the button's own.
  static double get notchRadius =>
      AppBottomNavBar.notchRadiusFor(AppFab.defaultCornerRadius);

  /// Anything other than null came back means a fine was posted: the form pops
  /// the [Fine] the server wrote, and an abandoned form pops nothing.
  Future<void> _impose(BuildContext context) async {
    final Fine? imposed = await context.push<Fine>(
      AppRoutes.createFinePath(
        propertyId: propertyId,
        allotmentId: allotmentId,
      ),
    );
    if (imposed == null) return;
    await ChallansController.reloadIfOpened();
    if (!context.mounted) return;
    await onImposed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AppFab(
      icon: Icons.add_card,
      label: 'Fine',
      size: size,
      color: context.brand.accent,
      foregroundColor: AppColors.onAccent,
      onTap: () => _impose(context),
    );
  }
}
