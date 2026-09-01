import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/app/dependency_injection.dart';
import 'package:mcq_app/config/theme/app_theme.dart';
import 'package:mcq_app/controllers/auth_controller.dart';
import 'package:mcq_app/config/theme/app_brand.dart';
import 'package:mcq_app/controllers/dashboard_controller.dart';
import 'package:mcq_app/controllers/theme_controller.dart';
import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/dashboard_repository.dart';
import 'package:mcq_app/data/repositories/defaulters_repository.dart';
import 'package:mcq_app/views/auth/change_password_screen.dart';
import 'package:mcq_app/views/auth/login_screen.dart';
import 'package:mcq_app/views/magistrate/collection_detail_screen.dart';
import 'package:mcq_app/views/magistrate/collections_screen.dart';
import 'package:mcq_app/views/magistrate/create_chalaan_screen.dart';
import 'package:mcq_app/views/magistrate/magistrate_home_screen.dart';
import 'package:mcq_app/views/magistrate/magistrate_profile_screen.dart';
import 'package:mcq_app/views/magistrate/sealed_screen.dart';

import 'support/api_stub.dart';
import 'support/dashboard_fixtures.dart';

/// Renders every screen to a PNG under `test/preview/` so a change can be
/// looked at, not merely analysed. Run it deliberately:
///
///     flutter test test/design_preview.dart --update-goldens
///
/// The filename has no `_test` suffix on purpose: `flutter test` collects only
/// `*_test.dart`, so these stay out of the ordinary suite. They are previews to
/// review, not assertions — a deliberate redesign should never surface as a
/// failing build.
void main() {
  setUpAll(() async {
    Get.reset();
    installInMemoryKeychain();
    setupDependencies();
    await _loadRealFonts();
  });

  tearDownAll(Get.reset);

  // Builders rather than widgets, so an entry can set up the state it means to
  // show — the sign-in screen is worth seeing with a failure on it, since that
  // is the state an officer meets at a counter when the password is wrong.
  final screens = <String, Widget Function()>{
    'login': () {
      Get.find<AuthController>().errorMessage.value = null;
      return const LoginScreen();
    },
    'login_error': () {
      Get.find<AuthController>().errorMessage.value =
          'These credentials do not match our records.';
      return const LoginScreen();
    },
    'change_password': () {
      Get.find<AuthController>().errorMessage.value = null;
      return const ChangePasswordScreen();
    },
    'home': () {
      _seedDashboard();
      return const MagistrateHomeScreen();
    },
    // The header once it has collapsed: the name pinned on a plain bar, with
    // the designation and the beat strip gone.
    'home_collapsed': () {
      _seedDashboard();
      return const MagistrateHomeScreen();
    },
    // The state a bazaar with no signal produces, which the happy path never
    // shows and which is where a dashboard usually falls apart.
    'home_offline': () {
      _seedDashboard(
        failure: const ApiException(
          message: 'No connection. Check your signal and try again.',
          failure: ApiFailure.network,
        ),
      );
      return const MagistrateHomeScreen();
    },
    'collections': () => const CollectionsScreen(),
    'sealed': () => const SealedScreen(),
    'profile': () {
      Get.find<AuthController>().officer.value = officerFixture;
      Get.find<ThemeController>().setColorScheme(
        AppColorScheme.balochistanGreen,
      );
      return const MagistrateProfileScreen();
    },
    // Proof the choice reaches the whole interface and not just the picker:
    // the header, the chips, the tick and the button all follow.
    'profile_indigo': () {
      Get.find<AuthController>().officer.value = officerFixture;
      Get.find<ThemeController>().setColorScheme(AppColorScheme.indigo);
      return const MagistrateProfileScreen();
    },
    'detail': () => const CollectionDetailScreen(recordId: '77'),
    'fine': () => const CreateChalaanScreen(),
  };

  // A dashboard is taller than a form. Rendering it at the default height
  // would crop the half worth reviewing — the activity figures — out of the
  // picture, which is how a layout problem goes unseen.
  const tall = <String, double>{
    'home': 7000,
    'home_collapsed': 1400,
    'home_offline': 2100,
    'profile': 3900,
    'profile_indigo': 3900,
  };

  /// Entries to drag before capturing, and by how much.
  const scrolled = <String, double>{'home_collapsed': 420};

  for (final entry in screens.entries) {
    for (final mode in <String>['light', 'dark']) {
      testWidgets('${entry.key} ($mode)', (WidgetTester tester) async {
        tester.view
          ..physicalSize = Size(1080, tall[entry.key] ?? 2100)
          ..devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        // Built before the theme, because an entry may choose a colour scheme
        // and the whole point of that entry is that the theme follows it.
        final screen = entry.value();
        final scheme = Get.find<ThemeController>().colorScheme.value;

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _withRealFont(
              mode == 'dark' ? AppTheme.dark(scheme) : AppTheme.light(scheme),
            ),
            home: screen,
          ),
        );
        await tester.pumpAndSettle();

        // A screen that wants to be seen mid-scroll says so, and the preview
        // drags it there — a collapsing header is a state, not a still.
        final scrollBy = scrolled[entry.key];
        if (scrollBy != null) {
          await tester.drag(
            find.byType(CustomScrollView),
            Offset(0, -scrollBy),
          );
          await tester.pumpAndSettle();
        }

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('preview/${entry.key}_$mode.png'),
        );
      });
    }
  }
}

/// Puts a signed-in officer and a dashboard over the fixtures in place of the
/// real ones, so home renders the payload the staging server actually returns
/// instead of reaching for the network.
void _seedDashboard({Object? failure}) {
  Get.find<AuthController>().officer.value = officerFixture;

  // Swap the repository, not the controller. `Get.put` is put-*if-absent*, so
  // putting a controller over the `lazyPut` registration made by
  // `setupDependencies` is silently a no-op and the screen rebuilds the real
  // one. Deleting the repository does remove it — it is not `fenix` — and the
  // controller, which is, drops its instance and keeps its factory, so the
  // screen's `Get.find` builds a fresh one over whatever is registered now.
  Get.delete<DashboardRepository>(force: true);
  Get.put<DashboardRepository>(
    FakeDashboardRepository(failure: failure),
    permanent: true,
  );
  Get.delete<DefaultersRepository>(force: true);
  Get.put<DefaultersRepository>(
    FakeDefaultersRepository(failure: failure),
    permanent: true,
  );
  Get.delete<DashboardController>(force: true);
}

/// The app's theme asks `google_fonts` for Inter, which cannot be fetched in a
/// test — so every label falls back to the placeholder font and renders as a
/// black box. Repointing the theme at the Roboto loaded by [_loadRealFonts]
/// makes the preview legible. Sizes, weights and spacing are untouched, so what
/// is being reviewed is still the real layout.
ThemeData _withRealFont(ThemeData theme) => theme.copyWith(
  textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
  primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
  // `apply` does not reach the styles hanging off component themes, and each
  // one that is missed shows up as a row of black rectangles — form hints and
  // validation messages especially, which is most of what there is to review on
  // a screen like the fine form.
  appBarTheme: theme.appBarTheme.copyWith(
    titleTextStyle: _real(theme.appBarTheme.titleTextStyle),
  ),
  inputDecorationTheme: theme.inputDecorationTheme.copyWith(
    hintStyle: _real(theme.inputDecorationTheme.hintStyle),
    labelStyle: _real(theme.inputDecorationTheme.labelStyle),
    floatingLabelStyle: _real(theme.inputDecorationTheme.floatingLabelStyle),
    errorStyle: _real(theme.inputDecorationTheme.errorStyle),
    helperStyle: _real(theme.inputDecorationTheme.helperStyle),
    prefixStyle: _real(theme.inputDecorationTheme.prefixStyle),
    suffixStyle: _real(theme.inputDecorationTheme.suffixStyle),
    counterStyle: _real(theme.inputDecorationTheme.counterStyle),
  ),
);

TextStyle? _real(TextStyle? style) => style?.copyWith(fontFamily: 'Roboto');

/// Loads a real font out of the Flutter SDK, plus the Material icon font.
///
/// Asserts the directory is there rather than skipping quietly: a missing font
/// does not fail the render, it just draws every label as a black rectangle,
/// and a preview nobody can read is worse than no preview.
Future<void> _loadRealFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  expect(
    flutterRoot,
    isNotNull,
    reason: 'FLUTTER_ROOT is set by `flutter test`; run the previews with it',
  );

  final fontsDir = Directory('$flutterRoot/bin/cache/artifacts/material_fonts');
  expect(
    fontsDir.existsSync(),
    isTrue,
    reason: 'no font at ${fontsDir.path} — the preview would be unreadable',
  );

  final fonts = <String, List<String>>{
    'Roboto': <String>['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'],
    'MaterialIcons': <String>['MaterialIcons-Regular.otf'],
  };

  for (final family in fonts.entries) {
    final loader = FontLoader(family.key);
    for (final name in family.value) {
      final file = File('${fontsDir.path}/$name');
      expect(file.existsSync(), isTrue, reason: 'missing font ${file.path}');
      loader.addFont(
        file.readAsBytes().then(
          (List<int> bytes) => ByteData.sublistView(Uint8List.fromList(bytes)),
        ),
      );
    }
    await loader.load();
  }
}
