import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../config/theme/app_brand.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../models/api_refs.dart';
import '../../../../widgets/widgets.dart';
import 'holder_actions.dart';
import 'owed_strip.dart';

class ProfileHeader extends StatefulWidget {
  const ProfileHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.owed,
    required this.unpaidMonths,
    required this.lastPaid,
    required this.neverPaid,
    required this.nextVisit,
    required this.promised,
    required this.mobileNo,
    required this.point,
    required this.address,
    required this.onBack,
  });

  final String title;
  final String? subtitle;

  final String? owed;

  final int? unpaidMonths;
  final DateTime? lastPaid;
  final bool neverPaid;
  final DateTime? nextVisit;
  final bool promised;

  final String? mobileNo;
  final GeoPoint? point;
  final String? address;

  final VoidCallback onBack;

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();

  Widget _block(double t, {required bool hasActions}) {
    final String? owed = this.owed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: lerpDouble(18, 8, t)!),
        Row(
          children: <Widget>[
            AppCircleIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
            const SizedBox(width: 10),
            Expanded(child: _titleBlock()),
          ],
        ),
        if (owed != null) ...<Widget>[
          SizedBox(height: lerpDouble(20, 10, t)!),
          OwedStrip(
            owed: owed,
            unpaidMonths: unpaidMonths,
            lastPaid: lastPaid,
            neverPaid: neverPaid,
            nextVisit: nextVisit,
            promised: promised,
            collapse: t,
          ),
        ],
        if (hasActions) ...<Widget>[
          SizedBox(height: lerpDouble(14, 8, t)!),
          AppShrink(
            scale: lerpDouble(1, _actionShrink, t)!,
            child: HolderActions(
              mobileNo: mobileNo,
              point: point,
              address: address,
            ),
          ),
        ],
        SizedBox(height: lerpDouble(14, 10, t)!),
      ],
    );
  }

  /// Which shop, then who holds it — the same two lines at both ends, because
  /// a bar that names neither is a figure belonging to nobody.
  Widget _titleBlock() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      if (subtitle != null) ...<Widget>[
        AppText.body(
          subtitle!,
          color: Colors.white.withValues(alpha: 0.75),
          maxLines: 1,
        ),
        const SizedBox(height: 2),
      ],
      AppText.titleLarge(title, color: Colors.white, maxLines: 1),
    ],
  );

  /// The actions collapse to the small pill's height, so the chips on the bar
  /// are the size the rest of the app draws a compact one at.
  static final double _actionShrink =
      HolderActions.heightFor(compact: true) /
      HolderActions.heightFor(compact: false);
}

class _ProfileHeaderState extends State<ProfileHeader> {
  /// Close to the real thing, so the frame before the first measurement is
  /// not visibly wrong. Every frame after uses what was measured.
  double _expandedHeight = 300;
  double _collapsedHeight = 170;

  void _onMeasured({double? expanded, double? collapsed}) {
    if (!mounted) return;
    final double open = expanded ?? _expandedHeight;
    final double shut = collapsed ?? _collapsedHeight;
    // Half a pixel: a measurement that only jitters is not worth a frame.
    if ((open - _expandedHeight).abs() < 0.5 &&
        (shut - _collapsedHeight).abs() < 0.5) {
      return;
    }
    setState(() {
      _expandedHeight = open;
      _collapsedHeight = shut;
    });
  }

  /// The block at both ends, laid out where it cannot be seen, read, tapped or
  /// found — [Offstage] does all of that — so the header can declare the
  /// heights it actually comes out at.
  ///
  /// Stretched, because the real block is laid out against a tight width and a
  /// copy measured against a loose one would wrap differently.
  Widget _measures({required bool hasActions}) => Offstage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppMeasure(
          onHeight: (double h) => _onMeasured(expanded: h),
          child: widget._block(0, hasActions: hasActions),
        ),
        AppMeasure(
          onHeight: (double h) => _onMeasured(collapsed: h),
          child: widget._block(1, hasActions: hasActions),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bool hasActions =
        widget.mobileNo != null ||
        widget.point != null ||
        widget.address != null;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _ProfileHeaderDelegate(
        header: widget,
        hasActions: hasActions,
        expandedHeight: _expandedHeight,
        collapsedHeight: _collapsedHeight,
        topPadding: MediaQuery.paddingOf(context).top,
        brand: context.brand,
        measures: _measures(hasActions: hasActions),
      ),
    );
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ProfileHeaderDelegate({
    required this.header,
    required this.hasActions,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.topPadding,
    required this.brand,
    required this.measures,
  });

  final ProfileHeader header;
  final bool hasActions;
  final double expandedHeight;
  final double collapsedHeight;
  final double topPadding;
  final AppBrandColors brand;

  /// The offstage copies the two heights come from, built by the state and
  /// carried through unchanged, so a scroll frame rebuilds the block and not
  /// the two measurements of it.
  final Widget measures;

  /// The screen's horizontal rhythm.
  static const double _inset = 12;

  // Ordered, not trusted: a sliver whose min extent is over its max asserts.
  @override
  double get minExtent =>
      topPadding + math.min(collapsedHeight, expandedHeight);

  @override
  double get maxExtent =>
      topPadding + math.max(collapsedHeight, expandedHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final double range = maxExtent - minExtent;
    final double t = range <= 0 ? 1 : (shrinkOffset / range).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.xl),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[brand.headerFrom, brand.headerTo],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -26,
              bottom: -44,
              child: Opacity(opacity: 1 - t, child: const AppHeroOrnament()),
            ),
            Positioned(left: _inset, right: _inset, top: 0, child: measures),
            Positioned(
              left: _inset,
              right: _inset,
              top: topPadding,
              child: header._block(t, hasActions: hasActions),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_ProfileHeaderDelegate old) =>
      expandedHeight != old.expandedHeight ||
      collapsedHeight != old.collapsedHeight ||
      topPadding != old.topPadding ||
      hasActions != old.hasActions ||
      brand != old.brand ||
      header.title != old.header.title ||
      header.subtitle != old.header.subtitle ||
      header.owed != old.header.owed ||
      header.unpaidMonths != old.header.unpaidMonths ||
      header.lastPaid != old.header.lastPaid ||
      header.neverPaid != old.header.neverPaid ||
      header.nextVisit != old.header.nextVisit ||
      header.promised != old.header.promised ||
      header.mobileNo != old.header.mobileNo ||
      header.point != old.header.point ||
      header.address != old.header.address;
}
