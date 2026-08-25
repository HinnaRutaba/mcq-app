import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/user_role.dart';

class AuthController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final Rx<UserRole> role = UserRole.tenant.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool isLoading = false.obs;

  bool get isMagistrate => role.value == UserRole.magistrate;

  void setIsMagistrate(bool? checked) {
    role.value = (checked ?? false) ? UserRole.magistrate : UserRole.tenant;
  }

  void toggleObscurePassword() =>
      obscurePassword.value = !obscurePassword.value;

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<UserRole?> login() async {
    if (!(formKey.currentState?.validate() ?? false)) return null;

    isLoading.value = true;
    try {
      // TODO: replace with the real authentication call.
      await Future.delayed(const Duration(milliseconds: 900));
      return role.value;
    } finally {
      isLoading.value = false;
    }
  }

  void reset() {
    emailController.clear();
    passwordController.clear();
    role.value = UserRole.tenant;
    obscurePassword.value = true;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
