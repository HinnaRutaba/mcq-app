import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/dialer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/field/field_card.dart';
import '../../../../widgets/widgets.dart';

/// The top of the profile: who this is, and what state he is in.
///
/// The name arrives here from the card the officer tapped, through a
/// [Hero], so it visibly continues rather than cutting to a new page.
///
/// The status strip beneath it says sealed / case open / promise standing /
/// never paid — and when **none** of those apply it says so in one quiet
/// line. Rendering nothing there leaves the reader unsure whether the check
/// ran at all, which on this screen is the difference between "no seal" and
/// "we did not look".
class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.card,
    this.heroPrefix = 'defaulters',
  });

  final FieldCard card;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Initials(name: card.allotteeName),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: '$heroPrefix-name-${card.propertyId}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: UserText.display(
                        card.allotteeName,
                        fallback: t('card.noTenant'),
                        maxLines: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AppText.body(card.unitLabel, color: muted, maxLines: 1),
                  UserText.caption(card.placeLabel, color: muted),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ContactChips(card: card),
        const SizedBox(height: 16),
        _StatusStrip(card: card),
      ],
    );
  }
}

/// Initials, drawn rather than fetched. There are no allottee photographs
/// in the register and a grey silhouette says nothing.
class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String? name;

  String get _letters {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 62,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [scheme.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: AppText.titleLarge(_letters, color: Colors.white),
    );
  }
}

/// The mobile number and the CNIC, as things the officer can actually use.
class _ContactChips extends StatelessWidget {
  const _ContactChips({required this.card});

  final FieldCard card;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (card.isCallable) {
      chips.addAll([
        _Chip(
          icon: Icons.phone_rounded,
          label: card.mobileNo!,
          tone: AppTone.success,
          onTap: () => Dialer.call(card.mobileNo),
        ),
        _Chip(
          icon: Icons.sms_rounded,
          label: t('profile.sms'),
          tone: AppTone.info,
          onTap: () => Dialer.sms(card.mobileNo),
        ),
      ]);
    }
    if ((card.cnic ?? '').isNotEmpty) {
      chips.add(
        _Chip(
          icon: Icons.badge_outlined,
          label: card.cnic!,
          tone: AppTone.neutral,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: card.cnic!));
            AppFeedback.toast(t('profile.copied'));
          },
        ),
      );
    }

    if (chips.isEmpty) {
      return AppText.bodySmall(
        t('profile.noContact'),
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final AppTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = tone.on(context);
    return AppPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(11, 9, 13, 9),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colour.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colour),
            const SizedBox(width: 7),
            Directionality(
              textDirection: TextDirection.ltr,
              child: AppText.label(label, color: colour),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sealed, case open, promise standing, never paid — or, in one quiet
/// sentence, none of them.
class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.card});

  final FieldCard card;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (card.isSealed)
        AppStatusBadge(
          label: (card.sealNo ?? '').isEmpty
              ? t('card.sealedPlain')
              : t('card.sealed', args: {'seal': card.sealNo!}),
          tone: AppStatusTone.danger,
          icon: Icons.lock_rounded,
        ),
      if (card.hasOpenCase)
        AppStatusBadge(
          label: t('card.caseOpen', args: {'id': '${card.openCaseId}'}),
          tone: AppStatusTone.info,
          icon: Icons.folder_open_rounded,
        ),
      if (card.promiseBroken)
        AppStatusBadge(
          label: t('profile.promiseBroken'),
          tone: AppStatusTone.danger,
          icon: Icons.warning_amber_rounded,
        )
      else if (card.promiseStanding)
        AppStatusBadge(
          label: t('profile.promiseStanding'),
          tone: AppStatusTone.warning,
          icon: Icons.handshake_rounded,
        ),
      if (card.neverPaid && !card.isVacant)
        AppStatusBadge(
          label: t('card.neverPaid'),
          tone: AppStatusTone.danger,
          icon: Icons.block_rounded,
        ),
      if (card.isVacant)
        AppStatusBadge(
          label: t('card.vacant'),
          tone: AppStatusTone.info,
          icon: Icons.storefront_outlined,
        ),
    ];

    if (badges.isEmpty) {
      // Saying "nothing applies" is a different statement from drawing
      // nothing, and only one of them tells the officer the check ran.
      return Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 17,
            color: AppTone.success.on(context),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: AppText.bodySmall(
              t('profile.nothingStanding'),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: badges);
  }
}
