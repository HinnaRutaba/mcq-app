import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/widgets.dart';
import '../../config/theme/app_radius.dart';

/// The password change an officer cannot skip.
///
/// Reached straight from signing in, when the server says
/// `must_change_password`. There is no way past it, because the server will
/// refuse every other call until it is done — so the only ways out are setting
/// a password or going back to sign in.
///
/// Changing the password revokes every token the officer holds. The controller
/// deals with that by signing in again on their behalf, so from the officer's
/// side this screen leads straight to the dashboard.
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  Future<void> _submit(BuildContext context, AuthController controller) async {
    if (controller.isLoading.value) return;

    final outcome = await controller.changePassword();
    if (!context.mounted) return;

    switch (outcome) {
      case PasswordChangeOutcome.success:
        context.go(AppRoutes.magistrateHome);
      case PasswordChangeOutcome.signInRequired:
        // The password did change; only the session did not survive it. The
        // controller has already put the explanation on the sign-in screen.
        context.go(AppRoutes.login);
      case PasswordChangeOutcome.invalidForm:
      case PasswordChangeOutcome.failed:
        break;
    }
  }

  void _backToSignIn(BuildContext context, AuthController controller) {
    controller.abandonPasswordChange();
    context.go(AppRoutes.login);
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
                key: controller.changePasswordFormKey,
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
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const AppText.headlineLarge('Set a new password'),
                    const SizedBox(height: 8),
                    const AppText.body(
                      'Your password must be changed before you can carry on. '
                      'Once it is set you will go straight to your dashboard.',
                    ),
                    const SizedBox(height: 24),
                    const AppAlert(
                      tone: AppTone.info,
                      icon: Icons.info_outline_rounded,
                      message:
                          'This signs you out of any other device you are '
                          'using.',
                    ),
                    const SizedBox(height: 20),
                    Obx(() {
                      final message = controller.errorMessage.value;
                      if (message == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: AppAlert(message: message),
                      );
                    }),
                    AppTextField(
                      label: 'New password',
                      hint:
                          'At least ${AuthController.minPasswordLength} characters',
                      controller: controller.newPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: controller.validateNewPassword,
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Confirm new password',
                      hint: 'Type it again',
                      controller: controller.confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: controller.validateConfirmPassword,
                      onFieldSubmitted: (_) => _submit(context, controller),
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    const SizedBox(height: 28),
                    Obx(
                      () => AppButton(
                        label: 'Set Password & Continue',
                        isLoading: controller.isLoading.value,
                        onPressed: () => _submit(context, controller),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Back to Sign In',
                      variant: AppButtonVariant.ghost,
                      onPressed: () => _backToSignIn(context, controller),
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
