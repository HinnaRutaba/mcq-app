import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes/app_routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../controllers/api/offline_queue_controller.dart';
import '../../../controllers/api/session_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/auth/permissions.dart';
import '../../../widgets/widgets.dart';

/// Everything that is not one of the five daily screens.
///
/// **Grouped, not listed.** Twelve identical rows in one column is a menu
/// an officer reads top to bottom every time; three short groups with a
/// heading each is a menu he learns the shape of. The groups are the three
/// questions he is actually asking: what am I chasing, what is on record,
/// and what is this handset doing.
///
/// Each entry is gated on the permission behind it — a magistrate who does
/// not hold `enforcement.seal.view` simply does not see Seals, rather than
/// tapping into a 403.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final queue = Get.find<OfflineQueueController>();

    return Scaffold(
      appBar: AppBar(title: AppText.titleLarge(t('nav.more'))),
      body: Obx(
        () => ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 18, 32),
          children: [
            _Group(
              title: t('beat.queuesTitle'),
              entries: [
                _Entry(
                  icon: Icons.handshake_outlined,
                  label: t('followUps.title'),
                  route: AppRoutes.followUps,
                  tone: AppTone.warning,
                ),
                if (session.can(Permissions.caseView))
                  _Entry(
                    icon: Icons.assignment_ind_outlined,
                    label: t('cases.assignedTitle'),
                    route: AppRoutes.casesPath(assignedToMe: true),
                    tone: AppTone.info,
                  ),
                _Entry(
                  icon: Icons.map_outlined,
                  label: t('map.title'),
                  route: AppRoutes.map,
                  tone: AppTone.primary,
                ),
              ],
            ),
            _Group(
              title: t('profile.tabHistory'),
              entries: [
                if (session.can(Permissions.caseView))
                  _Entry(
                    icon: Icons.folder_open_outlined,
                    label: t('cases.title'),
                    route: AppRoutes.cases,
                    tone: AppTone.info,
                  ),
                if (session.can(Permissions.sealView))
                  _Entry(
                    icon: Icons.lock_outline_rounded,
                    label: t('seal.title'),
                    route: AppRoutes.seals,
                    tone: AppTone.danger,
                  ),
                if (session.can(Permissions.fineView))
                  _Entry(
                    icon: Icons.gavel_outlined,
                    label: t('fines.title'),
                    route: AppRoutes.fines,
                    tone: AppTone.warning,
                  ),
                if (session.can(Permissions.legalCaseView))
                  _Entry(
                    icon: Icons.balance_outlined,
                    label: t('legal.title'),
                    route: AppRoutes.legal,
                    tone: AppTone.info,
                  ),
                _Entry(
                  icon: Icons.insights_outlined,
                  label: t('activity.title'),
                  route: AppRoutes.activity,
                  tone: AppTone.success,
                ),
              ],
            ),
            _Group(
              title: t('settings.title'),
              entries: [
                _Entry(
                  icon: Icons.sync_rounded,
                  label: t('queue.title'),
                  route: AppRoutes.queue,
                  badge: queue.badgeCount,
                  // What has not reached the server is the one thing on
                  // this screen that can be wrong right now.
                  tone: queue.attentionCount > 0
                      ? AppTone.danger
                      : queue.badgeCount > 0
                          ? AppTone.warning
                          : AppTone.neutral,
                ),
                _Entry(
                  icon: Icons.settings_outlined,
                  label: t('settings.title'),
                  route: AppRoutes.settings,
                  tone: AppTone.neutral,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One heading and the card of rows under it.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.entries});

  final String title;
  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 10),
            child: AppText.caption(
              title.toUpperCase(),
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0)
                    Divider(
                      color: theme.dividerColor,
                      height: 1,
                      indent: 68,
                    ),
                  entries[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row: a toned icon plate, a label, an optional count, a chevron.
class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.label,
    required this.route,
    this.badge = 0,
    this.tone = AppTone.neutral,
  });

  final IconData icon;
  final String label;
  final String route;
  final int badge;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour =
        tone == AppTone.neutral ? theme.colorScheme.primary : tone.on(context);
    final plate = tone == AppTone.neutral
        ? theme.colorScheme.primaryContainer
        : tone.container(context);

    return ListTile(
      onTap: () {
        AppHaptics.select();
        context.push(route);
      },
      contentPadding:
          const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 6),
      shape: const RoundedRectangleBorder(),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: plate,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 20, color: colour),
      ),
      title: AppText.titleMedium(label, maxLines: 2),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge > 0) ...[
            AppStatusBadge(
              label: '$badge',
              tone: tone == AppTone.danger
                  ? AppStatusTone.danger
                  : AppStatusTone.warning,
              icon: Icons.sync_problem_rounded,
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
