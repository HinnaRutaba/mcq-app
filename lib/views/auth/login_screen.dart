import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _submit(BuildContext context, AuthController controller) async {
    if (controller.isLoading.value) return;

    final outcome = await controller.signIn();
    if (!context.mounted) return;

    switch (outcome) {
      case SignInOutcome.success:
        context.go(AppRoutes.magistrateHome);
      case SignInOutcome.mustChangePassword:
        context.go(AppRoutes.changePassword);
      case SignInOutcome.invalidForm:
      case SignInOutcome.failed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

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
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
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
                      'Sign in to manage collections, fines and sealed shops.',
                    ),
                    const SizedBox(height: 32),
                    Obx(() {
                      final message = controller.errorMessage.value;
                      if (message == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: AppAlert(message: message),
                      );
                    }),
                    AppTextField(
                      label: 'Username',
                      // Sign in with the username, not the email — the server
                      // will not match an email address.
                      hint: 'Enter your username',
                      controller: controller.usernameController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: controller.validateUsername,
                      autofillHints: const [AutofillHints.username],
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
                        onFieldSubmitted: (_) => _submit(context, controller),
                        autofillHints: const [AutofillHints.password],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Obx(
                      () => AppButton(
                        label: 'Sign In',
                        isLoading: controller.isLoading.value,
                        onPressed: () => _submit(context, controller),
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
