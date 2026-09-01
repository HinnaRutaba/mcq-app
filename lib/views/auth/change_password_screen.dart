import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/theme/app_colors.dart';
import '../../controllers/api/session_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/app_feedback.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/widgets.dart';
import '../magistrate/api/widgets/server_field_error.dart';

/// Forced password change — the first screen an officer ever sees.
///
/// `must_change_password: true` on the session sends him straight here and
/// he is not let past it, so it had better explain itself: last time this
/// was a raw form, in Urdu, with no sentence saying why it had appeared.
///
/// **A successful change revokes every token this officer holds** —
/// deliberately, because a credential issued before a possible compromise
/// must stop working. So the app clears the keychain and sends him back to
/// login, and that is designed as a pleasant, expected moment rather than
/// left to look like the app breaking: *"Password changed. Please sign in
/// again."*
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final RxMap<String, List<String>> _errors = <String, List<String>>{}.obs;

  SessionController get _session => Get.find<SessionController>();

  @override
  void initState() {
    super.initState();
    // The strength meter is drawn from what he has typed so far.
    _next.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _errors.clear();
    try {
      final message = await _session.changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
        confirmation: _confirm.text,
      );
      AppHaptics.success();
      if (!mounted) return;
      // A dialog, not a toast. He is about to be signed out and he needs
      // to understand that it was meant to happen.
      await AppFeedback.serverRefusal(
        message ?? t('password.changed'),
        title: t('password.changedTitle'),
      );
    } on ApiException catch (error) {
      AppHaptics.refused();
      if (error.isValidation) {
        _errors.assignAll(error.errors);
      } else if (!error.isForbidden) {
        AppFeedback.toast(error.message, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppBanner(
                        tone: AppStatusTone.warning,
                        icon: Icons.lock_reset_rounded,
                        title: t('password.forcedTitle'),
                        message: t('password.forced'),
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        label: t('password.current'),
                        controller: _current,
                        obscureText: true,
                        validator: (value) => (value ?? '').isEmpty
                            ? t('auth.passwordRequired')
                            : null,
                      ),
                      // The server's own message for this field, verbatim.
                      ServerFieldError(
                        errors: _errors,
                        field: 'current_password',
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: t('password.new'),
                        controller: _next,
                        obscureText: true,
                        validator: (value) => (value ?? '').length < 8
                            ? t('password.tooShort')
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _Strength(password: _next.text),
                      ServerFieldError(errors: _errors, field: 'password'),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: t('password.confirm'),
                        controller: _confirm,
                        obscureText: true,
                        validator: (value) =>
                            value != _next.text ? t('password.mismatch') : null,
                      ),
                      const SizedBox(height: 20),
                      // Said before it happens, not after. An officer who
                      // is signed out without warning assumes the app is
                      // broken and stops trusting it.
                      AppBanner(
                        tone: AppStatusTone.info,
                        icon: Icons.devices_rounded,
                        message: t('password.revokesEverything'),
                      ),
                      const SizedBox(height: 28),
                      Obx(
                        () => AppButton(
                          label: t('settings.changePassword'),
                          icon: Icons.check_rounded,
                          isLoading: _session.isSubmitting.value,
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A green band with the corporation's name on it, so the first screen an
/// officer sees looks like something MCQ built rather than a raw form.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsetsDirectional.fromSTEB(
          24,
          MediaQuery.paddingOf(context).top + 28,
          24,
          28,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: dark
                ? const [Color(0xFF11301F), AppColors.darkBackground]
                : const [AppColors.primaryLight, AppColors.primaryDark],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            AppText.headlineMedium(t('password.title'), color: Colors.white),
            const SizedBox(height: 6),
            AppText.body(
              t('app.corporation'),
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ],
        ),
      ),
    );
  }
}

/// How strong the new password is, in words as well as colour.
///
/// Deliberately advisory: the server holds the real rule and its refusal is
/// shown verbatim under the field. This is here so an officer is not
/// guessing at a policy nobody has told him.
class _Strength extends StatelessWidget {
  const _Strength({required this.password});

  final String password;

  ({double value, AppTone tone, String key}) get _rating {
    if (password.isEmpty) {
      return (value: 0, tone: AppTone.neutral, key: 'password.strengthNone');
    }
    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

    if (score <= 2) {
      return (value: 0.33, tone: AppTone.danger, key: 'password.strengthWeak');
    }
    if (score == 3) {
      return (value: 0.66, tone: AppTone.warning, key: 'password.strengthFair');
    }
    return (value: 1, tone: AppTone.success, key: 'password.strengthStrong');
  }

  @override
  Widget build(BuildContext context) {
    final rating = _rating;
    final colour = rating.tone.on(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: rating.value),
            duration: const Duration(milliseconds: 240),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation(colour),
            ),
          ),
        ),
        const SizedBox(height: 6),
        AppText.bodySmall(t(rating.key), color: colour),
      ],
    );
  }
}
