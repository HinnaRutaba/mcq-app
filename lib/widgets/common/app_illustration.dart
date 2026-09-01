import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_status_colors.dart';

/// What an empty state is *about*. Every list that can be empty picks one.
enum AppIllustrationKind {
  /// Nothing is overdue in these areas. Good news, and it must look like it.
  allClear,

  /// No promise falls due today.
  nothingToChase,

  /// A shop is closed — the seal queue, and a sealed card.
  shopSealed,

  /// The round is walked, or there is nothing to walk.
  roundDone,

  /// A search that matched nothing.
  noResults,

  /// The officer holds no area posting.
  noPosting,

  /// Everything on the handset has reached the server.
  allSynced,

  /// A list that failed rather than emptied.
  disconnected,
}

/// A drawn illustration, not a stock icon and not an asset.
///
/// Every one is the same shop front — an awning, a shutter, a signboard —
/// with a different badge on it, so the set reads as one hand rather than
/// as eight stock downloads.
///
/// It plays as a **Lottie animation**: the shop draws itself on with a trim
/// path, the badge pops in, and the whole thing breathes once. The
/// animation runs a single two-second cycle and then holds — an empty state
/// that loops forever is a fidget in the corner of the officer's eye while
/// he is trying to read the sentence beside it.
///
/// Three things make this safe to ship on a bazaar handset:
///
/// * **The JSON is bundled**, not fetched. An empty state is most often
///   what an officer sees when his signal is worst, and an illustration
///   that needs the network to draw "you are offline" is a joke.
/// * **It is recoloured at runtime.** The files are authored in
///   placeholder colours with every layer named by role — `wash`, `line`,
///   `badge`, `glyph` — and [LottieDelegates] repaints them from the theme,
///   so one file serves light and dark and follows a palette change.
/// * **It falls back to paint.** If an asset is missing or fails to parse,
///   the original [_ShopFrontPainter] draws the same illustration
///   statically. A broken asset must never be a blank screen.
class AppIllustration extends StatelessWidget {
  const AppIllustration(this.kind, {super.key, this.size = 156});

  final AppIllustrationKind kind;
  final double size;

  /// The bundled animation for each state.
  static String assetOf(AppIllustrationKind kind) => switch (kind) {
        AppIllustrationKind.allClear => 'assets/lottie/all_clear.json',
        AppIllustrationKind.nothingToChase =>
          'assets/lottie/nothing_to_chase.json',
        AppIllustrationKind.shopSealed => 'assets/lottie/shop_sealed.json',
        AppIllustrationKind.roundDone => 'assets/lottie/round_done.json',
        AppIllustrationKind.noResults => 'assets/lottie/no_results.json',
        AppIllustrationKind.noPosting => 'assets/lottie/no_posting.json',
        AppIllustrationKind.allSynced => 'assets/lottie/all_synced.json',
        AppIllustrationKind.disconnected => 'assets/lottie/disconnected.json',
      };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final status = context.status;
    final line =
        dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final brand = dark ? AppColors.primaryOnDark : AppColors.primary;
    final wash = Color.alphaBlend(
      brand.withValues(alpha: dark ? 0.16 : 0.11),
      Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
    );
    final badge = _badgeColour(kind, status);
    final onBadge = _onBadge(kind, status);

    final painted = _Painted(
      kind: kind,
      size: size,
      line: line,
      brand: brand,
      wash: wash,
      badge: badge,
      onBadge: onBadge,
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Lottie.asset(
          assetOf(kind),
          width: size,
          height: size,
          fit: BoxFit.contain,
          repeat: false,
          // Keep the composition warm between empty states — the officer
          // hits several of these in a session.
          addRepaintBoundary: true,
          delegates: LottieDelegates(
            values: [
              ValueDelegate.color(const ['wash', '**'], value: wash),
              ValueDelegate.strokeColor(const ['line', '**'], value: line),
              ValueDelegate.color(const ['badge', '**'], value: badge),
              ValueDelegate.strokeColor(const ['glyph', '**'], value: onBadge),
              ValueDelegate.color(const ['glyph', '**'], value: onBadge),
            ],
          ),
          // A missing or malformed asset draws the painted original rather
          // than an error box or nothing at all.
          errorBuilder: (context, error, stack) => painted,
          frameBuilder: (context, child, composition) =>
              composition == null ? painted : child,
        ),
      ),
    );
  }

  static Color _badgeColour(AppIllustrationKind kind, AppStatusColors status) {
    switch (kind) {
      case AppIllustrationKind.allClear:
      case AppIllustrationKind.nothingToChase:
      case AppIllustrationKind.roundDone:
      case AppIllustrationKind.allSynced:
        return status.success;
      case AppIllustrationKind.shopSealed:
        return status.danger;
      case AppIllustrationKind.disconnected:
        return status.warning;
      case AppIllustrationKind.noResults:
      case AppIllustrationKind.noPosting:
        return status.info;
    }
  }

  static Color _onBadge(AppIllustrationKind kind, AppStatusColors status) {
    switch (kind) {
      case AppIllustrationKind.allClear:
      case AppIllustrationKind.nothingToChase:
      case AppIllustrationKind.roundDone:
      case AppIllustrationKind.allSynced:
        return status.onSuccess;
      case AppIllustrationKind.shopSealed:
        return status.onDanger;
      case AppIllustrationKind.disconnected:
        return status.onWarning;
      case AppIllustrationKind.noResults:
      case AppIllustrationKind.noPosting:
        return status.onInfo;
    }
  }
}

/// The static original, kept as the fallback path.
class _Painted extends StatelessWidget {
  const _Painted({
    required this.kind,
    required this.size,
    required this.line,
    required this.brand,
    required this.wash,
    required this.badge,
    required this.onBadge,
  });

  final AppIllustrationKind kind;
  final double size;
  final Color line;
  final Color brand;
  final Color wash;
  final Color badge;
  final Color onBadge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShopFrontPainter(
          kind: kind,
          line: line,
          brand: brand,
          wash: wash,
          badge: badge,
          onBadge: onBadge,
        ),
      ),
    );
  }
}

class _ShopFrontPainter extends CustomPainter {
  _ShopFrontPainter({
    required this.kind,
    required this.line,
    required this.brand,
    required this.wash,
    required this.badge,
    required this.onBadge,
  });

  final AppIllustrationKind kind;
  final Color line;
  final Color brand;
  final Color wash;
  final Color badge;
  final Color onBadge;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = line;
    final fill = Paint()..color = wash;

    // The ground the shop stands on.
    canvas.drawCircle(Offset(s * 0.5, s * 0.52), s * 0.42, fill);

    // Shop body.
    final body = Rect.fromLTWH(s * 0.22, s * 0.36, s * 0.56, s * 0.40);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        body,
        topLeft: Radius.circular(s * 0.03),
        topRight: Radius.circular(s * 0.03),
      ),
      stroke,
    );

    // Awning — the scalloped edge every bazaar shop has.
    final awning = Path()..moveTo(s * 0.17, s * 0.36);
    awning.lineTo(s * 0.26, s * 0.24);
    awning.lineTo(s * 0.74, s * 0.24);
    awning.lineTo(s * 0.83, s * 0.36);
    awning.close();
    canvas.drawPath(awning, Paint()..color = brand.withValues(alpha: 0.16));
    canvas.drawPath(awning, stroke);
    for (var i = 0; i < 5; i++) {
      final x = s * 0.17 + (s * 0.66 / 5) * (i + 0.5);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(x, s * 0.36), radius: s * 0.066),
        0,
        math.pi,
        false,
        stroke,
      );
    }

    // Shutter slats, or an open doorway.
    if (kind == AppIllustrationKind.shopSealed) {
      for (var i = 1; i < 5; i++) {
        final y = body.top + (body.height / 5) * i;
        canvas.drawLine(
          Offset(body.left + s * 0.035, y),
          Offset(body.right - s * 0.035, y),
          stroke,
        );
      }
    } else {
      final door = Rect.fromLTWH(s * 0.42, s * 0.52, s * 0.16, s * 0.24);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          door,
          topLeft: Radius.circular(s * 0.06),
          topRight: Radius.circular(s * 0.06),
        ),
        stroke,
      );
      canvas.drawLine(
        Offset(s * 0.27, s * 0.46),
        Offset(s * 0.36, s * 0.46),
        stroke,
      );
      canvas.drawLine(
        Offset(s * 0.64, s * 0.46),
        Offset(s * 0.73, s * 0.46),
        stroke,
      );
    }

    // The badge that says which empty state this is.
    final centre = Offset(s * 0.755, s * 0.755);
    final radius = s * 0.165;
    canvas.drawCircle(centre, radius + s * 0.028, Paint()..color = onBadge);
    canvas.drawCircle(centre, radius, Paint()..color = badge);
    _drawGlyph(canvas, centre, radius, onBadge, s);
  }

  void _drawGlyph(
    Canvas canvas,
    Offset c,
    double r,
    Color colour,
    double s,
  ) {
    final glyph = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.026
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = colour;

    switch (kind) {
      case AppIllustrationKind.allClear:
      case AppIllustrationKind.nothingToChase:
      case AppIllustrationKind.roundDone:
      case AppIllustrationKind.allSynced:
        // A tick.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - r * 0.44, c.dy)
            ..lineTo(c.dx - r * 0.08, c.dy + r * 0.36)
            ..lineTo(c.dx + r * 0.48, c.dy - r * 0.34),
          glyph,
        );
        break;
      case AppIllustrationKind.shopSealed:
        // A padlock.
        canvas.drawArc(
          Rect.fromCircle(center: Offset(c.dx, c.dy - r * 0.16), radius: r * 0.30),
          math.pi,
          math.pi,
          false,
          glyph,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(c.dx, c.dy + r * 0.24),
              width: r * 0.86,
              height: r * 0.62,
            ),
            Radius.circular(r * 0.14),
          ),
          glyph,
        );
        break;
      case AppIllustrationKind.noResults:
        // A magnifier.
        canvas.drawCircle(
          Offset(c.dx - r * 0.10, c.dy - r * 0.10),
          r * 0.36,
          glyph,
        );
        canvas.drawLine(
          Offset(c.dx + r * 0.18, c.dy + r * 0.18),
          Offset(c.dx + r * 0.46, c.dy + r * 0.46),
          glyph,
        );
        break;
      case AppIllustrationKind.noPosting:
        // A map pin with nothing in it.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy + r * 0.48)
            ..quadraticBezierTo(
                c.dx - r * 0.46, c.dy - r * 0.06, c.dx, c.dy - r * 0.48)
            ..quadraticBezierTo(
                c.dx + r * 0.46, c.dy - r * 0.06, c.dx, c.dy + r * 0.48),
          glyph,
        );
        break;
      case AppIllustrationKind.disconnected:
        // An exclamation.
        canvas.drawLine(
          Offset(c.dx, c.dy - r * 0.42),
          Offset(c.dx, c.dy + r * 0.08),
          glyph,
        );
        canvas.drawLine(
          Offset(c.dx, c.dy + r * 0.40),
          Offset(c.dx, c.dy + r * 0.42),
          glyph,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ShopFrontPainter old) =>
      old.kind != kind || old.badge != badge || old.line != line;
}
