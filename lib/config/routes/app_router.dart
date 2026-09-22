import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/defaulter_card.dart';
import '../../models/enforcement_case.dart';
import '../../views/auth/change_password_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/magistrate/defaulters/defaulters_screen.dart';
import '../../views/magistrate/home/home_screen.dart';
import '../../views/magistrate/magistrate_shell.dart';
import '../../views/magistrate/more/more_screen.dart';
import '../../views/magistrate/more/profile_screen.dart';
import '../../views/magistrate/more/sealed_screen.dart';
import '../../views/magistrate/round/round_screen.dart';
import '../../views/magistrate/search/unit_search_screen.dart';
import '../../views/magistrate/trade/trade_capture_screen.dart';
import '../../views/magistrate/trade/trade_licences_screen.dart';
import '../../controllers/property_profile_controller.dart';
import '../../views/magistrate/cases/cases_screen.dart';
import '../../views/magistrate/challans/challans_screen.dart';
import '../../views/magistrate/followups/follow_ups_screen.dart';
import '../../views/magistrate/shared/create_case_screen.dart';
import '../../views/magistrate/shared/create_seal_screen.dart';
import '../../views/magistrate/shared/record_action_screen.dart';
import '../../views/magistrate/shared/release_seal_screen.dart';
import '../../views/magistrate/shared/create_fine_screen.dart';
import '../../views/magistrate/property/property_profile_screen.dart';
import '../../views/splash/splash_screen.dart';
import '../theme/app_brand.dart';
import '../../widgets/widgets.dart';
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
    // Six branches, in the order they sit on the bar: Home, Defaulters,
    // Round, Licences, Challans, More. The branch index is the tab index —
    // `MagistrateShell` reads it straight off `navigationShell.currentIndex`,
    // so the two lists must stay in step.
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
              path: AppRoutes.magistrateDefaulters,
              builder: (context, state) => const DefaultersScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.magistrateRound,
              builder: (context, state) => const RoundScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.magistrateTradeLicences,
              builder: (context, state) => const TradeLicencesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.magistrateChallans,
              builder: (context, state) => const ChallansScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.magistrateMore,
              builder: (context, state) => const MoreScreen(),
              // Nested, so these push onto the More branch's own navigator and
              // the bottom bar stays put.
              routes: [
                GoRoute(
                  path: AppRoutes.magistrateSealedSegment,
                  builder: (context, state) => const SealedScreen(),
                ),
                GoRoute(
                  path: AppRoutes.magistrateProfileSegment,
                  builder: (context, state) => const MagistrateProfileScreen(),
                ),
                GoRoute(
                  path: AppRoutes.magistrateCasesSegment,
                  builder: (context, state) => const CasesScreen(),
                ),
                GoRoute(
                  path: AppRoutes.magistrateFollowUpsSegment,
                  builder: (context, state) => const FollowUpsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // --- Pushed full-screen routes (above the shell) ----------------------
    // Above the shell: a form the officer should finish or abandon, not wander
    // off from into another tab with a half-written fine behind them.
    GoRoute(
      path: AppRoutes.createFine,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => CreateFineScreen(
        propertyId: int.tryParse(state.uri.queryParameters['property'] ?? ''),
        allotmentId: int.tryParse(state.uri.queryParameters['allotment'] ?? ''),
      ),
    ),
    GoRoute(
      path: AppRoutes.createCase,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => CreateCaseScreen(
        propertyId: int.tryParse(state.uri.queryParameters['property'] ?? ''),
      ),
    ),
    GoRoute(
      path: AppRoutes.createSeal,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => CreateSealScreen(
        propertyId: int.tryParse(state.uri.queryParameters['property'] ?? '')!,
        caseId: int.tryParse(state.uri.queryParameters['case'] ?? ''),
        // The caller's own list, when it had one. A cold link carries none and
        // the form reads them itself.
        cases: state.extra is List<EnforcementCase>
            ? state.extra! as List<EnforcementCase>
            : null,
      ),
    ),
    GoRoute(
      path: AppRoutes.releaseSeal,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => ReleaseSealScreen(
        propertyId: int.parse(state.uri.queryParameters['property']!),
        sealId: int.tryParse(state.uri.queryParameters['seal'] ?? ''),
      ),
    ),
    GoRoute(
      path: AppRoutes.recordAction,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => RecordActionScreen(
        propertyId: int.parse(state.uri.queryParameters['property']!),
        actionCode: state.uri.queryParameters['type']!,
        caseId: int.tryParse(state.uri.queryParameters['case'] ?? ''),
        // The caller's own list, when it had one. A cold link carries none and
        // the form reads them itself.
        cases: state.extra is List<EnforcementCase>
            ? state.extra! as List<EnforcementCase>
            : null,
      ),
    ),
    GoRoute(
      path: AppRoutes.tradeCapture,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => TradeCaptureScreen(
        searched: state.uri.queryParameters['q'],
        areaId: int.tryParse(state.uri.queryParameters['area'] ?? ''),
      ),
    ),
    // Grown out of the box that opened it rather than slid in from the right:
    // the search box on Home becomes the search page. See [AppContainerPage].
    GoRoute(
      path: AppRoutes.unitSearch,
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        transitionDuration: AppContainerPage.openDuration,
        reverseTransitionDuration: AppContainerPage.closeDuration,
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) => AppContainerPage.grow(
              context,
              animation,
              child,
              // The circle that was pressed, when the officer came from one.
              from: state.extra is Rect ? state.extra! as Rect : null,
              // It sits on the hero header, and so does the top of the page it
              // opens: the surface growing out of it is that same green rather
              // than a white plate flashing across the header.
              fromColor: context.brand.headerFrom,
            ),
        child: const UnitSearchScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.propertyProfile,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => PropertyProfileScreen(
        propertyId: int.parse(state.pathParameters['id']!),
        // Present when the officer arrived from a list; null on a cold link,
        // which the screen is built to survive.
        card: state.extra is DefaulterCard
            ? state.extra! as DefaulterCard
            : null,
        initialTab: ProfileTab.byName(state.uri.queryParameters['tab']),
      ),
    ),
  ],
);
