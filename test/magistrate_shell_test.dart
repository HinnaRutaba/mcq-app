import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:mcq_app/app/dependency_injection.dart';
import 'package:mcq_app/config/routes/app_router.dart';
import 'package:mcq_app/controllers/defaulters_controller.dart';
import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/views/magistrate/defaulters/defaulters_screen.dart';
import 'package:mcq_app/views/magistrate/magistrate_shell.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/create_fine_button.dart';
import 'package:mcq_app/widgets/widgets.dart';
import 'package:mcq_app/views/magistrate/more/more_screen.dart';
import 'package:mcq_app/views/magistrate/round/round_screen.dart';
import 'package:mcq_app/views/magistrate/shared/widgets/back_to_home_button.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';

/// Whether the four labels physically fit is a question about real font
/// metrics, so it is answered by the `nav_bar` entry in `design_preview.dart`
/// and not here — a widget test draws every glyph as a square of the font
/// size and would call a bar clipped that is nowhere near it.
///
/// The bottom bar and the router's branch list are indexed by the same
/// integer, and nothing in the type system says so. These tests are what says
/// so: reorder one without the other and an officer tapping "Round" arrives
/// at More.
void main() {
  /// The bar's four destinations, in the order they are drawn. The create
  /// button sits between the second and third and is not one of them.
  const List<String> barLabels = <String>[
    'Home',
    'Defaulters',
    'Round',
    'More',
  ];

  /// The branch each of those tabs must land on, in the same order.
  const List<String> branchPaths = <String>[
    AppRoutes.magistrateHome,
    AppRoutes.magistrateDefaulters,
    AppRoutes.magistrateRound,
    AppRoutes.magistrateMore,
  ];

  /// The shell over four stand-in pages. The real screens each want their own
  /// controllers and repositories; what is under test here is the bar and the
  /// branch it selects, so a page that only names itself is enough.
  GoRouter buildRouter() => GoRouter(
    initialLocation: branchPaths.first,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell shell,
            ) => MagistrateShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          for (final String path in branchPaths)
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: path,
                  builder: (BuildContext context, GoRouterState state) =>
                      Scaffold(body: Center(child: Text('page $path'))),
                ),
              ],
            ),
        ],
      ),
    ],
  );

  /// Returns the router it pumped, so a test can call `popRoute` on it — that
  /// is the method Android's back button arrives through.
  Future<GoRouter> pumpShell(WidgetTester tester) async {
    // Narrow enough to be a real handset: five labels have to fit on the bar
    // of the smallest phone an officer is issued, not just on a tablet.
    tester.view
      ..physicalSize = const Size(360, 720)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final GoRouter router = buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('the bar carries the four destinations, and the create button', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    for (final String label in barLabels) {
      expect(find.text(label), findsOneWidget, reason: '$label is missing');
    }

    expect(find.byType(CreateFineButton), findsOneWidget);
    expect(find.text('Fine'), findsOneWidget, reason: 'the button is labelled');

    // It sits in the gap the bar leaves, so it must not cover a destination.
    final Rect button = tester.getRect(find.byType(CreateFineButton));
    for (final String label in barLabels) {
      expect(
        button.overlaps(tester.getRect(find.text(label))),
        isFalse,
        reason: 'the create button covers $label',
      );
    }

    // And the gap is really a gap: the two sides split evenly around it.
    final double centre = tester
        .getRect(find.byType(AppBottomNavBar))
        .center
        .dx;
    expect(
      button.center.dx,
      closeTo(centre, 0.5),
      reason: 'the create button should sit on the bar\'s midline',
    );
  });

  testWidgets('the labels are drawn in bar order', (WidgetTester tester) async {
    await pumpShell(tester);

    final List<double> xs = <double>[
      for (final String label in barLabels)
        tester.getCenter(find.text(label)).dx,
    ];
    for (int i = 1; i < xs.length; i++) {
      expect(
        xs[i],
        greaterThan(xs[i - 1]),
        reason: '${barLabels[i]} should sit after ${barLabels[i - 1]}',
      );
    }
  });

  testWidgets('each tab selects the branch that sits at its index', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    for (int i = 0; i < barLabels.length; i++) {
      await tester.tap(find.text(barLabels[i]));
      await tester.pumpAndSettle();

      expect(
        find.text('page ${branchPaths[i]}'),
        findsOneWidget,
        reason: '${barLabels[i]} should show ${branchPaths[i]}',
      );
    }
  });

  test('the real router declares those branches, in that order', () {
    final StatefulShellRoute shell = appRouter.configuration.routes
        .whereType<StatefulShellRoute>()
        .single;

    expect(
      shell.branches.map(
        (StatefulShellBranch b) => (b.routes.single as GoRoute).path,
      ),
      branchPaths,
      reason:
          'the router branches and MagistrateShell.entries are indexed by '
          'the same integer and must stay in step',
    );
    expect(MagistrateShell.entries.map((entry) => entry.label), barLabels);
  });

  test('Home is the branch the back arrow and the back button aim at', () {
    // `BackToHomeButton.homeBranch` is a bare integer shared by the arrow in
    // every header and the shell's `PopScope`. Move Home along the bar without
    // moving it and both send the officer to Defaulters instead.
    expect(branchPaths[BackToHomeButton.homeBranch], AppRoutes.magistrateHome);
    expect(barLabels[BackToHomeButton.homeBranch], 'Home');
  });

  testWidgets('the back button returns to Home from every other tab', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpShell(tester);

    for (int i = 1; i < barLabels.length; i++) {
      await tester.tap(find.text(barLabels[i]));
      await tester.pumpAndSettle();
      expect(find.text('page ${branchPaths[i]}'), findsOneWidget);

      // What the Android back press actually calls.
      final bool handled = await router.routerDelegate.popRoute();
      await tester.pumpAndSettle();

      expect(
        handled,
        isTrue,
        reason:
            'back on ${barLabels[i]} must not fall through and close the '
            'app on an officer mid-round',
      );
      expect(
        find.text('page ${branchPaths.first}'),
        findsOneWidget,
        reason: 'back on ${barLabels[i]} should land on Home',
      );
    }
  });

  testWidgets('the back button still leaves the app from Home', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpShell(tester);
    expect(find.text('page ${branchPaths.first}'), findsOneWidget);

    // Home is the one tab that lets the press out. Swallowing it here would
    // leave a handset the officer cannot back out of at all.
    expect(await router.routerDelegate.popRoute(), isFalse);
  });

  testWidgets('every tab but Home carries an arrow back to Home', (
    WidgetTester tester,
  ) async {
    // Pumped one at a time rather than through the router: reaching them via
    // the shell would build Home's branch and put the dashboard's fetch on
    // the wire. Defaulters wants a controller, which it gets over the
    // fixtures — the arrow is what is under test, not the list.
    Get.put<DefaultersController>(
      DefaultersController(
        defaultersRepository: FakeDefaultersRepository(),
        dashboardRepository: FakeDashboardRepository(),
      ),
    );
    addTearDown(Get.reset);

    for (final Widget screen in <Widget>[
      const DefaultersScreen(),
      const RoundScreen(),
      const MoreScreen(),
    ]) {
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pumpAndSettle();

      expect(
        find.byType(BackToHomeButton),
        findsOneWidget,
        reason: '${screen.runtimeType} has no way back to Home but the bar',
      );
    }
  });

  group('inside the More branch', () {
    setUp(() {
      Get.reset();
      installInMemoryKeychain();
      setupDependencies();
    });

    tearDown(Get.reset);

    /// The real router, opened straight onto More. `indexedStack` only builds
    /// the branch it is showing, so this never constructs Home and never puts
    /// the dashboard's fetch on the wire.
    Future<void> pumpMore(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(400, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      appRouter.go(AppRoutes.magistrateMore);
      await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
      await tester.pumpAndSettle();
    }

    testWidgets('Sealed shops opens with the bar still under it', (
      WidgetTester tester,
    ) async {
      await pumpMore(tester);
      await tester.tap(find.text('Sealed shops'));
      await tester.pumpAndSettle();

      expect(find.text('Sealed Shops'), findsOneWidget);
      // The point of nesting these under the branch rather than pushing them
      // over the shell: the officer can still leave for their round.
      expect(find.text('Round'), findsOneWidget);
    });

    testWidgets('Profile opens with the bar still under it', (
      WidgetTester tester,
    ) async {
      await pumpMore(tester);
      await tester.tap(find.text('Profile and appearance'));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Round'), findsOneWidget);
    });
  });
}
