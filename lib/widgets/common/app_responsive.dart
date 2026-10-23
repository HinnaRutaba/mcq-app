import 'package:flutter/widgets.dart';

import '../../core/utils/screen_type.dart';

/// Builds a different layout per [ScreenType].
///
/// A missing [tablet] or [desktop] falls back to the next smaller layout.
/// Only the chosen builder runs. Classifies by the window size; set
/// [useConstraints] to classify by the space this widget is given instead,
/// e.g. inside a side panel.
class AppResponsive extends StatelessWidget {
  const AppResponsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.useConstraints = false,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;
  final bool useConstraints;

  @override
  Widget build(BuildContext context) {
    if (!useConstraints) return _build(context, context.screenType);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          _build(context, ScreenType.fromSize(constraints.biggest)),
    );
  }

  Widget _build(BuildContext context, ScreenType type) {
    final WidgetBuilder builder = switch (type) {
      ScreenType.mobile => mobile,
      ScreenType.tablet => tablet ?? mobile,
      ScreenType.desktop => desktop ?? tablet ?? mobile,
    };
    return builder(context);
  }
}
