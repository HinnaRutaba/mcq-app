import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../text/app_text.dart';
import 'app_gradient_header.dart';

/// The header a non-scrolling screen opens with — a deep forest-green band
/// with rounded bottom corners, the same gradient and the same slow ambient
/// glow as the dashboard's collapsing header, so a screen that cannot be a
/// sliver still belongs to the same app.
///
/// Pass just [title] for a simple screen header (Payments, Profile, …), or
/// add [subtitle]/[trailing]/[bottom] for a richer dashboard header that
/// carries a headline stat or quick facts.
///
/// Where the screen *is* a scroll view, prefer
/// [AppGradientSliverHeader]: it collapses as the officer scrolls into the
/// work and hands a fifth of a small screen back to the content.
class AppHeroHeader extends StatefulWidget {
  const AppHeroHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.bottom,
    this.glow = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottom;

  /// The drifting ambient light. Off on a header that sits behind a busy
  /// figure, where anything moving competes with it.
  final bool glow;

  @override
  State<AppHeroHeader> createState() => _AppHeroHeaderState();
}

class _AppHeroHeaderState extends State<AppHeroHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void initState() {
    super.initState();
    if (widget.glow) _drift.repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const onBand = Colors.white;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: dark
                ? const [Color(0xFF16402A), Color(0xFF0A1A11)]
                : const [AppColors.primaryLight, AppColors.primaryDark],
          ),
        ),
        child: Stack(
          children: [
            if (widget.glow)
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _drift,
                    builder: (context, _) => CustomPaint(
                      painter: AppAmbientGlowPainter(
                        phase: _drift.value,
                        accent: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                20,
                MediaQuery.paddingOf(context).top + 18,
                20,
                26,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.subtitle != null) ...[
                              AppText.body(
                                widget.subtitle!,
                                color: onBand.withValues(alpha: 0.78),
                              ),
                              const SizedBox(height: 2),
                            ],
                            AppText.headlineMedium(
                              widget.title,
                              color: onBand,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      ?widget.trailing,
                    ],
                  ),
                  if (widget.bottom != null) ...[
                    const SizedBox(height: 20),
                    DefaultTextStyle.merge(
                      style: const TextStyle(color: onBand),
                      child: widget.bottom!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
