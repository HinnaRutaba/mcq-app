import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../config/theme/app_brand.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_status_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../widgets/widgets.dart';

class OwedStrip extends StatelessWidget {
  const OwedStrip({
    super.key,
    required this.owed,
    this.unpaidMonths,
    this.lastPaid,
    this.neverPaid = false,
    this.nextVisit,
    this.promised = false,
    this.collapse = 0,
  });

  /// Rent arrears, already formatted. Never a fine — that is a separate debt
  /// on a separate challan, and the two are never totalled.
  final String owed;

  final int? unpaidMonths;
  final DateTime? lastPaid;
  final bool neverPaid;

  /// When the officer is next due at the shop.
  final DateTime? nextVisit;

  /// Whether a promise to pay stands against [nextVisit]. Worded the way the
  /// defaulters list words it, so the same day does not read as two different
  /// facts across the two screens.
  final bool promised;

  /// How far the header carrying this has collapsed — 0 at rest, 1 fully
  /// down, where the plate is the label and the figure and nothing else.
  ///
  /// Every part of the plate that goes shrinks linearly with it, so the
  /// header can lerp its own height between the two ends and land on the
  /// plate's actual height at every point in between.
  final double collapse;

  /// Dark ink, always, per the accent's own rule in [AppColors] — and at full
  /// strength rather than muted, because at 75% the label and the note under
  /// the figure land at 4.2:1 on the gold, and this at 7:1.
  static const Color _ink = AppColors.onAccent;

  /// What the figure shrinks to on the collapsed plate: a title's size rather
  /// than a display's, still the loudest thing on the bar.
  static const double _figureShrink = 0.7;

  @override
  Widget build(BuildContext context) {
    // The scheme's own accent, so the block follows whichever colour the
    // officer picked instead of pinning one gold.
    final Color gold = context.brand.accent;
    final double t = collapse.clamp(0.0, 1.0);
    // The pills and the note are what the plate loses on the way down. They
    // shrink with it at full strength and only fade over the last half, so a
    // header at rest half way down is a smaller plate rather than a washed
    // out one.
    final double extras = 1 - t;
    final double fade = (extras * 2).clamp(0.0, 1.0);
    final List<Widget> pills = _pills();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        12,
        lerpDouble(12, 8, t)!,
        12,
        lerpDouble(14, 8, t)!,
      ),
      decoration: BoxDecoration(
        color: gold,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Color.lerp(gold, Colors.black, 0.22)!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 15,
                color: _ink,
              ),
              const SizedBox(width: 12),
              AppText.caption('Owes right now', color: _ink),
            ],
          ),
          SizedBox(height: lerpDouble(4, 3, t)!),
          AppShrink(
            scale: lerpDouble(1, _figureShrink, t)!,
            child: AppText(
              owed,
              variant: AppTextVariant.displaySmall,
              color: _ink,
              maxLines: 1,
            ),
          ),
          if (extras > 0) ...<Widget>[
            if (pills.isNotEmpty) ...<Widget>[
              SizedBox(height: 8 * extras),
              AppShrink(
                scale: extras,
                child: Opacity(
                  opacity: fade,
                  // White plates, not the app's tonal ones: a pale gold
                  // "months behind" on a gold plate is no pill at all. White
                  // separates from the plate, and the ink on it keeps the
                  // status colours the list uses rather than flattening the
                  // three into one.
                  child: Wrap(spacing: 12, runSpacing: 6, children: pills),
                ),
              ),
            ],
            SizedBox(height: 8 * extras),
            AppShrink(
              scale: extras,
              child: Opacity(
                opacity: fade,
                child: AppText.caption(
                  'Rent arrears only — a fine is a separate debt',
                  color: _ink,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _pills() {
    final int? months = unpaidMonths;
    // Locals, because a nullable field does not promote.
    final DateTime? paid = lastPaid;
    final DateTime? visit = nextVisit;

    return <Widget>[
      if (months != null && months > 0)
        _OwedPill(
          label: '$months ${months == 1 ? 'month' : 'months'} behind',
          tone: AppTone.warning,
        ),
      if (neverPaid)
        const _OwedPill(label: 'Never paid', tone: AppTone.danger)
      else if (paid != null)
        _OwedPill(label: 'Last paid ${Formatters.date(paid.toLocal())}'),
      if (visit != null)
        _OwedPill(
          // A promise and the day it comes due are one fact, not two.
          label: promised
              ? 'Promised · ${Formatters.date(visit.toLocal())}'
              : 'Visit ${Formatters.date(visit.toLocal())}',
          tone: promised ? AppTone.info : AppTone.neutral,
        ),
    ];
  }
}

/// A pill on the owed plate: white, so it stands off the gold, with the
/// tone's own ink on it.
class _OwedPill extends StatelessWidget {
  const _OwedPill({required this.label, this.tone = AppTone.neutral});

  final String label;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    // The plate is white in both modes, so the ink comes off the *light*
    // status palette whichever mode the app is in — the dark one is stepped
    // for a near-black surface and is too pale to read on white.
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          AppStatusColors.lightFor(context.brand.primary),
          context.brand,
        ],
      ),
      child: Builder(
        builder: (BuildContext context) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: AppText.caption(
            label,
            color: tone.on(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
