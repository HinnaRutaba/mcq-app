import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/auth_user.dart';
import '../../../widgets/widgets.dart';

/// Who is signed in, from the token's own user — name, designation, how to
/// reach them, and the roles the server granted.
///
/// The officer is the one accountable for every seal and every fine recorded
/// on this handset, so the screen says plainly whose account it is. A shared
/// device in a bazaar makes that a working detail, not a decoration.
class OfficerCard extends StatelessWidget {
  const OfficerCard({super.key, required this.officer});

  final AuthUser officer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
                child: Icon(Icons.shield_outlined, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium(officer.name, maxLines: 1),
                    if (officer.designation != null) ...[
                      const SizedBox(height: 2),
                      AppText.caption(officer.designation!, maxLines: 1),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        for (final String role in officer.roles)
                          AppStatusBadge(label: role, tone: AppTone.primary),
                        if (officer.isLocked)
                          const AppStatusBadge(
                            label: 'LOCKED',
                            tone: AppTone.danger,
                          ),
                        if (!officer.isActive)
                          const AppStatusBadge(
                            label: 'INACTIVE',
                            tone: AppTone.warning,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          const SizedBox(height: 12),
          // Only what the server actually sent — `employee_no` and `branch_id`
          // come back null for this officer, and a row reading "—" is noise.
          _Detail(icon: Icons.badge_outlined, value: officer.username),
          if (officer.employeeNo != null)
            _Detail(icon: Icons.tag_rounded, value: officer.employeeNo!),
          if (officer.mobileNo != null)
            _Detail(icon: Icons.call_outlined, value: officer.mobileNo!),
          if (officer.email != null)
            _Detail(icon: Icons.mail_outline_rounded, value: officer.email!),
          if (officer.lastLoginAt != null)
            _Detail(
              icon: Icons.schedule_rounded,
              value: 'Last signed in ${Formatters.dateTime(officer.lastLoginAt!.toLocal())}',
            ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 10),
          Expanded(child: AppText.body(value, maxLines: 1)),
        ],
      ),
    );
  }
}
