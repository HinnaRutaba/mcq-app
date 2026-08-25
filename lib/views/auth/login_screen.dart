import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_role.dart';
import '../../widgets/widgets.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleLogin(BuildContext context, AuthController controller) async {
    final role = await controller.login();
    if (role == null || !context.mounted) return;
    context.go(
      role == UserRole.magistrate ? AppRoutes.magistrateDashboard : AppRoutes.tenantDashboard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthController());

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const AppText.headlineLarge('Welcome back'),
                    const SizedBox(height: 8),
                    const AppText.body(
                      'Sign in to manage your properties and payments.',
                    ),
                    const SizedBox(height: 32),
                    AppTextField(
                      label: 'Email',
                      hint: 'you@example.com',
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.mail_outline_rounded,
                      validator: controller.validateEmail,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 20),
                    Obx(
                      () => AppTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: controller.passwordController,
                        obscureText: controller.obscurePassword.value,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: controller.validatePassword,
                        onFieldSubmitted: (_) => _handleLogin(context, controller),
                        autofillHints: const [AutofillHints.password],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => AppCheckbox(
                        value: controller.isMagistrate,
                        onChanged: controller.setIsMagistrate,
                        label: 'Sign in as Magistrate',
                      ),
                    ),
                    const SizedBox(height: 28),
                    Obx(
                      () => AppButton(
                        label: 'Sign In',
                        isLoading: controller.isLoading.value,
                        onPressed: () => _handleLogin(context, controller),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
