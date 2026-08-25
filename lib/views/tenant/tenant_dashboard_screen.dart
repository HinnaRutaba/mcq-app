import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/widgets.dart';

/// Placeholder Tenant dashboard. Real features land here once specified.
class TenantDashboardScreen extends StatelessWidget {
  const TenantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText.titleLarge('Tenant Dashboard')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppText.headlineMedium('Welcome, Tenant'),
              const SizedBox(height: 8),
              const AppText.body('Your dashboard content will go here.'),
              const SizedBox(height: 32),
              AppButton(
                label: 'Log out',
                variant: AppButtonVariant.outline,
                fullWidth: false,
                onPressed: () {
                  Get.find<AuthController>().reset();
                  context.go(AppRoutes.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
