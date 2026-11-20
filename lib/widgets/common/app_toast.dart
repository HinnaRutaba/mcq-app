import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../text/app_text.dart';

/// A short confirmation that drops in at the top of the screen and leaves by
/// itself. For an act that went through; a snackbar reads as a system notice.
class AppToast {
  AppToast._();

  /// How long it stays before leaving. A tap sends it off sooner.
  static const Duration shownFor = Duration(milliseconds: 2800);

  static OverlayEntry? _current;
  static GlobalKey<_ToastState>? _currentKey;

  static void show(
    BuildContext context,
    String message, {
    AppTone tone = AppTone.success,
    IconData? icon,
  }) {
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    // One at a time: a new toast replaces the one on screen.
    _remove();

    final GlobalKey<_ToastState> key = GlobalKey<_ToastState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Toast(
        key: key,
        message: message,
        tone: tone,
        icon: icon ?? _glyph(tone),
        onGone: () {
          if (identical(_current, entry)) _remove();
        },
      ),
    );
    _current = entry;
    _currentKey = key;
    overlay.insert(entry);
  }

  /// Sends the toast on screen off, animated. Nothing happens if none is up.
  static void dismiss() => _currentKey?.currentState?._leave();

  static void _remove() {
    _current?.remove();
    _current = null;
    _currentKey = null;
  }

  static IconData _glyph(AppTone tone) => switch (tone) {
    AppTone.success => Icons.check_circle_rounded,
    AppTone.warning || AppTone.accent => Icons.warning_amber_rounded,
    AppTone.danger => Icons.error_outline_rounded,
    _ => Icons.info_outline_rounded,
  };
}

class _Toast extends StatefulWidget {
  const _Toast({
    super.key,
    required this.message,
    required this.tone,
    required this.icon,
    required this.onGone,
  });

  final String message;
  final AppTone tone;
  final IconData icon;
  final VoidCallback onGone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 220),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _motion.forward();
    _timer = Timer(AppToast.shownFor, _leave);
  }

  Future<void> _leave() async {
    _timer?.cancel();
    if (!mounted || _motion.status == AnimationStatus.reverse) return;
    await _motion.reverse();
    widget.onGone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color ink = widget.tone.on(context);
    final Animation<double> drop = CurvedAnimation(
      parent: _motion,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1.2),
                  end: Offset.zero,
                ).animate(drop),
                child: FadeTransition(
                  opacity: _motion,
                  child: Semantics(
                    liveRegion: true,
                    child: GestureDetector(
                      onTap: _leave,
                      // Swipe up to send it off early.
                      onVerticalDragEnd: (DragEndDetails d) {
                        if ((d.primaryVelocity ?? 0) < 0) _leave();
                      },
                      child: Material(
                        color: widget.tone.container(context),
                        elevation: 6,
                        shadowColor: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                          child: Row(
                            children: <Widget>[
                              Icon(widget.icon, color: ink, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AppText.body(
                                  widget.message,
                                  color: ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
