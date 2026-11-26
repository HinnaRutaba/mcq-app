import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/agreement_cases_controller.dart';
import '../../controllers/agreement_dashboard_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/mobile_access.dart';
import '../../widgets/widgets.dart';

/// The CMO's and the Administrator's frame: Home, Cases, More. No create
/// button — nothing is prepared on the phone; that is Estate's, on the web.
class AgreementsShell extends StatefulWidget {
  const AgreementsShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const int homeBranch = 0;
  static const int casesBranch = 1;

  static const List<AppBottomNavEntry> entries = <AppBottomNavEntry>[
    AppBottomNavEntry(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    AppBottomNavEntry(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      label: 'Cases',
    ),
    AppBottomNavEntry(
      icon: Icons.more_horiz_outlined,
      activeIcon: Icons.more_horiz_rounded,
      label: 'More',
    ),
  ];

  /// Back to Home, keeping the other tabs where they were.
  static void goHome(BuildContext context) =>
      StatefulNavigationShell.maybeOf(context)?.goBranch(homeBranch);

  @override
  State<AgreementsShell> createState() => _AgreementsShellState();
}

class _AgreementsShellState extends State<AgreementsShell> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// No push notifications: the session and the dashboard are re-read when
  /// the officer comes back to the app.
  Future<void> _onResume() async {
    final AuthController auth = Get.find<AuthController>();
    await auth.refreshAccess();
    if (!mounted || !auth.isSignedIn) return;
    final MobileAccess? access = auth.access.value;
    if (access != null && !access.has(MobileWorkspace.agreements)) {
      context.go(AppRoutes.homeFor(access));
      return;
    }
    unawaited(AgreementDashboardController.reloadIfOpened());
  }

  void _goBranch(int index) {
    if (index == AgreementsShell.casesBranch) {
      unawaited(AgreementCasesController.showAllIfOpened());
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool onHome =
        widget.navigationShell.currentIndex == AgreementsShell.homeBranch;

    return PopScope(
      canPop: onHome,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _goBranch(AgreementsShell.homeBranch);
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: AppBottomNavBar(
          entries: AgreementsShell.entries,
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _goBranch,
        ),
      ),
    );
  }
}
