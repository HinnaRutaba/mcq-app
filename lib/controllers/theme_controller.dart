import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Holds the app's current [ThemeMode] so any screen can offer a
/// light/dark/system toggle (see the Profile screens) and have it apply
/// instantly app-wide.
class ThemeController extends GetxController {
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  void setThemeMode(ThemeMode mode) => themeMode.value = mode;
}
