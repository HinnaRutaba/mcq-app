import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/api/seal_form_controller.dart';
import '../../controllers/api/session_controller.dart';
import '../../models/property/property_summary.dart';
import '../../views/auth/change_password_screen.dart';
import '../../views/auth/officer_login_screen.dart';
import '../../views/magistrate/api/case_detail_screen.dart';
import '../../views/magistrate/api/case_write_args.dart';
import '../../views/magistrate/api/cases_screen.dart';
import '../../views/magistrate/api/fine_form_screen.dart';
import '../../views/magistrate/api/fines_screen.dart';
import '../../views/magistrate/api/legal_screen.dart';
import '../../views/magistrate/api/more_screen.dart';
import '../../views/magistrate/api/offline_queue_screen.dart';
import '../../views/magistrate/api/officer_shell.dart';
import '../../views/magistrate/api/property_profile_screen.dart';
import '../../views/magistrate/api/record_action_screen.dart';
import '../../views/magistrate/api/record_inspection_screen.dart';
import '../../views/magistrate/api/seal_form_screen.dart';
import '../../views/magistrate/api/settings_screen.dart';
import '../../views/magistrate/field/activity_screen.dart';
import '../../views/magistrate/field/beat_screen.dart';
import '../../views/magistrate/field/field_defaulters_screen.dart';
import '../../views/magistrate/field/field_seals_screen.dart';
import '../../views/magistrate/field/follow_ups_screen.dart';
import '../../views/magistrate/field/map_screen.dart';
import '../../views/magistrate/field/queue_list_screen.dart';
import '../../views/magistrate/field/round_screen.dart';
import '../../views/magistrate/field/shop_profile_screen.dart';
import '../../views/magistrate/field/unit_search_screen.dart';
import '../../views/magistrate/field/widgets/field_actions.dart';
import '../../views/splash/session_boot_screen.dart';
import '../../models/field/field_card.dart';
import 'app_routes.dart';
import 'queue_destination.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// The router, with the two guards the app needs: "signed in", and "must
/// change password".
///
/// Guards live here rather than in screens so no screen can be walked past.
/// A 401 anywhere flips the session stage, the refresh listenable fires, and
/// the officer lands on login — once, with an explanation. A 403 does
/// nothing here at all: it is the refusal of one action, not an expiry.
final GoRouter appRouter = _buildRouter();

GoRouter _buildRouter() {
  final session = Get.find<SessionController>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: session.routerRefresh,
    redirect: (context, state) {
      final path = state.matchedLocation;

      switch (session.stage.value) {
        case SessionStage.starting:
          // Nothing is rendered until the session check has answered.
          return path == AppRoutes.splash ? null : AppRoutes.splash;
        case SessionStage.signedOut:
          return path == AppRoutes.login ? null : AppRoutes.login;
        case SessionStage.mustChangePassword:
          // Route straight to a change-password screen and do not let them
          // past it.
          return path == AppRoutes.changePassword
              ? null
              : AppRoutes.changePassword;
        case SessionStage.ready:
          if (path == AppRoutes.splash || path == AppRoutes.login) {
            // Back to where they were when the token died, if we know.
            final returnTo = session.returnTo;
            session.returnTo = null;
            return returnTo != null && returnTo.startsWith('/officer')
                ? returnTo
                : AppRoutes.today;
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SessionBootScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const OfficerLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // --- The officer's five daily screens ------------------------------
      // See the beat, work the list, walk the round, find the unit in
      // front of him, everything else. That is his day, in order.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            OfficerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.today,
                builder: (context, state) => const BeatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.defaulters,
                builder: (context, state) => const FieldDefaultersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.round,
                builder: (context, state) => const RoundScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.find,
                builder: (context, state) => const UnitSearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),

      // --- Pushed above the shell ---------------------------------------
      GoRoute(
        path: AppRoutes.caseDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => CaseDetailScreen(
          caseId: _intParam(state, 'caseId'),
        ),
      ),
      GoRoute(
        path: AppRoutes.recordAction,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => RecordActionScreen(
          caseId: _intParam(state, 'caseId'),
          args: state.extra is CaseWriteArgs
              ? state.extra as CaseWriteArgs
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.sealCase,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SealFormScreen(
          mode: SealMode.seal,
          caseId: _intParam(state, 'caseId'),
          args: state.extra is CaseWriteArgs
              ? state.extra as CaseWriteArgs
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.releaseSeal,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SealFormScreen(
          mode: SealMode.release,
          sealId: _intParam(state, 'sealId'),
          args: state.extra is CaseWriteArgs
              ? state.extra as CaseWriteArgs
              : null,
        ),
      ),
      // One list, two readings — `?ready=1` narrows it to the seals that
      // are now settled and waiting to be opened again.
      GoRoute(
        path: AppRoutes.seals,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => FieldSealsScreen(
          readyOnly: state.uri.queryParameters['ready'] == '1',
        ),
      ),
      GoRoute(
        path: AppRoutes.cases,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => CasesScreen(
          assignedToMe: state.uri.queryParameters['assigned'] == 'me',
        ),
      ),
      GoRoute(
        path: AppRoutes.followUps,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => FollowUpsScreen(
          initialState: state.uri.queryParameters['state'],
        ),
      ),
      GoRoute(
        path: AppRoutes.activity,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ActivityScreen(),
      ),
      GoRoute(
        path: AppRoutes.map,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MapScreen(),
      ),
      // The fallback behind a beat tile the app has no designed screen
      // for. No number on that dashboard is allowed to be a dead end.
      GoRoute(
        path: AppRoutes.queueList,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => QueueListScreen(
          args: state.extra is QueueListArgs
              ? state.extra as QueueListArgs
              : const QueueListArgs(endpoint: '', title: ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.fines,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FinesScreen(),
      ),
      // The card the officer tapped travels in `extra`, so the profile
      // draws before a request has answered and the shared-element
      // transition has something to land on.
      GoRoute(
        path: AppRoutes.propertyProfile,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ShopProfileScreen(
          propertyId: _intParam(state, 'propertyId'),
          card: state.extra is FieldCard ? state.extra as FieldCard : null,
          heroPrefix: state.uri.queryParameters['from'] ?? 'defaulters',
        ),
      ),
      // Kept reachable for the prototype screens that predate the field
      // module and still push a PropertySummary.
      GoRoute(
        path: AppRoutes.unitProfile,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PropertyProfileScreen(
          propertyId: _intParam(state, 'propertyId'),
          property: state.extra is PropertySummary
              ? state.extra as PropertySummary
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.imposeFine,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => FineFormScreen(
          propertyId: _intParam(state, 'propertyId'),
          property: state.extra is PropertySummary
              ? state.extra as PropertySummary
              : null,
          target: state.extra is ActionTarget
              ? state.extra as ActionTarget
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.recordInspection,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => RecordInspectionScreen(
          propertyId: _intParam(state, 'propertyId'),
        ),
      ),
      GoRoute(
        path: AppRoutes.legal,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LegalScreen(),
      ),
      GoRoute(
        path: AppRoutes.queue,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OfflineQueueScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

int _intParam(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '') ?? 0;
