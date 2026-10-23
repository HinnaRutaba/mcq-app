import 'package:flutter/widgets.dart';

/// The layout class the current window falls into.
enum ScreenType {
  mobile,
  tablet,
  desktop;

  /// Width at or above which a window is laid out as desktop.
  static const double desktopMinWidth = 1200;

  /// Shortest side at or above which a window is laid out as tablet. The
  /// shortest side, so a phone turned landscape stays a phone.
  static const double tabletMinShortestSide = 600;

  static ScreenType fromSize(Size size) {
    if (size.width >= desktopMinWidth) return ScreenType.desktop;
    if (size.shortestSide >= tabletMinShortestSide) return ScreenType.tablet;
    return ScreenType.mobile;
  }
}

/// `context.screenType`, `context.isTablet`, `context.responsive(...)`.
///
/// Reads `MediaQuery.sizeOf`, so the widget rebuilds only when the window
/// size changes.
extension ScreenTypeContext on BuildContext {
  ScreenType get screenType => ScreenType.fromSize(MediaQuery.sizeOf(this));

  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;

  /// Picks a value per screen type; a missing one falls back to the next
  /// smaller size, then to [mobile].
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    return switch (screenType) {
      ScreenType.mobile => mobile,
      ScreenType.tablet => tablet ?? mobile,
      ScreenType.desktop => desktop ?? tablet ?? mobile,
    };
  }
}
