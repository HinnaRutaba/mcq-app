import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

/// A round icon button — used as header actions (e.g. notifications) and
/// as the tappable circle in [AppQuickAction]. Supports a small unread
/// [badge] dot.
class AppCircleIconButton extends StatelessWidget {
  const AppCircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.background,
    this.iconColor,
    this.size = 42,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? background;
  final Color? iconColor;
  final double size;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: background ?? Colors.white.withValues(alpha: 0.16),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              height: size,
              width: size,
              child: Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: size * 0.5,
              ),
            ),
          ),
        ),
        if (badge)
          Positioned(
            right: 1,
            top: 1,
            child: Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
