import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme/app_brand.dart';
import '../../../controllers/theme_controller.dart';
import '../../../widgets/widgets.dart';

/// Letting the officer make the app comfortable to look at.
///
/// A handset used all day in bright sun and again after dark is read by one
/// pair of eyes, and which colour is easiest on them is not something a
/// designer can decide from here. Five schemes rather than a colour picker:
/// each is a set someone has checked, and a free choice would let an officer
/// build an interface where the brand is the same red as an overdue account.
///
/// Nothing here reaches the server. It is this handset's screen, and it stays
/// on this handset.
class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  static const Map<ThemeMode, String> _modeLabels = <ThemeMode, String>{
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
    ThemeMode.system: 'System',
  };

  static IconData _modeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
    ThemeMode.system => Icons.settings_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ThemeController>();
    final muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText.titleMedium('Colour scheme'),
        const SizedBox(height: 4),
        AppText.body(
          'Changes the whole interface, not one colour. Pick whichever is '
          'easiest on your eyes — nothing else changes.',
          color: muted,
        ),
        const SizedBox(height: 14),
        Obx(
          () => Column(
            children: <Widget>[
              for (final AppColorScheme scheme in AppColorScheme.values) ...[
                if (scheme != AppColorScheme.values.first)
                  const SizedBox(height: 10),
                _SchemeCard(
                  scheme: scheme,
                  selected: controller.colorScheme.value == scheme,
                  onTap: () => controller.setColorScheme(scheme),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        const AppText.titleMedium('Light or dark'),
        const SizedBox(height: 4),
        AppText.body(
          '“System” follows your handset’s own setting, so the screen dims '
          'in the evening on its own.',
          color: muted,
        ),
        const SizedBox(height: 12),
        Obx(
          () => AppChipTabs<ThemeMode>(
            items: _modeLabels.keys.toList(),
            itemLabel: (ThemeMode mode) => _modeLabels[mode]!,
            itemIcon: _modeIcon,
            selected: controller.themeMode.value,
            onChanged: controller.setThemeMode,
          ),
        ),
      ],
    );
  }
}

/// One scheme, with a sample of what it does before it is applied.
class _SchemeCard extends StatelessWidget {
  const _SchemeCard({
    required this.scheme,
    required this.selected,
    required this.onTap,
  });

  final AppColorScheme scheme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    // The chosen scheme's own colour rings it, so the selection is shown in
    // the thing being selected.
    final ring = scheme.of(theme.brightness).primary;
    final radius = BorderRadius.circular(14);

    return Semantics(
      selected: selected,
      button: true,
      label: scheme.label,
      child: Material(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? ring : theme.dividerColor,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                _SchemePreview(scheme: scheme),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: AppText.titleMedium(
                              scheme.label,
                              maxLines: 1,
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 6),
                            // Never the ring alone: a tick and, below, the
                            // word — a border colour is not a state a
                            // colourblind reader can rely on.
                            Icon(
                              Icons.check_circle_rounded,
                              size: 17,
                              color: ring,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      AppText.caption(
                        selected ? 'In use' : scheme.description,
                        color: selected ? ring : muted,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A miniature of the app in that scheme: the header band it puts at the top
/// of every screen, the accent it fills a button with, and the brand colour as
/// it lands on an ordinary surface.
///
/// Split in two on purpose. Drawn as one block it hid the very thing it was
/// meant to show — in light mode the header and the primary are the same
/// colour, so the bar disappeared into the band behind it.
class _SchemePreview extends StatelessWidget {
  const _SchemePreview({required this.scheme});

  final AppColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = scheme.of(theme.brightness);

    return Container(
      width: 84,
      height: 58,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[brand.headerFrom, brand.headerTo],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Bar(
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 5,
                  ),
                ),
                const SizedBox(width: 5),
                _Bar(color: brand.accent, height: 7, width: 14),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              color: theme.colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bar(color: brand.primary, height: 6, width: 44),
                  const Spacer(),
                  _Bar(
                    color: theme.colorScheme.surfaceContainerHighest,
                    height: 9,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color, required this.height, this.width});

  final Color color;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
    ),
  );
}
