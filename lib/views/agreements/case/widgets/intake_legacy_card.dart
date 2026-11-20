import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../models/intake_legacy.dart';
import '../../../../widgets/widgets.dart';
import 'intake_info_card.dart';

/// The case now beside the shop's old legacy register row. Differences are
/// listed; matching fields fold into one line so the card stays short.
class IntakeLegacyCard extends StatelessWidget {
  const IntakeLegacyCard({
    super.key,
    required this.legacy,
    required this.checks,
    required this.showMatches,
    required this.onShowMatches,
  });

  final IntakeLegacy legacy;
  final List<LegacyCheck> checks;
  final bool showMatches;
  final ValueChanged<bool> onShowMatches;

  @override
  Widget build(BuildContext context) {
    final IntakeLegacyEntry? entry = legacy.entry;
    final Color? muted = _muted(context);
    List<LegacyCheck> only(LegacyMatch m) =>
        checks.where((LegacyCheck c) => c.match == m).toList();
    final List<LegacyCheck> differs = only(LegacyMatch.differs);
    final List<LegacyCheck> unchecked = only(LegacyMatch.unchecked);
    final List<LegacyCheck> same = only(LegacyMatch.same);
    final List<LegacyCheck> rows = <LegacyCheck>[
      ...differs,
      ...unchecked,
      if (showMatches) ...same,
    ];

    final String source = entry == null
        ? ''
        : <String>[
            if (entry.sheetRow != null) 'Row ${entry.sheetRow}',
            ?entry.sourceReference?.split(',').first,
            if (entry.versionNo != null) 'v${entry.versionNo}',
          ].join(' · ');

    return IntakeInfoCard(
      title: 'Legacy register',
      icon: Icons.history_edu_outlined,
      trailing: entry == null
          ? const AppStatusBadge(label: 'No entry')
          : differs.isNotEmpty
          ? AppStatusBadge(
              label: '${differs.length} differ',
              tone: AppTone.warning,
              icon: Icons.compare_arrows_rounded,
            )
          : unchecked.isEmpty && same.isNotEmpty
          ? const AppStatusBadge(
              label: 'Matches',
              tone: AppTone.success,
              icon: Icons.check_rounded,
            )
          : null,
      children: <Widget>[
        if (entry == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppText.body(
              'This shop has no row in the legacy register.',
              color: muted,
            ),
          )
        else ...<Widget>[
          if (source.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppText.caption(source, color: muted, maxLines: 1),
            ),
          if (rows.isNotEmpty) ...<Widget>[
            const _Row(
              label: '',
              now: 'Now · this case',
              old: 'Old · register',
            ),
            for (final LegacyCheck check in rows)
              _Row(
                label: check.label,
                now: check.caseValue,
                old: check.legacyValue,
                match: check.match,
              ),
          ],
          if (same.isNotEmpty)
            _MatchesLine(
              same: same,
              all: differs.isEmpty && unchecked.isEmpty,
              open: showMatches,
              onTap: () => onShowMatches(!showMatches),
            ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  static Color? _muted(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
}

/// The label and verdict glyph over the value now and the old one. With no
/// [match] it is the column heading.
class _Row extends StatelessWidget {
  const _Row({required this.label, this.now, this.old, this.match});

  final String label;
  final String? now;
  final String? old;
  final LegacyMatch? match;

  @override
  Widget build(BuildContext context) {
    final Color? muted = IntakeLegacyCard._muted(context);
    final bool header = match == null;
    final bool differs = match == LegacyMatch.differs;
    final Color warn = AppTone.warning.on(context);

    // Headings in the colour of their side: brand for now, amber for the
    // register, as its values turn amber when they differ.
    Widget value(
      String? text, {
      Color? color,
      AppTone tone = AppTone.primary,
    }) => header
        ? AppText.label(
            text ?? '',
            color: tone.on(context),
            fontWeight: FontWeight.w800,
          )
        : AppText.body(
            text ?? '—',
            color: text == null ? muted : color,
            fontWeight: FontWeight.w600,
            maxLines: 3,
          );

    // Values get the full width under their label: a CNIC needs it.
    final Widget values = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: value(now)),
        const SizedBox(width: 12),
        Expanded(
          child: value(
            old,
            color: differs ? warn : null,
            tone: AppTone.warning,
          ),
        ),
      ],
    );

    final Widget? glyph = switch (match) {
      LegacyMatch.same => Icon(
        Icons.check_circle_rounded,
        size: 16,
        color: AppTone.success.on(context),
      ),
      LegacyMatch.differs => Icon(Icons.error_rounded, size: 16, color: warn),
      LegacyMatch.unchecked => Icon(
        Icons.remove_rounded,
        size: 16,
        color: muted,
      ),
      null => null,
    };

    return Container(
      margin: EdgeInsets.only(bottom: header ? 0 : 4),
      padding: EdgeInsets.fromLTRB(8, header ? 0 : 6, 8, header ? 6 : 7),
      decoration: differs
          ? BoxDecoration(
              color: AppTone.warning.container(context),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            )
          : null,
      child: header
          ? values
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppText.caption(
                        match == LegacyMatch.unchecked
                            ? '$label · not on both'
                            : label,
                        color: differs ? warn : muted,
                        fontWeight: differs ? FontWeight.w700 : null,
                      ),
                    ),
                    ?glyph,
                  ],
                ),
                const SizedBox(height: 1),
                values,
              ],
            ),
    );
  }
}

/// "Same in both: Name, CNIC" — tap to list them beside the differences.
class _MatchesLine extends StatelessWidget {
  const _MatchesLine({
    required this.same,
    required this.all,
    required this.open,
    required this.onTap,
  });

  final List<LegacyCheck> same;

  /// Every field matched, so the line is the whole verdict.
  final bool all;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color ok = AppTone.success.on(context);
    final Color link = Theme.of(context).colorScheme.primary;
    final String names = same.map((LegacyCheck c) => c.label).join(', ');
    return AppPress(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(
          children: <Widget>[
            Icon(Icons.check_circle_rounded, size: 16, color: ok),
            const SizedBox(width: 8),
            Expanded(
              child: AppText.caption(
                all
                    ? 'All ${same.length} fields match'
                    : 'Same in both: $names',
                color: IntakeLegacyCard._muted(context),
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 8),
            AppText.caption(
              open ? 'Hide' : 'Show',
              color: link,
              fontWeight: FontWeight.w700,
            ),
            Icon(
              open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 18,
              color: link,
            ),
          ],
        ),
      ),
    );
  }
}
