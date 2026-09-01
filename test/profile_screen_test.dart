import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:mcq_app/config/routes/app_routes.dart';
import 'package:mcq_app/config/theme/app_brand.dart';
import 'package:mcq_app/config/theme/app_theme.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/controllers/theme_controller.dart';
import 'package:mcq_app/core/storage/secure_storage_service.dart';
import 'package:mcq_app/data/repositories/auth_repository.dart';
import 'package:mcq_app/views/magistrate/magistrate_profile_screen.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';

/// The officer's own page: who is signed in, how the app looks, and the way
/// out.
void main() {
  late StubbedApi api;
  late AuthController auth;
  late ThemeController theme;

  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(400, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Behind a router, because signing out navigates — and where it lands is
    // part of what the button is for.
    final router = GoRouter(
      initialLocation: AppRoutes.magistrateProfile,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.magistrateProfile,
          builder: (_, _) => const MagistrateProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Scaffold(body: Center(child: Text('SIGN IN'))),
        ),
      ],
    );

    await tester.pumpWidget(
      Obx(
        () => MaterialApp.router(
          theme: AppTheme.light(theme.colorScheme.value),
          darkTheme: AppTheme.dark(theme.colorScheme.value),
          themeMode: theme.themeMode.value,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    Get.reset();
    api = StubbedApi();
    auth = AuthController(
      authRepository: ApiAuthRepository(api: api.service, storage: api.storage),
    );
    auth.officer.value = officerFixture;
    Get.put<AuthController>(auth, permanent: true);
    Get.put<SecureStorageService>(api.storage, permanent: true);
    theme = ThemeController(storage: api.storage);
    Get.put<ThemeController>(theme, permanent: true);
  });

  tearDown(Get.reset);

  group('the officer card', () {
    testWidgets('identifies the account this handset is signed in as', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      expect(find.text('Habibullah Tareen'), findsOneWidget);
      expect(find.text('Municipal Magistrate'), findsOneWidget);
      expect(find.text('magistrate'), findsOneWidget);
      expect(find.text('magistrate@mcq.test'), findsOneWidget);
      expect(find.text('MAGISTRATE'), findsOneWidget);
    });

    testWidgets('a null field is left out rather than shown empty', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      // `employee_no` and `branch_id` come back null for this officer.
      expect(find.text('—'), findsNothing);
    });

    testWidgets('says so plainly when nobody is signed in', (
      WidgetTester tester,
    ) async {
      auth.officer.value = null;

      await pumpProfile(tester);

      expect(find.text('Not signed in.'), findsOneWidget);
    });
  });

  group('appearance', () {
    testWidgets('offers every scheme, with the default in use', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      for (final AppColorScheme scheme in AppColorScheme.values) {
        expect(find.text(scheme.label), findsOneWidget, reason: scheme.name);
      }
      expect(find.text('In use'), findsOneWidget);
      expect(theme.colorScheme.value, AppColorScheme.balochistanGreen);
    });

    testWidgets('picking one repaints the app and is remembered', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      await tester.tap(find.text('Indigo'));
      await tester.pumpAndSettle();

      expect(theme.colorScheme.value, AppColorScheme.indigo);
      expect(
        Theme.of(tester.element(find.byType(MagistrateProfileScreen)))
            .colorScheme
            .primary,
        AppColorScheme.indigo.light.primary,
        reason: 'the choice has to reach the theme, not just the controller',
      );
      expect(await api.storage.readColorScheme(), 'indigo');
    });

    testWidgets('light and dark are chosen and remembered too', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(theme.themeMode.value, ThemeMode.dark);
      expect(await api.storage.readThemeMode(), 'dark');
    });

    testWidgets('what was chosen last time comes back', (
      WidgetTester tester,
    ) async {
      await api.storage.saveColorScheme('teal');
      await api.storage.saveThemeMode('dark');

      // A fresh controller, the way a relaunch builds one.
      final restored = ThemeController(storage: api.storage);
      Get.delete<ThemeController>(force: true);
      Get.put<ThemeController>(restored, permanent: true);
      theme = restored;

      await pumpProfile(tester);

      expect(restored.colorScheme.value, AppColorScheme.teal);
      expect(restored.themeMode.value, ThemeMode.dark);
    });

    testWidgets('a scheme that no longer exists falls back to the default', (
      WidgetTester tester,
    ) async {
      await api.storage.saveColorScheme('sunset-orange');

      final restored = ThemeController(storage: api.storage);
      Get.delete<ThemeController>(force: true);
      Get.put<ThemeController>(restored, permanent: true);
      theme = restored;

      await pumpProfile(tester);

      expect(restored.colorScheme.value, AppColorScheme.balochistanGreen);
    });
  });

  group('logging out', () {
    testWidgets('asks first, and staying signed in keeps the session', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsOneWidget);

      await tester.tap(find.text('Stay signed in'));
      await tester.pumpAndSettle();

      expect(auth.isSignedIn, isTrue);
      expect(api.stub.lastOptions, isNull, reason: 'nothing was revoked');
    });

    testWidgets('confirming revokes this handset', (WidgetTester tester) async {
      await api.storage.saveSession(token: 'live-token');
      api.stub.reply(<String, dynamic>{'message': 'Signed out.'});

      await pumpProfile(tester);

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      // The dialog's button, not the page's.
      await tester.tap(find.widgetWithText(TextButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(api.stub.lastOptions!.path, '/api/v1/auth/device/logout');
      expect(auth.isSignedIn, isFalse);
      expect(await api.storage.readToken(), isNull);
      expect(find.text('SIGN IN'), findsOneWidget);
    });

    testWidgets('the colour scheme survives signing out', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);
      await tester.tap(find.text('Teal'));
      await tester.pumpAndSettle();

      await api.storage.clearAll();

      expect(
        await api.storage.readColorScheme(),
        'teal',
        reason: 'signing out is no reason to throw away an eyesight choice',
      );
    });
  });
}
