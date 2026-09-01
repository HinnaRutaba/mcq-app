import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../motion/app_pressable.dart';
import '../motion/app_stagger.dart';
import '../text/app_text.dart';

/// One row of the action sheet.
///
/// **Hide, do not disable, an action the domain forbids.** A vacant unit
/// cannot be fined through the tenancy — there is nobody to bill and the
/// server returns 422 — so that action is not built at all, rather than
/// built greyed out. A greyed-out button asks the officer to work out why,
/// standing in a bazaar, and he cannot.
///
/// The same is true of permissions: an action the officer's `permissions`
/// do not carry is never offered. Showing a button that will be refused is
/// worse than not offering it.
class AppSheetAction {
  const AppSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.description,
    this.tone = AppTone.neutral,
    this.destructive = false,
  });

  final IconData icon;
  final String label;

  /// One line saying what it does, in plain words.
  final String? description;

  final VoidCallback onTap;
  final AppTone tone;

  /// Fires a heavier haptic and draws in the danger tone — sealing a shop
  /// should *feel* like a decision.
  final bool destructive;
}

/// The sheet of large, clearly labelled actions a profile opens.
///
/// Every row is icon **and** text — never icon-only. This officer may not
/// be a daily smartphone user, and an unlabelled glyph is a guess.
class AppActionSheet extends StatelessWidget {
  const AppActionSheet({
    super.key,
    required this.title,
    required this.actions,
    this.subtitle,
    this.emptyMessage,
    this.notice,
  });

  final String title;

  /// Names the shop and the allottee, so the officer can see at a glance
  /// whose file he is about to write on.
  final String? subtitle;

  final List<AppSheetAction> actions;

  /// Shown when permissions and the domain leave nothing on offer — an
  /// empty sheet with no explanation reads as a broken app.
  final String? emptyMessage;

  /// A sentence above the actions saying why some of them are missing.
  ///
  /// Hiding an action the domain forbids is right; hiding it *silently* is
  /// not. An officer looking for "Seal the shop" and not finding it needs
  /// to read the reason — usually the server's own sentence, which names
  /// the court case that stayed it.
  final Widget? notice;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<AppSheetAction> actions,
    String? subtitle,
    String? emptyMessage,
    Widget? notice,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // The sheet's surface, radius, drag handle and elevation come from
      // `bottomSheetTheme`, so this looks like every other sheet in the app
      // without repeating a single value here.
      useSafeArea: true,
      builder: (context) => AppActionSheet(
        title: title,
        subtitle: subtitle,
        actions: actions,
        emptyMessage: emptyMessage,
        notice: notice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 6, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleLarge(title),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  // Names the shop and the allottee, so the officer can see
                  // at a glance whose file he is about to write on.
                  AppText.body(
                    subtitle!,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
          Divider(color: theme.dividerColor, height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 20),
              children: [
                if (notice != null) ...[
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(6, 4, 6, 12),
                    child: notice!,
                  ),
                ],
                if (actions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 28),
                    child: AppText.body(
                      emptyMessage ?? '',
                      textAlign: TextAlign.center,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...[
                    for (var i = 0; i < actions.length; i++)
                      AppStaggerIn(
                        index: i,
                        child: _ActionRow(action: actions[i]),
                      ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});

  final AppSheetAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = action.destructive ? AppTone.danger : action.tone;
    final colour =
        tone == AppTone.neutral ? theme.colorScheme.primary : tone.on(context);
    final plate = tone == AppTone.neutral
        ? theme.colorScheme.primaryContainer
        : tone.container(context);

    // A real ListTile: 64 tall, icon and text, ink, a `button` semantic and
    // the platform's own focus handling — none of which a Container with a
    // GestureDetector on it has.
    return ListTile(
      onTap: () {
        if (action.destructive) {
          AppHaptics.decision();
        } else {
          AppHaptics.select();
        }
        Navigator.of(context).pop();
        action.onTap();
      },
      contentPadding:
          const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 8),
      minVerticalPadding: 14,
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: plate,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(action.icon, color: colour, size: 23),
      ),
      title: AppText.titleMedium(action.label, maxLines: 2),
      subtitle: action.description == null
          ? null
          : Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: AppText.bodySmall(
                action.description!,
                color: theme.colorScheme.onSurfaceVariant,
                maxLines: 3,
              ),
            ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        size: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: action.destructive
              ? colour.withValues(alpha: 0.42)
              : Colors.transparent,
        ),
      ),
    );
  }
}
