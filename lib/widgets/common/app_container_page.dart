import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_container_sheet.dart';

/// Opens a whole page by growing it out of the control that was pressed.
///
/// The page half of [AppContainerSheet]: the search box the officer pressed
/// becomes the screen, so what opens is plainly *that box's* page rather than
/// another screen sliding in from the right. Closing runs backwards, into the
/// box.
///
/// The transition only — the route that uses it lives under `config/routes/`,
/// which is the layer that knows about pages.
class AppContainerPage {
  AppContainerPage._();

  /// The surface growing, and the page's own contents arriving behind it.
  static const Duration openDuration = Duration(milliseconds: 420);
  static const Duration closeDuration = Duration(milliseconds: 280);

  /// Where the pressed control is drawn on screen, transforms and all. The
  /// same question the sheet asks, so it is answered in one place.
  static Rect? rectOf(GlobalKey? key) => AppContainerSheet.rectOf(key);

  /// When the page's contents start to appear — most of the way through the
  /// growth, so the surface arrives before anything is written on it.
  static const double _contentAt = 0.34;

  /// When the pressed control's own fill has finished handing over to the
  /// page's.
  static const double _handoverBy = 0.4;

  /// The transition itself, for a route's `transitionsBuilder`.
  ///
  /// [from] is the pressed control's rectangle in global coordinates, read
  /// with [rectOf] at the moment of the press. A cold link carries none, and
  /// the page grows out of a box where a header's search field sits — which is
  /// where the officer would have pressed had they arrived the usual way.
  static Widget grow(
    BuildContext context,
    Animation<double> animation,
    Widget child, {
    Rect? from,
    Color? fromColor,
  }) {
    final ThemeData theme = Theme.of(context);
    final Size screen = MediaQuery.sizeOf(context);
    final Rect start =
        from ??
        Rect.fromCenter(
          center: Offset(
            screen.width / 2,
            MediaQuery.paddingOf(context).top + 84,
          ),
          width: screen.width - 40,
          height: 48,
        );

    final Animation<double> reveal = CurvedAnimation(
      parent: animation,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeInCubic,
    );

    final Widget surface = Stack(
      children: <Widget>[
        // The box's own fill, handed over early — the officer should see their
        // search box become the page, not a page arriving over it.
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0, _handoverBy, curve: Curves.easeOut),
                ),
              ),
              // The app's fields and cards are all drawn on `surface`, which
              // is what a control pressed to open a page is almost always
              // filled with.
              child: ColoredBox(
                color: fromColor ?? theme.colorScheme.surface,
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(_contentAt, 1, curve: Curves.easeOut),
          ),
          child: child,
        ),
      ],
    );

    return AnimatedBuilder(
      animation: reveal,
      child: surface,
      builder: (BuildContext context, Widget? built) => ClipRRect(
        clipper: _PageReveal(from: start, progress: reveal.value),
        child: built,
      ),
    );
  }
}

/// The growing hole the page is seen through: the pressed box's rectangle
/// opening out to the whole screen.
///
/// A clip rather than a box that changes size, because the page is laid out at
/// its full size from the first frame — so nothing inside it reflows as the
/// transition runs.
class _PageReveal extends CustomClipper<RRect> {
  const _PageReveal({required this.from, required this.progress});

  final Rect from;
  final double progress;

  @override
  RRect getClip(Size size) {
    final Rect rect = Rect.lerp(from, Offset.zero & size, progress)!;
    // A search box is a rounded field; the screen is square-cornered.
    final double box = from.shortestSide / 2;
    return RRect.fromRectAndRadius(
      rect,
      Radius.circular(lerpDouble(box, 0, progress)!),
    );
  }

  @override
  bool shouldReclip(_PageReveal old) =>
      old.progress != progress || old.from != from;
}
