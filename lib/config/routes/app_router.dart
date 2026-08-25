import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../views/auth/login_screen.dart';
import '../../views/magistrate/magistrate_dashboard_screen.dart';
import '../../views/splash/splash_screen.dart';
import '../../views/tenant/tenant_dashboard_screen.dart';
import 'app_routes.dart';

/// Global navigator key, handy for navigating from outside the widget tree
/// (e.g. controllers) if ever needed.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// App-wide [GoRouter] configuration.
///
/// All navigation (splash -> login -> role dashboard) is declared here.
/// Add new routes as dedicated screens are built out.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.magistrateDashboard,
      builder: (context, state) => const MagistrateDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.tenantDashboard,
      builder: (context, state) => const TenantDashboardScreen(),
    ),
  ],
);
