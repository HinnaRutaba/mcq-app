import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/api/locale_controller.dart';
import '../../controllers/api/session_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';

/// Sign in.
///
/// Username, not email: MCQ staff email is optional and many officers do
/// not have one. `device_name` is prefilled with the handset model and left
/// editable — it is what the officer sees when revoking a lost phone.
///
/// There is one error message for every failure, and no retry loop: the
/// server deliberately does not distinguish a wrong password from a locked
/// account, and five failures locks the account for 15 minutes.
class OfficerLoginScreen extends StatefulWidget {
  const OfficerLoginScreen({super.key});

  @override
  State<OfficerLoginScreen> createState() => _OfficerLoginScreenState();
}

class _OfficerLoginScreenState extends State<OfficerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _deviceName = TextEditingController();

  SessionController get _session => Get.find<SessionController>();

  @override
  void initState() {
    super.initState();
    _session.suggestedDeviceName().then((name) {
      if (mounted && _deviceName.text.isEmpty) _deviceName.text = name;
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _deviceName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await _session.signIn(
      username: _username.text,
      password: _password.text,
      deviceName: _deviceName.text,
    );
    // No navigation here: the router redirects on the session stage, so a
    // forced password change cannot be walked past.
  }

  @override
  Widget build(BuildContext context) {
    final locale = Get.find<LocaleController>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 32, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.account_balance_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const Spacer(),
                        // Urdu is reachable before sign-in: an officer who
                        // reads Urdu should not have to sign in in English
                        // to switch to it.
                        Obx(
                          () => SegmentedButton<AppLocale>(
                            segments: [
                              for (final option in AppLocale.values)
                                ButtonSegment(
                                  value: option,
                                  label: AppText.label(option.nativeLabel),
                                ),
                            ],
                            selected: {locale.locale.value},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) =>
                                locale.use(selection.first),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppText.headlineLarge(t('auth.title')),
                    const SizedBox(height: 8),
                    AppText.body(t('auth.subtitle')),
                    const SizedBox(height: 28),

                    AppTextField(
                      label: t('auth.username'),
                      hint: t('auth.usernameHint'),
                      controller: _username,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.person_outline_rounded,
                      autofillHints: const [AutofillHints.username],
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? t('auth.usernameRequired')
                          : null,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: t('auth.password'),
                      controller: _password,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.lock_outline_rounded,
                      autofillHints: const [AutofillHints.password],
                      validator: (value) => (value ?? '').isEmpty
                          ? t('auth.passwordRequired')
                          : null,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: t('auth.deviceName'),
                      hint: t('auth.deviceNameHint'),
                      controller: _deviceName,
                      textInputAction: TextInputAction.done,
                      prefixIcon: Icons.smartphone_outlined,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? t('auth.deviceNameRequired')
                          : null,
                    ),
                    const SizedBox(height: 6),
                    AppText.caption(t('auth.deviceNameHelp')),

                    Obx(() {
                      final error = _session.signInError.value;
                      if (error.isEmpty) return const SizedBox(height: 24);
                      return Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 20),
                        child: AppBanner(
                          tone: AppStatusTone.danger,
                          icon: Icons.error_outline_rounded,
                          message: error,
                        ),
                      );
                    }),

                    Obx(
                      () => AppButton(
                        label: t('auth.signIn'),
                        isLoading: _session.isSubmitting.value,
                        onPressed: _submit,
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
