import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/theme/app_brand.dart';
import '../core/storage/secure_storage_service.dart';

/// How the app looks on this handset: the officer's colour scheme and whether
/// it follows the device's light/dark setting.
///
/// Both are personal to the handset and go nowhere near the server — an
/// officer choosing Graphite is not a fact the corporation needs.
///
/// They are kept in the same store as everything else the handset remembers.
/// It is the keychain, which is more than a display preference needs, but the
/// app has exactly one persistence mechanism and adding a second native plugin
/// for a colour choice would be out of proportion. Reads there already fail
/// soft, so a handset that cannot answer simply starts on the default.
class ThemeController extends GetxController {
  ThemeController({SecureStorageService? storage})
    : _storage = storage ?? Get.find<SecureStorageService>();

  final SecureStorageService _storage;

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  final Rx<AppColorScheme> colorScheme = AppColorScheme.balochistanGreen.obs;

  @override
  void onInit() {
    super.onInit();
    _restore();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    _storage.saveThemeMode(mode.name);
  }

  void setColorScheme(AppColorScheme scheme) {
    colorScheme.value = scheme;
    _storage.saveColorScheme(scheme.name);
  }

  /// Reads back what was chosen last time. Anything unrecognised — a scheme
  /// dropped in a later build — falls back to the default rather than
  /// stranding the officer on a colour that no longer exists.
  Future<void> _restore() async {
    colorScheme.value = AppColorScheme.fromName(
      await _storage.readColorScheme(),
    );
    themeMode.value = _modeFromName(await _storage.readThemeMode());
  }

  static ThemeMode _modeFromName(String? name) => switch (name) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
