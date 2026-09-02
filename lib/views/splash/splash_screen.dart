import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../config/theme/app_brand.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/widgets.dart';
import '../../config/theme/app_radius.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  /// Decides where the officer lands, before anything else is rendered.
  ///
  /// An officer who is already signed in goes straight to the dashboard rather
  /// than being made to type a password they have already given. The session
  /// check runs alongside the splash's minimum display time, so a fast network
  /// does not make the logo flash and a slow one does not add to the wait.
  Future<void> _route() async {
    final minimumDisplay = Future<void>.delayed(
      const Duration(milliseconds: 1200),
    );

    final signedIn = await Get.find<AuthController>().restoreSession();
    await minimumDisplay;

    if (!mounted) return;
    context.go(signedIn ? AppRoutes.magistrateHome : AppRoutes.login);
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
                ? <Color>[context.brand.headerTo, context.brand.headerFrom]
                : <Color>[context.brand.headerFrom, context.brand.headerTo],
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
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              const AppText.headlineLarge('MCQ', color: Colors.white),
              const SizedBox(height: 6),
              AppText.body(
                'Property finance, simplified',
                color: Colors.white.withValues(alpha: 0.8),
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
