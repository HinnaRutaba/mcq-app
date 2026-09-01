import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/storage/key_value_store.dart';

/// How the app looks: light or dark, and how large the words are.
///
/// **Dark mode is not decoration here.** Field officers work bazaars after
/// dark, and every status colour has a lifted dark variant in `AppColors`
/// so a red pill stays legible against near-black.
///
/// **Large text is not decoration either.** The scale already starts at 15
/// rather than 12, because this is read at arm's length in sunlight by an
/// officer who may be over fifty — but some officers need more than that
/// and have never been shown the operating system's accessibility
/// settings. This is that setting, in the app, next to the language.
class ThemeController extends GetxController {
  ThemeController([this._store]);

  final KeyValueStore? _store;

  static const String _modeKey = 'mcq.theme_mode';
  static const String _textScaleKey = 'mcq.text_scale';

  /// The three sizes on offer. Anything finer than this is a slider an
  /// officer fiddles with instead of working.
  static const List<double> textScales = [1.0, 1.15, 1.3];

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  /// Applied on top of whatever the operating system already does, in
  /// [LocalisedTextTheme].
  final RxDouble textScale = 1.0.obs;

  @override
  void onInit() {
    super.onInit();
    final store = _store;
    if (store == null) return;
    final mode = store.getString(_modeKey);
    if (mode != null) {
      themeMode.value = ThemeMode.values.firstWhere(
        (value) => value.name == mode,
        orElse: () => ThemeMode.system,
      );
    }
    final scale = double.tryParse(store.getString(_textScaleKey) ?? '');
    if (scale != null && textScales.contains(scale)) textScale.value = scale;
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    _store?.setString(_modeKey, mode.name);
  }

  void setTextScale(double scale) {
    textScale.value = scale;
    _store?.setString(_textScaleKey, '$scale');
  }
}
