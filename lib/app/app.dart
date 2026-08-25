import 'package:flutter/material.dart';

import '../config/routes/app_router.dart';
import '../config/theme/app_theme.dart';

/// Root widget: wires up theming (light/dark) and routing.
class McqApp extends StatelessWidget {
  const McqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MCQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
