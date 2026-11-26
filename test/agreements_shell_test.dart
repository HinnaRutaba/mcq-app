import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/views/agreements/agreements_shell.dart';

/// Android's back button on a CMO/Admin tab: Home first, then out of the app.
void main() {
  const List<String> labels = <String>['Home', 'Cases', 'More'];
  const List<String> paths = <String>[
    AppRoutes.agreementsHome,
    AppRoutes.agreementsCases,
    AppRoutes.agreementsMore,
  ];

  Future<GoRouter> pumpShell(WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: paths.first,
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder: (_, _, StatefulNavigationShell shell) =>
              AgreementsShell(navigationShell: shell),
          branches: <StatefulShellBranch>[
            for (final String path in paths)
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: path,
                    builder: (_, _) =>
                        Scaffold(body: Center(child: Text('page $path'))),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('back on Cases or More lands on Home, then leaves', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpShell(tester);

    for (int i = 1; i < labels.length; i++) {
      await tester.tap(find.text(labels[i]));
      await tester.pumpAndSettle();
      expect(await router.routerDelegate.popRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('page ${paths.first}'), findsOneWidget);
    }
    expect(await router.routerDelegate.popRoute(), isFalse);
  });

  // Android 16 predictive back only hands Flutter the press if it said it wants it.
  testWidgets('Android is told the app takes the back press off Home', (
    WidgetTester tester,
  ) async {
    final List<bool> handlesBack = <bool>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          handlesBack.add(call.arguments as bool);
        }
        return null;
      },
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpShell(tester);

    for (int i = 1; i < labels.length; i++) {
      await tester.tap(find.text(labels[i]));
      await tester.pumpAndSettle();
      expect(handlesBack.last, isTrue, reason: 'on ${labels[i]}');
    }
    await tester.tap(find.text(labels.first));
    await tester.pumpAndSettle();
    expect(handlesBack.last, isFalse);
  });
}
