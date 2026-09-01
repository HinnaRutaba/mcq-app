import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/routes/app_router.dart';
import '../config/theme/app_theme.dart';
import '../controllers/theme_controller.dart';

/// Root widget: wires up theming (light/dark) and routing.
class McqApp extends StatelessWidget {
  const McqApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => MaterialApp.router(
        title: 'MCQ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(themeController.colorScheme.value),
        darkTheme: AppTheme.dark(themeController.colorScheme.value),
        themeMode: themeController.themeMode.value,
        routerConfig: appRouter,
      ),
    );
  }
}
