import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/theme/app_colors.dart';
import '../../controllers/api/session_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';

/// The launch screen.
///
/// Nothing is rendered until `GET /auth/device/session` has answered: 200
/// means the stored token is still good and gives the current user and
/// permissions, 401 means clear the keychain and show login. Skipping this
/// means discovering the token is dead three screens in.
class SessionBootScreen extends StatefulWidget {
  const SessionBootScreen({super.key});

  @override
  State<SessionBootScreen> createState() => _SessionBootScreenState();
}

class _SessionBootScreenState extends State<SessionBootScreen> {
  @override
  void initState() {
    super.initState();
    // The router's redirect moves the officer on as soon as the stage
    // changes; this screen never navigates itself.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Get.find<SessionController>().bootstrap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkBackground, AppColors.primaryDark]
                : [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 88,
                width: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              AppText.headlineLarge(t('app.name'), color: Colors.white),
              const SizedBox(height: 6),
              AppText.body(
                t('app.corporation'),
                color: Colors.white.withValues(alpha: 0.8),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(
                    Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
