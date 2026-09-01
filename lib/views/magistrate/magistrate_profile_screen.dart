import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../widgets/widgets.dart';

class MagistrateProfileScreen extends StatelessWidget {
  const MagistrateProfileScreen({super.key});

  static const _themeOptions = {
    ThemeMode.system: 'System',
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
  };

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      body: Column(
        children: [
          const AppHeroHeader(title: 'Profile'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.shield_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name, designation and posted bazaars come from
                      // `AuthRepository.currentSession()` and the beat's
                      // `scope.areaNames` once this screen is wired.
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.titleMedium('Signed-in officer'),
                            SizedBox(height: 2),
                            AppText.caption('Not wired up yet'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const AppText.titleMedium('Appearance'),
                const SizedBox(height: 12),
                Obx(
                  () => AppChipTabs<ThemeMode>(
                    items: _themeOptions.keys.toList(),
                    itemLabel: (mode) => _themeOptions[mode]!,
                    selected: themeController.themeMode.value,
                    onChanged: themeController.setThemeMode,
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Log Out',
                  variant: AppButtonVariant.outline,
                  onPressed: () {
                    Get.find<AuthController>().reset();
                    context.go(AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
