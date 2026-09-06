import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/widgets.dart';

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
    return Scaffold(
      body: AppBrandBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 28),
            child: Column(
              children: <Widget>[
                const Spacer(),
                const AppLogo(size: 116),
                const SizedBox(height: 28),
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
                const Spacer(),
                const AppGovernmentMark(onDark: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
