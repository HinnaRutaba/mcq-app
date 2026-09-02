/// The app's corner radii. Six steps and nothing between them.
///
/// Pick by the size of the thing being rounded, not by eye: a radius chosen
/// per widget is how the app ended up with fifteen of them.
class AppRadius {
  AppRadius._();

  /// Marks inside a chart, a progress track, a checkbox.
  static const double xs = 6;

  /// Small controls and inline plates — a swatch, a thumbnail, a chart body.
  static const double sm = 10;

  /// The default. Cards, buttons, fields, tiles, alerts.
  static const double md = 14;

  /// Large pressables and icon plates — the create button, a quick action.
  static const double lg = 20;

  /// The biggest surfaces: the hero header's lip, a bottom sheet, the splash
  /// mark. Also what the bar's notch comes out at, being [lg] plus its margin.
  static const double xl = 28;

  /// Stadium — pills and badges, where the shape is the point.
  static const double pill = 999;
}
