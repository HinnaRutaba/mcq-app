import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme/app_radius.dart';
import '../../../core/utils/screen_type.dart';
import '../../../widgets/widgets.dart';
import 'auth_panel_clipper.dart';

/// The frame both auth screens are built in: the crest over the brand
/// backdrop, and a sheet of surface pulled up over it holding the form.
///
/// The sheet takes whatever height is left, so the form scrolls inside it when
/// the keyboard is up and the crest above stays put. Wider than a phone, the
/// crest moves into a brand panel beside the form instead.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.message,
    required this.child,
  });

  final String title;

  /// One line under [title] saying what signing in is for.
  final String message;

  /// The form itself.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppResponsive(
      mobile: _buildMobile,
      tablet: (BuildContext context) =>
          _Wide(title: title, message: message, child: child),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      body: AppBrandBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 22, 24, 24),
                child: Column(
                  children: <Widget>[
                    AppLogo(size: 78),
                    SizedBox(height: 14),
                    AppText.titleMedium(
                      'Metropolitan Corporation Quetta',
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _Sheet(title: title, message: message, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.message,
    required this.child,
  });

  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.65);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          32,
          24,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppText.headlineMedium(title),
                const SizedBox(height: 8),
                AppText.body(message, color: muted),
                const SizedBox(height: 28),
                child,
                const SizedBox(height: 32),
                const Center(child: AppGovernmentMark()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The tablet and desktop layout: the form on the left, the brand panel on
/// the right, both inside one rounded sheet.
class _Wide extends StatelessWidget {
  const _Wide({
    required this.title,
    required this.message,
    required this.child,
  });

  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.65);
    final double gutter = context.responsive(mobile: 12, desktop: 16);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(gutter),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Padding(
              padding: EdgeInsets.all(gutter),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              AppText.headlineLarge(
                                title,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              AppText.body(
                                message,
                                color: muted,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 36),
                              child,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: gutter),
                  // The panel gives up some width on a tablet, where the form
                  // needs it more than the crest does.
                  Expanded(
                    flex: context.responsive(mobile: 5, desktop: 7),
                    child: const _BrandPanel(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);

    Widget logo = const AppLogo(size: 128);
    Widget name = const AppText.titleLarge(
      'Metropolitan Corporation Quetta',
      color: Colors.white,
      textAlign: TextAlign.center,
    );
    Widget mark = const AppGovernmentMark(onDark: true, height: 56);

    if (!still) {
      // The crest arrives, then bobs on a slow loop in time with the ground.
      logo = logo
          .animate(
            onPlay: (AnimationController loop) => loop.repeat(reverse: true),
          )
          .moveY(
            begin: -6,
            end: 6,
            duration: 3200.ms,
            curve: Curves.easeInOutSine,
          )
          .animate()
          .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
          .scaleXY(
            begin: 0.9,
            end: 1,
            duration: 600.ms,
            curve: Curves.easeOutBack,
          );
      name = name
          .animate(delay: 150.ms)
          .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
          .slideY(
            begin: 0.4,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOutCubic,
          );
      mark = mark
          .animate(delay: 300.ms)
          .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic);
    }

    return ClipPath(
      clipper: const AuthPanelClipper(),
      child: AppBrandBackdrop(
        drift: true,
        child: Stack(
          children: <Widget>[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[logo, const SizedBox(height: 22), name],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Center(child: mark),
            ),
          ],
        ),
      ),
    );
  }
}
