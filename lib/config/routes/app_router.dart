import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../views/auth/change_password_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/magistrate/collection_detail_screen.dart';
import '../../views/magistrate/collections_screen.dart';
import '../../views/magistrate/create_chalaan_screen.dart';
import '../../views/magistrate/magistrate_home_screen.dart';
import '../../views/magistrate/magistrate_profile_screen.dart';
import '../../views/magistrate/magistrate_shell.dart';
import '../../views/magistrate/sealed_screen.dart';
import '../../views/splash/splash_screen.dart';
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
    // Outside the shell on purpose: there is no bottom nav to wander off to
    // while the change is outstanding.
    GoRoute(
      path: AppRoutes.changePassword,
      builder: (context, state) => const ChangePasswordScreen(),
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
          CollectionDetailScreen(recordId: state.pathParameters['id']!),
    ),
  ],
);
