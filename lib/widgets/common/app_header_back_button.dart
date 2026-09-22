import 'package:flutter/material.dart';

/// The back arrow on a hero header, sized to the title line it rides on.
///
/// Bare rather than a filled circle: on a sliver header anything taller than
/// the title sets the row height itself and pushes the whole gradient down.
class AppHeaderBackButton extends StatelessWidget {
  const AppHeaderBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // `titleLarge` is the style `AppHeroHeader` draws its title in, so the
    // arrow rides in space the block already occupies.
    final TextStyle? title = Theme.of(context).textTheme.titleLarge;
    final double line = (title?.fontSize ?? 18) * (title?.height ?? 1.3);

    return InkResponse(
      onTap: onTap,
      radius: line,
      // Wider than the glyph on purpose: width is free here — only height
      // feeds back into the header — so the target takes what it can get.
      child: SizedBox(
        height: line,
        width: 32,
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
