import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/agreement_case.dart';
import '../../../../widgets/widgets.dart';
import '../intake_labels.dart';

/// One agreement case on the list: who and where up top, the facts a
/// reviewer scans as chips, rent and date in a footer.
class IntakeCard extends StatelessWidget {
  const IntakeCard({super.key, required this.file, this.onTap});

  final AgreementCase file;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.65);
    final String? rent = Formatters.money(
      file.amounts['verified_monthly_rent'] ?? file.amounts['monthly_rent'],
    );
    final String? address = file.shop.fullAddress;
    final String? cnic = file.applicant?.cnic;

    final List<Widget> chips = <Widget>[
      if (file.query != null)
        const AppStatusBadge(
          icon: Icons.help_outline_rounded,
          label: 'Query open',
          tone: AppTone.warning,
        ),
      if (file.shop.locationChangedSinceReview)
        const AppStatusBadge(
          icon: Icons.wrong_location_outlined,
          label: 'Location changed',
          tone: AppTone.danger,
        ),
      AppStatusBadge(
        icon: Icons.tag_rounded,
        label: file.intakeNo ?? 'Case ${file.id}',
        tone: AppTone.primary,
      ),
      if (file.caseType != null)
        AppStatusBadge(
          icon: Icons.category_outlined,
          label: file.caseType!.label,
          tone: AppTone.primary,
        ),
    ];
    final bool footer = rent != null || file.submittedAt != null;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Initials(name: file.applicant?.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppText.titleMedium(file.title, maxLines: 1),
                        ),
                        if (file.status != null) ...<Widget>[
                          const SizedBox(width: 8),
                          IntakeStatusBadge(
                            status: file.status!.value,
                            label: file.status!.label,
                            tone: file.status!.tone,
                          ),
                        ],
                      ],
                    ),
                    if (cnic != null) ...<Widget>[
                      const SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                          Icon(Icons.badge_outlined, size: 14, color: muted),
                          const SizedBox(width: 4),
                          AppText.caption(_cnic(cnic), color: muted),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: chips),
          if (address != null) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.place_outlined, size: 15, color: muted),
                const SizedBox(width: 6),
                Expanded(child: AppText.caption(address, color: muted)),
              ],
            ),
          ],
          if (footer) ...<Widget>[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                if (rent != null) ...<Widget>[
                  Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: AppTone.primary.on(context),
                  ),
                  const SizedBox(width: 6),
                  AppText.body(rent, fontWeight: FontWeight.w700),
                  AppText.caption(' / month', color: muted),
                ],
                const Spacer(),
                if (file.submittedAt != null) ...<Widget>[
                  Icon(Icons.schedule_rounded, size: 14, color: muted),
                  const SizedBox(width: 4),
                  AppText.caption(
                    Formatters.date(file.submittedAt!.toLocal()),
                    color: muted,
                  ),
                ],
                if (onTap != null) ...<Widget>[
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 20, color: muted),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 13 digits read as 12345-1234567-1.
  static String _cnic(String raw) {
    final String d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length != 13) return raw;
    return '${d.substring(0, 5)}-${d.substring(5, 12)}-${d.substring(12)}';
  }
}

/// The applicant's initials on a brand disc; a folder when unnamed.
class _Initials extends StatelessWidget {
  const _Initials({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final Color ink = AppTone.primary.on(context);
    final List<String> words = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((String w) => w.isNotEmpty)
        .toList();
    final String letters = words
        .take(2)
        .map((String w) => w[0].toUpperCase())
        .join();

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTone.primary.container(context),
        shape: BoxShape.circle,
      ),
      child: letters.isEmpty
          ? Icon(Icons.folder_open_rounded, size: 20, color: ink)
          : AppText.body(letters, color: ink, fontWeight: FontWeight.w700),
    );
  }
}

/// A case's status as a pill: the server's tone where it sent one.
class IntakeStatusBadge extends StatelessWidget {
  const IntakeStatusBadge({
    super.key,
    required this.status,
    required this.label,
    this.tone,
    this.filled = false,
  });

  final String status;
  final String label;
  final String? tone;

  /// Solid, for a badge on the brand plate.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(
      label: label == status ? IntakeLabels.status(status) : label,
      tone: tone == null ? _tone(status) : AppToneColors.fromApi(tone),
      filled: filled,
    );
  }

  static AppTone _tone(String status) => switch (status) {
    'pending_cmo' || 'pending_admin' || 'pending_dispatch' => AppTone.warning,
    'approved' || 'activated' => AppTone.success,
    'rejected' || 'cancelled' => AppTone.danger,
    'returned' => AppTone.info,
    _ => AppTone.neutral,
  };
}
