import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/field/beat.dart';
import '../../../../widgets/widgets.dart';

/// The top band of the home screen: who he is, and where he is posted.
///
/// It is the first thing an officer sees every morning, so it is worth
/// making it feel like something: a deep forest-green gradient with a slow
/// ambient glow drifting across it, his name large and warm, his
/// designation under it, and then **his areas as chips**.
///
/// It is a **collapsing sliver**. Scrolling into the work folds the
/// greeting away and leaves his name pinned in a compact bar, which is a
/// fifth of a small screen handed back to the queues without losing the
/// title.
///
/// Those chips are not decoration. Area scoping is enforced server-side and
/// must be *displayed* — an officer reading his beat's arrears as the
/// city's is making decisions on a fraction of the register. MCQ asked for
/// this specifically.
class BeatHeaderSliver extends StatelessWidget {
  const BeatHeaderSliver({
    super.key,
    required this.officer,
    required this.scope,
    this.actions = const [],
  });

  final BeatOfficer officer;
  final BeatScope scope;
  final List<Widget> actions;

  /// "Good morning" / "Good afternoon" / "Good evening", by the handset
  /// clock. He opens this at seven in the morning and again at six.
  static String greetingKey(DateTime now) {
    if (now.hour < 12) return 'beat.goodMorning';
    if (now.hour < 17) return 'beat.goodAfternoon';
    return 'beat.goodEvening';
  }

  @override
  Widget build(BuildContext context) {
    const onBand = Colors.white;

    return AppGradientSliverHeader(
      expandedHeight: scope.areaNames.length > 3 ? 244 : 214,
      actions: actions,
      collapsedTitle: UserText.headline(
        officer.name,
        color: onBand,
        maxLines: 1,
        fallback: t('app.name'),
      ),
      expanded: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppText.body(
            t(greetingKey(DateTime.now())),
            color: onBand.withValues(alpha: 0.78),
          ),
          const SizedBox(height: 2),
          UserText.display(
            officer.name,
            color: onBand,
            maxLines: 2,
            fallback: t('app.name'),
          ),
          if ((officer.designation ?? '').isNotEmpty) ...[
            const SizedBox(height: 3),
            AppText.bodySmall(
              officer.designation!,
              color: onBand.withValues(alpha: 0.74),
              maxLines: 1,
            ),
          ],
          const SizedBox(height: 14),
          ScopeChips(scope: scope),
        ],
      ),
    );
  }
}

/// The officer's areas — and his zone, where the server sends one.
///
/// Printed on every screen of figures, not only here. "Which areas do these
/// numbers cover" is the question an officer must never have to ask.
class ScopeChips extends StatelessWidget {
  const ScopeChips({super.key, required this.scope, this.onBand = true});

  final BeatScope scope;

  /// True inside the header's gradient, where the chips are drawn light on
  /// dark; false on an ordinary surface.
  final bool onBand;

  @override
  Widget build(BuildContext context) {
    final foreground =
        onBand ? Colors.white : Theme.of(context).colorScheme.onSurface;

    if (!scope.restricted) {
      return _Chip(
        label: t('beat.allAreas'),
        icon: Icons.public_rounded,
        foreground: foreground,
        onBand: onBand,
      );
    }
    if (!scope.hasPosting) {
      return _Chip(
        label: t('beat.noPostingChip'),
        icon: Icons.person_off_outlined,
        foreground: foreground,
        onBand: onBand,
      );
    }

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final name in scope.areaNames)
          _Chip(
            label: name,
            icon: Icons.place_rounded,
            foreground: foreground,
            onBand: onBand,
          ),
        for (final zone in scope.zoneNames)
          _Chip(
            label: zone,
            icon: Icons.layers_rounded,
            foreground: foreground,
            onBand: onBand,
            faint: true,
          ),
      ],
    );
  }
}

/// A read-only chip.
///
/// Deliberately not a Material [Chip]: these are labels, not controls, and
/// a chip an officer taps and nothing happens is a chip that teaches him
/// the rest of the row is dead too. It carries the chip's shape so it reads
/// as part of the same family.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.onBand,
    this.faint = false,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final bool onBand;
  final bool faint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = onBand
        ? foreground.withValues(alpha: faint ? 0.08 : 0.15)
        : scheme.surfaceContainerHigh;
    final border = onBand
        ? foreground.withValues(alpha: 0.22)
        : scheme.outline;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 13, 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          UserText.caption(label, color: foreground),
        ],
      ),
    );
  }
}
