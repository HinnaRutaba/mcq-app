import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/widgets.dart';

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
    return AppHeaderBackButton(onTap: () => goHome(context));
  }
}
