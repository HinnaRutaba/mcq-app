import 'package:flutter/material.dart';

/// Wraps a pressable block so it dips under the thumb and springs back.
///
/// The gesture lives here rather than in an [InkWell] inside the child: one
/// recognizer, so a drag that turns into a scroll cancels the press instead of
/// leaving a tile held down. That trades the ripple for the dip, which is the
/// better half of the pair on a tile the size of a card — a ripple under a
/// finger is mostly hidden, a scale is not.
class AppPress extends StatefulWidget {
  const AppPress({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.92,
  });

  final Widget child;

  /// Null leaves the block inert — no dip, no tap.
  final VoidCallback? onTap;

  /// How far down the press goes. Deep enough to be seen at arm's length in
  /// sunlight; a 0.98 dip reads as nothing happening.
  final double scale;

  @override
  State<AppPress> createState() => _AppPressState();
}

class _AppPressState extends State<AppPress> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    final still = MediaQuery.disableAnimationsOf(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        // Down fast, back slowly with an overshoot: the press should feel
        // answered on contact and settle on release.
        duration: still
            ? Duration.zero
            : Duration(milliseconds: _down ? 90 : 260),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
