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
  const RoundStickyHead({super.key, required this.group});

  final RoundGroup group;

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
        expandedHeight: _expanded,
        collapsedHeight: _collapsed,
        plate: context.brand.filledPlate,
        ink: ink,
        divider: Theme.of(context).dividerColor,
        measures: _measures(ink),
      ),
    );
  }
}

class _HeadDelegate extends SliverPersistentHeaderDelegate {
  const _HeadDelegate({
    required this.group,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.plate,
    required this.ink,
    required this.divider,
    required this.measures,
  });

  final RoundGroup group;
  final double expandedHeight;
  final double collapsedHeight;
  final Gradient plate;
  final Color ink;
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
      expandedHeight != old.expandedHeight ||
      collapsedHeight != old.collapsedHeight ||
      plate != old.plate ||
      ink != old.ink ||
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
    this.briefing = true,
    this.briefingOpacity = 1,
  });

  final RoundGroup group;

  /// The ink the brand plate carries — near-black in both themes.
  final Color ink;

  /// Whether the two briefing lines are in the block at all. False is the
  /// collapsed strip, whose height is what the pinned head shrinks to.
  final bool briefing;

  /// How much of those lines is left as the strip collapses.
  final double briefingOpacity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.storefront_rounded, size: 17, color: ink),
              const SizedBox(width: 8),
              Expanded(
                child: AppText.titleMedium(_name, color: ink, maxLines: 1),
              ),
              const SizedBox(width: 12),
              AppText.titleMedium(
                Formatters.money(group.outstanding) ?? group.outstanding,
                color: ink,
                maxLines: 1,
              ),
            ],
          ),
          if (briefing)
            Opacity(
              opacity: briefingOpacity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 3),
                  AppText.caption(
                    _where,
                    color: ink.withValues(alpha: 0.7),
                    maxLines: 1,
                  ),
                  if (counts(group).isNotEmpty) ...<Widget>[
                    const SizedBox(height: 5),
                    _Counts(group: group, ink: ink),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String get _name => group.marketName ?? group.areaName ?? 'Unnamed bazaar';

  /// Where the market is, how many of its shops are behind, and how many of
  /// those the server picked out — three figures that read as a contradiction
  /// unless the last one says it is a shortlist.
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
      '${group.shops} ${group.shops == 1 ? 'shop' : 'shops'} behind',
      if (stops == 0)
        'none picked out yet'
      else if (stops >= group.shops)
        'all $stops on the round'
      else
        'worst $stops to call at',
    ].join(' · ');
  }

  /// The states that are actually true of this market, worst first. A row of
  /// zeroes is three more things to read and nothing to act on.
  ///
  /// Toned against light on purpose: the brand plate is a light tint in both
  /// themes, so the dark scheme's own status colours — picked to sit on
  /// near-black — would wash out on it.
  static List<({String label, Color colour})> counts(RoundGroup group) {
    final int broken = group.brokenPromises;
    return <({String label, Color colour})>[
      if (broken > 0)
        (
          label:
              '$broken ${broken == 1 ? 'broke a promise' : 'broke promises'}',
          colour: AppTone.danger.resolve(Brightness.light),
        ),
      if (group.neverPaid > 0)
        (
          label: '${group.neverPaid} never paid',
          colour: AppTone.warning.resolve(Brightness.light),
        ),
      if (group.sealed > 0)
        (
          label: '${group.sealed} sealed',
          colour: AppTone.info.resolve(Brightness.light),
        ),
    ];
  }
}

/// The market's states on one line, each in its own colour, cut off rather
/// than wrapped — the strip has a declared height and no room to grow.
class _Counts extends StatelessWidget {
  const _Counts({required this.group, required this.ink});

  final RoundGroup group;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final List<({String label, Color colour})> entries =
        RoundBazaarHead.counts(group);

    return ClipRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < entries.length; i++) ...<Widget>[
              if (i > 0)
                AppText.caption(
                  ' · ',
                  color: ink.withValues(alpha: 0.45),
                  maxLines: 1,
                ),
              AppText.caption(
                entries[i].label,
                color: entries[i].colour,
                fontWeight: FontWeight.w700,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
