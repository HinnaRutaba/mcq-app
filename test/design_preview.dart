import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mcq_app/app/dependency_injection.dart';
import 'package:mcq_app/config/theme/app_theme.dart';
import 'package:mcq_app/views/magistrate/collection_detail_screen.dart';
import 'package:mcq_app/views/magistrate/collections_screen.dart';
import 'package:mcq_app/views/magistrate/create_chalaan_screen.dart';
import 'package:mcq_app/views/magistrate/magistrate_home_screen.dart';
import 'package:mcq_app/views/magistrate/magistrate_profile_screen.dart';
import 'package:mcq_app/views/magistrate/sealed_screen.dart';

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
    setupDependencies();
    await _loadRealFonts();
  });

  tearDownAll(Get.reset);

  final screens = <String, Widget>{
    'home': const MagistrateHomeScreen(),
    'collections': const CollectionsScreen(),
    'sealed': const SealedScreen(),
    'profile': const MagistrateProfileScreen(),
    'detail': const CollectionDetailScreen(recordId: '77'),
    'fine': const CreateChalaanScreen(),
  };

  for (final entry in screens.entries) {
    for (final brightness in <String, ThemeData>{
      'light': _withRealFont(AppTheme.light),
      'dark': _withRealFont(AppTheme.dark),
    }.entries) {
      testWidgets('${entry.key} (${brightness.key})', (
        WidgetTester tester,
      ) async {
        tester.view
          ..physicalSize = const Size(1080, 2100)
          ..devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: brightness.value,
            home: entry.value,
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('preview/${entry.key}_${brightness.key}.png'),
        );
      });
    }
  }
}

/// The app's theme asks `google_fonts` for Inter, which cannot be fetched in a
/// test — so every label falls back to the placeholder font and renders as a
/// black box. Repointing the theme at the Roboto loaded by [_loadRealFonts]
/// makes the preview legible. Sizes, weights and spacing are untouched, so what
/// is being reviewed is still the real layout.
ThemeData _withRealFont(ThemeData theme) => theme.copyWith(
  textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
  primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
  // `apply` does not reach the styles hanging off component themes.
  appBarTheme: theme.appBarTheme.copyWith(
    titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
      fontFamily: 'Roboto',
    ),
  ),
);

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
