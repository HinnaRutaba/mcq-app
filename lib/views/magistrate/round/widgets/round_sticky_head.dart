import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../config/theme/app_brand.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/round_group.dart';
import '../../../../widgets/widgets.dart';

/// One bazaar's head, pinned while its stops scroll under it — so an officer
/// six shops down a market still knows which market they are in.
///
/// It arrives with the briefing on it and shrinks to the name and the money as
/// the section scrolls: a pinned block that kept its full height would eat the
/// screen the stops need.
class RoundStickyHead extends StatefulWidget {
  const RoundStickyHead({
    super.key,
    required this.group,
    required this.collapsed,
    required this.onToggle,
  });

  final RoundGroup group;

  /// Whether this market is folded shut — which is what the chevron says and
  /// what the section under it does.
  final bool collapsed;

  final VoidCallback onToggle;

  @override
  State<RoundStickyHead> createState() => _RoundStickyHeadState();
}

class _RoundStickyHeadState extends State<RoundStickyHead> {
  /// Close to the real thing, so the frame before the first measurement is
  /// not visibly wrong. Every frame after uses what was measured.
  double _expanded = 78;
  double _collapsed = 45;

  void _onMeasured({double? expanded, double? collapsed}) {
    if (!mounted) return;
    final double open = expanded ?? _expanded;
    final double shut = collapsed ?? _collapsed;
    // Half a pixel: a measurement that only jitters is not worth a frame.
    if ((open - _expanded).abs() < 0.5 && (shut - _collapsed).abs() < 0.5) {
      return;
    }
    setState(() {
      _expanded = open;
      _collapsed = shut;
    });
  }

  /// The head at both ends, laid out where it cannot be seen, read, tapped or
  /// found — [Offstage] does all of that — so the strip can declare the
  /// heights it actually comes out at rather than adding the column up by hand
  /// and cutting a line off when the arithmetic drifts.
  ///
  /// Stretched, because the real block is laid out against a tight width and a
  /// copy measured against a loose one would wrap differently.
  Widget _measures(Color ink) => Offstage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppMeasure(
          onHeight: (double h) => _onMeasured(expanded: h),
          child: RoundBazaarHead(group: widget.group, ink: ink),
        ),
        AppMeasure(
          onHeight: (double h) => _onMeasured(collapsed: h),
          child: RoundBazaarHead(
            group: widget.group,
            ink: ink,
            briefing: false,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final Color ink = context.brand.onFilledPlate;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeadDelegate(
        group: widget.group,
        folded: widget.collapsed,
        onToggle: widget.onToggle,
        expandedHeight: _expanded,
        collapsedHeight: _collapsed,
        plate: context.brand.filledPlate,
        ink: ink,
        owed: AppTone.danger.resolve(Brightness.light),
        divider: Theme.of(context).dividerColor,
        measures: _measures(ink),
      ),
    );
  }
}

class _HeadDelegate extends SliverPersistentHeaderDelegate {
  const _HeadDelegate({
    required this.group,
    required this.folded,
    required this.onToggle,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.plate,
    required this.ink,
    required this.owed,
    required this.divider,
    required this.measures,
  });

  final RoundGroup group;
  final bool folded;
  final VoidCallback onToggle;
  final double expandedHeight;
  final double collapsedHeight;
  final Gradient plate;
  final Color ink;
  final Color owed;
  final Color divider;
  final Widget measures;

  @override
  double get minExtent => math.min(collapsedHeight, expandedHeight);

  @override
  double get maxExtent => math.max(collapsedHeight, expandedHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final double range = maxExtent - minExtent;
    final double t = range <= 0 ? 1 : (shrinkOffset / range).clamp(0.0, 1.0);

    // Full-bleed and opaque: a card with corners would show the stops sliding
    // behind its edges, and edge to edge is what makes this read as a heading
    // rather than as one more shop to call at.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: plate,
        border: Border(bottom: BorderSide(color: divider)),
      ),
      child: ClipRect(
        child: Stack(
          children: <Widget>[
            Positioned(left: 0, right: 0, top: 0, child: measures),
            // Laid out at its natural height whatever the strip has shrunk to,
            // and clipped above — so the briefing is cut away from the bottom
            // rather than squeezed.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: RoundBazaarHead(
                group: group,
                ink: ink,
                owed: owed,
                folded: folded,
                onToggle: onToggle,
                // Gone before the strip finishes collapsing, so the last of
                // the scroll is a clean name line and not half a word under it.
                briefingOpacity: (1 - t * 1.6).clamp(0.0, 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_HeadDelegate old) =>
      group != old.group ||
      folded != old.folded ||
      expandedHeight != old.expandedHeight ||
      collapsedHeight != old.collapsedHeight ||
      plate != old.plate ||
      ink != old.ink ||
      owed != old.owed ||
      divider != old.divider ||
      measures != old.measures;
}

/// What the head says. Its own widget so the strip above can measure it, and
/// so a test can read which market is on screen.
class RoundBazaarHead extends StatelessWidget {
  const RoundBazaarHead({
    super.key,
    required this.group,
    required this.ink,
    this.owed,
    this.folded = false,
    this.onToggle,
    this.briefing = true,
    this.briefingOpacity = 1,
  });

  final RoundGroup group;

  /// The ink the brand plate carries — near-black in both themes.
  final Color ink;

  /// The ink the arrears figure wears. Null in a measurement, where nothing
  /// is painted and only the height matters.
  final Color? owed;

  /// Whether the market is folded shut, which is which way the chevron points.
  final bool folded;

  final VoidCallback? onToggle;

  /// Whether the two briefing lines are in the block at all. False is the
  /// collapsed strip, whose height is what the pinned head shrinks to.
  final bool briefing;

  /// How much of those lines is left as the strip collapses.
  final double briefingOpacity;

  @override
  Widget build(BuildContext context) {
    final Widget block = Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 16, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              // The chevron says the market folds, and takes the place of the
              // shop glyph: the plate already says this is a heading, and two
              // icons on one line is one more thing to read.
              AnimatedRotation(
                turns: folded ? -0.25 : 0,
                duration: const Duration(milliseconds: 160),
                child: Icon(Icons.expand_more_rounded, size: 20, color: ink),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppText.titleMedium(_name, color: ink, maxLines: 1),
              ),
              const SizedBox(width: 12),
              AppText.titleMedium(
                Formatters.money(group.outstanding) ?? group.outstanding,
                color: owed ?? ink,
                fontWeight: FontWeight.w700,
                maxLines: 1,
              ),
            ],
          ),
          if (briefing)
            Opacity(
              opacity: briefingOpacity,
              child: Padding(
                // Under the name, clear of the chevron.
                padding: const EdgeInsets.only(left: 26, top: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppText.caption(
                      _where,
                      color: ink.withValues(alpha: 0.72),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: _chips()),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (onToggle == null) return block;

    return Semantics(
      button: true,
      label: folded ? 'Open $_name' : 'Fold $_name away',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: block,
      ),
    );
  }

  String get _name => group.marketName ?? group.areaName ?? 'Unnamed bazaar';

  /// Where the market is, and how many of its shops the server picked out —
  /// the shortlist beside the "shops behind" chip, which would otherwise read
  /// as a contradiction.
  ///
  /// The bazaar is named only when it adds something the market name has not
  /// already said: "Prince Road Market · Prince Road" is noise.
  String get _where {
    final String? area = group.areaName;
    final bool nameSaysIt =
        area == null || group.marketName == null || group.marketName == area;
    // The server's own shortlist, not however many stops a search has left
    // under this head — the market is being described, not the search.
    final int stops = group.shortlisted;

    return <String>[
      if (!nameSaysIt) area,
      if (stops == 0)
        'none picked out yet'
      else if (stops >= group.shops)
        'all $stops on the round'
      else
        'worst $stops to call at',
    ].join(' · ');
  }

  /// The market as the round describes it, straight off the payload: `shops`,
  /// `broken_promises`, `never_paid` and `sealed`.
  ///
  /// Every one of them, zeroes included — the four together are the state of
  /// the bazaar, and a chip that appears only when it is non-zero makes an
  /// officer wonder whether it was checked.
  ///
  /// Toned against light, because the brand plate under them is a light tint
  /// in both themes.
  List<Widget> _chips() => <Widget>[
    _chip('Shops behind', group.shops, AppTone.neutral),
    _chip('Broken promises', group.brokenPromises, AppTone.danger),
    _chip('Never paid', group.neverPaid, AppTone.warning),
    _chip('Sealed', group.sealed, AppTone.info),
  ];

  /// Nothing to be alarmed by at zero: no broken promise is the good outcome,
  /// and a red 0 reads as one more thing to chase.
  static Widget _chip(String label, int count, AppTone tone) => AppStatusBadge(
    label: '$label · $count',
    tone: count == 0 ? AppTone.neutral : tone,
    brightness: Brightness.light,
  );

}
