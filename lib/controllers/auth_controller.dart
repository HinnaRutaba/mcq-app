import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Drives the (magistrate-only) login screen.
class AuthController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool obscurePassword = true.obs;
  final RxBool isLoading = false.obs;

  void toggleObscurePassword() =>
      obscurePassword.value = !obscurePassword.value;

  String? validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return 'Username is required';
    if (username.length < 3) return 'Username must be at least 3 characters';
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username)) {
      return 'Use letters, numbers, dot, underscore or hyphen only';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  /// Validates and signs in. Returns `true` once the (currently simulated)
  /// authentication succeeds, `false` if the form was invalid.
  Future<bool> login() async {
    if (!(formKey.currentState?.validate() ?? false)) return false;

    isLoading.value = true;
    try {
      // TODO: replace with the real authentication call.
      await Future.delayed(const Duration(milliseconds: 900));
      return true;
    } finally {
      isLoading.value = false;
    }
  }

  void reset() {
    usernameController.clear();
    passwordController.clear();
    obscurePassword.value = true;
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
