import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../config/theme/app_radius.dart';

/// Opens a bottom sheet by growing it out of the control that was pressed.
///
/// Material's container transform: the pill the officer pressed becomes the
/// sheet, so what opens is plainly *that button's* sheet rather than a panel
/// arriving from off screen. Closing runs backwards, back into the button.
///
/// Written here rather than taken from `package:animations`, whose
/// `OpenContainer` only ever expands into a full-screen route — that would
/// make this a page, and the shop behind it is half the point of a sheet.
class AppContainerSheet {
  AppContainerSheet._();

  /// [from] is a key on the pressed control, read for the rectangle it is
  /// actually drawn at — including any press scale it is holding. Pass none,
  /// or one whose control has since left the tree, and the sheet grows out of
  /// the bottom edge instead, which is what a sheet opened from a menu row or
  /// a test does.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    GlobalKey? from,
    Color? fromColor,
  }) {
    return Navigator.of(context).push<T>(
      _ContainerSheetRoute<T>(
        builder: builder,
        from: rectOf(from),
        fromColor: fromColor,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
      ),
    );
  }

  /// Where [key]'s widget is drawn on screen, transforms and all. Null when
  /// the key holds nothing — a control that has been rebuilt away, or a caller
  /// that never had one.
  static Rect? rectOf(GlobalKey? key) {
    final RenderObject? object = key?.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return null;
    // `localToGlobal` moves the origin but keeps the untransformed size, which
    // on a button held at 0.92 is a rectangle bigger than the thing on screen.
    return MatrixUtils.transformRect(
      object.getTransformTo(null),
      Offset.zero & object.size,
    );
  }

  /// The whole run: the surface growing, and the sheet's own contents
  /// staggering in behind it. Long, because the two happen in sequence rather
  /// than together.
  static const Duration openDuration = Duration(milliseconds: 380);
  static const Duration closeDuration = Duration(milliseconds: 240);

  /// When the contents start to appear — most of the way through the growth,
  /// so the surface arrives before anything is written on it.
  static const double _contentAt = 0.42;

  /// When the pressed control's own fill has finished handing over to the
  /// sheet's surface.
  static const double _handoverBy = 0.45;
}

class _ContainerSheetRoute<T> extends PopupRoute<T> {
  _ContainerSheetRoute({
    required this.builder,
    required this.from,
    required this.fromColor,
    required this.barrierLabel,
  });

  final WidgetBuilder builder;

  /// The rectangle to grow out of, in global coordinates.
  final Rect? from;

  /// The pressed control's fill, which the surface fades out of.
  final Color? fromColor;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => AppContainerSheet.openDuration;

  @override
  Duration get reverseTransitionDuration => AppContainerSheet.closeDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final ThemeData theme = Theme.of(context);
    final Size screen = MediaQuery.sizeOf(context);

    // No control to grow out of: a short pill at the bottom edge, which reads
    // as the sheet swelling up out of the screen.
    final Rect start =
        from ??
        Rect.fromCenter(
          center: Offset(screen.width / 2, screen.height - 32),
          width: screen.width * 0.5,
          height: 44,
        );

    final Animation<double> grow = CurvedAnimation(
      parent: animation,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeInCubic,
    );

    final Widget surface = Material(
      color: theme.colorScheme.surface,
      child: Stack(
        children: <Widget>[
          // The button's own fill, handed over to the surface early — the
          // officer should see their gold pill become the sheet, not a gold
          // sheet.
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: const Interval(
                      0,
                      AppContainerSheet._handoverBy,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: ColoredBox(
                  color: fromColor ?? theme.colorScheme.surface,
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(
                AppContainerSheet._contentAt,
                1,
                curve: Curves.easeOut,
              ),
            ),
            child: child,
          ),
        ],
      ),
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: _DragToDismiss(
        child: AnimatedBuilder(
          animation: grow,
          child: surface,
          builder: (BuildContext context, Widget? built) => ClipRRect(
            clipper: _Reveal(
              from: start,
              progress: grow.value,
              screenHeight: screen.height,
            ),
            child: built,
          ),
        ),
      ),
    );
  }
}

/// The growing hole the sheet is seen through: the pressed control's rectangle
/// opening out to the sheet's own.
///
/// A clip rather than a box that changes size, because the sheet is laid out
/// at its final size from the first frame — so its height never moves under
/// the transition, and nothing has to be measured before the animation can
/// start.
class _Reveal extends CustomClipper<RRect> {
  const _Reveal({
    required this.from,
    required this.progress,
    required this.screenHeight,
  });

  final Rect from;
  final double progress;
  final double screenHeight;

  @override
  RRect getClip(Size size) {
    final Rect full = Offset.zero & size;
    // The sheet sits on the bottom edge and spans the width, so its own
    // coordinates are the screen's less however tall it turned out.
    final Rect start = from.translate(0, -(screenHeight - size.height));
    final Rect rect = Rect.lerp(start, full, progress)!;

    final double pill = start.shortestSide / 2;
    return RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(lerpDouble(pill, AppRadius.xl, progress)!),
      topRight: Radius.circular(lerpDouble(pill, AppRadius.xl, progress)!),
      // Square by the time the sheet reaches the bottom of the screen.
      bottomLeft: Radius.circular(lerpDouble(pill, 0, progress)!),
      bottomRight: Radius.circular(lerpDouble(pill, 0, progress)!),
    );
  }

  @override
  bool shouldReclip(_Reveal oldClipper) =>
      oldClipper.progress != progress ||
      oldClipper.from != from ||
      oldClipper.screenHeight != screenHeight;
}

/// Swipe the sheet away, which is the gesture a bottom sheet owes an officer
/// holding the handset in one hand.
///
/// Drag from anywhere the list is not — the list wins the gesture where it can
/// actually scroll, the same as any other sheet.
class _DragToDismiss extends StatefulWidget {
  const _DragToDismiss({required this.child});

  final Widget child;

  /// Past this much of its own height, or thrown down faster than this, the
  /// sheet is being dismissed rather than nudged.
  static const double _dismissAt = 0.3;
  static const double _flingAt = 700;

  @override
  State<_DragToDismiss> createState() => _DragToDismissState();
}

class _DragToDismissState extends State<_DragToDismiss> {
  double _drag = 0;

  /// Whether [_drag] is being animated home rather than followed.
  bool _settling = false;

  void _update(DragUpdateDetails details) {
    setState(() {
      _settling = false;
      // Down only: dragging up on a sheet already at its height does nothing.
      _drag = (_drag + details.delta.dy).clamp(0, double.infinity);
    });
  }

  void _end(DragEndDetails details) {
    final double height = context.size?.height ?? 0;
    final bool dismissed =
        (details.primaryVelocity ?? 0) > _DragToDismiss._flingAt ||
        (height > 0 && _drag > height * _DragToDismiss._dismissAt);

    if (dismissed) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _settling = true;
      _drag = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _update,
      onVerticalDragEnd: _end,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _drag),
        // Zero while the finger is down: the sheet is following it, not
        // animating towards it.
        duration: _settling ? const Duration(milliseconds: 220) : Duration.zero,
        curve: Curves.easeOut,
        builder: (BuildContext context, double value, Widget? child) =>
            Transform.translate(offset: Offset(0, value), child: child),
        child: widget.child,
      ),
    );
  }
}
