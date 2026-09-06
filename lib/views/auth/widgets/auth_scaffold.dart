import 'package:flutter/material.dart';

import '../../../config/theme/app_radius.dart';
import '../../../widgets/widgets.dart';

/// The frame both auth screens are built in: the crest over the brand
/// backdrop, and a sheet of surface pulled up over it holding the form.
///
/// The sheet takes whatever height is left, so the form scrolls inside it when
/// the keyboard is up and the crest above stays put.
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
