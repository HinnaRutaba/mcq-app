import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../widgets/widgets.dart';

/// The search action on Home's header, beside the bell. Pressed, it grows into
/// the Find page.
///
/// A circle rather than a box with a hint in it: nothing is typed here. The
/// typing, the call and the rows all belong to the page this opens — and the
/// page grows out of this very circle, so the press is carried through rather
/// than replaced by a screen sliding in.
class HomeSearchButton extends StatefulWidget {
  const HomeSearchButton({super.key});

  @override
  State<HomeSearchButton> createState() => _HomeSearchButtonState();
}

class _HomeSearchButtonState extends State<HomeSearchButton> {
  /// Read at the press for the rectangle the circle is drawn at — the page is
  /// clipped out of it.
  final GlobalKey _circle = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return AppSearchHero(
      child: AppCircleIconButton(
        key: _circle,
        icon: Icons.search_rounded,
        // Null where the key holds nothing — a circle that has been rebuilt
        // away, or a test that never drew one — and the page grows out of the
        // top of the screen instead.
        onTap: () => context.push(
          AppRoutes.unitSearch,
          extra: AppContainerPage.rectOf(_circle),
        ),
      ),
    );
  }
}
