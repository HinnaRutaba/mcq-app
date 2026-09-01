import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../controllers/api/locale_controller.dart';
import '../../../controllers/api/session_controller.dart';
import '../../../controllers/api/settings_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/get_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/widgets.dart';
import 'widgets/detail_row.dart';

/// The officer's own details, the language, and signing out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(SettingsController.resolve);
    final session = Get.find<SessionController>();
    final locale = Get.find<LocaleController>();
    final theme = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(t('settings.title'))),
      body: Obx(() {
        final officer = session.user.value;

        return ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 40),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge_outlined,
                          size: 19,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 9),
                      Expanded(child: AppText.titleMedium(t('settings.officer'))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DetailRow(
                    label: t('auth.username'),
                    value: officer?.username,
                  ),
                  DetailRow(
                    label: t('settings.employeeNo'),
                    value: officer?.employeeNo,
                  ),
                  DetailRow(
                    label: t('settings.designation'),
                    value: officer?.designation,
                  ),
                  DetailRow(
                    label: t('property.mobile'),
                    value: officer?.mobileNo,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 19,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 9),
                      Expanded(child: AppText.titleMedium(t('settings.postings'))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (controller.postings.isEmpty)
                    AppText.caption(t('today.noPosting'))
                  else
                    for (final posting in controller.postings)
                      DetailRow(
                        label: posting.areaName,
                        value: posting.role.isEmpty
                            ? null
                            : posting.role.label,
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded,
                          size: 19,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 9),
                      Expanded(child: AppText.titleMedium(t('settings.language'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Changing this changes layout direction as well as
                  // words, and it also changes the language the server
                  // answers in via Accept-Language.
                  SegmentedButton<AppLocale>(
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
                  const SizedBox(height: 20),
                  // Three states, not a switch. The default is *system*,
                  // and a two-position switch cannot say so: it shows
                  // "off" while the handset is in dark mode and forces the
                  // app to light the moment the officer touches it.
                  AppText.body(t('settings.darkMode')),
                  const SizedBox(height: 2),
                  AppText.bodySmall(
                    t('settings.darkModeHelp'),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.brightness_auto_rounded,
                              size: 18),
                          label: Text(t('settings.themeSystem')),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_rounded, size: 18),
                          label: Text(t('settings.themeLight')),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_rounded, size: 18),
                          label: Text(t('settings.themeDark')),
                        ),
                      ],
                      selected: {theme.themeMode.value},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        AppHaptics.select();
                        theme.setThemeMode(selection.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Beyond the operating system's own setting, because
                  // some officers have never been shown it.
                  AppText.body(t('settings.textSize')),
                  const SizedBox(height: 8),
                  SegmentedButton<double>(
                    segments: [
                      for (var i = 0; i < ThemeController.textScales.length; i++)
                        ButtonSegment(
                          value: ThemeController.textScales[i],
                          label: AppText.label(
                            t('settings.textSize.$i'),
                          ),
                        ),
                    ],
                    selected: {theme.textScale.value},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        theme.setTextScale(selection.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_iphone_rounded,
                          size: 19,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 9),
                      Expanded(child: AppText.titleMedium(t('settings.device'))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DetailRow(
                    label: t('auth.deviceName'),
                    value: controller.deviceName.value,
                  ),
                  if (controller.tokenExpiry.value != null)
                    DetailRow(
                      label: t('settings.tokenExpiresLabel'),
                      value: Formatters.date(controller.tokenExpiry.value!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            AppButton(
              label: t('settings.changePassword'),
              variant: AppButtonVariant.outline,
              onPressed: () => context.push(AppRoutes.changePassword),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: t('auth.signOut'),
              variant: AppButtonVariant.danger,
              isLoading: session.isSubmitting.value,
              onPressed: () async {
                final confirmed = await AppConfirmDialog.ask(
                  context,
                  title: t('auth.signOut'),
                  body: t('auth.signOutConfirm'),
                  confirmLabel: t('auth.signOut'),
                );
                if (confirmed) await session.signOut();
              },
            ),
          ],
        );
      }),
    );
  }
}
