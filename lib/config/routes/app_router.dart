import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../views/auth/login_screen.dart';
import '../../views/magistrate/collection_detail_screen.dart';
import '../../views/magistrate/collections_screen.dart';
import '../../views/magistrate/create_chalaan_screen.dart';
import '../../views/magistrate/magistrate_home_screen.dart';
import '../../views/magistrate/magistrate_profile_screen.dart';
import '../../views/magistrate/magistrate_shell.dart';
import '../../views/magistrate/sealed_screen.dart';
import '../../views/splash/splash_screen.dart';
import '../../views/tenant/tenant_home_screen.dart';
import '../../views/tenant/tenant_payments_screen.dart';
import '../../views/tenant/tenant_profile_screen.dart';
import '../../views/tenant/tenant_shell.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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

    // --- Tenant shell ----------------------------------------------------
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          TenantShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.tenantHome,
              builder: (context, state) => const TenantHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.tenantPayments,
              builder: (context, state) => const TenantPaymentsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.tenantProfile,
              builder: (context, state) => const TenantProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // --- Magistrate shell --------------------------------------------------
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MagistrateShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.magistrateHome,
              builder: (context, state) => const MagistrateHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.magistrateCollections,
              builder: (context, state) => const CollectionsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.magistrateSealed,
              builder: (context, state) => const SealedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.magistrateProfile,
              builder: (context, state) => const MagistrateProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // --- Pushed full-screen routes (above the shell) ----------------------
    GoRoute(
      path: AppRoutes.createChalaan,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CreateChalaanScreen(),
    ),
    GoRoute(
      path: AppRoutes.collectionDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          CollectionDetailScreen(chalaanId: state.pathParameters['id']!),
    ),
  ],
);
