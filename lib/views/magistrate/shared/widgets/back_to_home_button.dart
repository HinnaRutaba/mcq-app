import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackToHomeButton extends StatelessWidget {
  const BackToHomeButton({super.key});

  /// Switches to the Home tab, keeping the tab being left standing where it
  /// was — [StatefulNavigationShellState.goBranch] restores a branch's own
  /// stack, so a list the officer had scrolled is still scrolled when they
  /// come back to it. `context.go` would rebuild it from the URL instead.
  ///
  /// [StatefulNavigationShell.maybeOf] rather than `of`: outside the shell —
  /// a widget preview, a test pumping one screen on its own — there is no tab
  /// to switch to, and asserting would break a harness that never taps this.
  static void goHome(BuildContext context) {
    StatefulNavigationShell.maybeOf(context)?.goBranch(homeBranch);
  }

  /// Home's index on the bar, and therefore its branch index in the router.
  /// The two lists are ordered by `MagistrateShell.entries`.
  static const int homeBranch = 0;

  @override
  Widget build(BuildContext context) {
    // Sized to the header's own title line — `titleLarge`, the style
    // `AppHeroHeader` draws the title in — so the arrow rides in space the
    // block already occupies. Anything taller sets the row height itself and
    // pushes the whole gradient header down, which a filled circle did.
    final TextStyle? title = Theme.of(context).textTheme.titleLarge;
    final double line = (title?.fontSize ?? 18) * (title?.height ?? 1.3);

    return InkResponse(
      onTap: () => goHome(context),
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
