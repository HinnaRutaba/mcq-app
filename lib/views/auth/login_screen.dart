import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/widgets.dart';
import 'widgets/auth_scaffold.dart';

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

    return AuthScaffold(
      title: 'Welcome back',
      message: 'Sign in to manage collections, fines and sealed shops.',
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
    );
  }
}
