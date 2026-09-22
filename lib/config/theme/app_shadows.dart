import 'package:flutter/material.dart';

/// The app's depth, as shadow rather than as a Material elevation step.
///
/// Two levels and nothing between them: [soft] lifts an ordinary card off the
/// page, [lifted] is for the one block on a screen that should read as raised.
///
/// Dark mode gets its own values rather than the light ones at more alpha — a
/// wide blur on near-black is invisible, so the depth there comes from a
/// tighter, denser shadow under a card that is already lighter than the page.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _softDark : _softLight;

  static List<BoxShadow> lifted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _liftedDark
      : _liftedLight;

  static const List<BoxShadow> _softLight = <BoxShadow>[
    BoxShadow(
      color: Color(0x14101B14),
      blurRadius: 16,
      offset: Offset(0, 6),
      spreadRadius: -6,
    ),
    BoxShadow(color: Color(0x0D101B14), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> _liftedLight = <BoxShadow>[
    BoxShadow(
      color: Color(0x24101B14),
      blurRadius: 28,
      offset: Offset(0, 14),
      spreadRadius: -10,
    ),
    BoxShadow(color: Color(0x14101B14), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> _softDark = <BoxShadow>[
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 10,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> _liftedDark = <BoxShadow>[
    BoxShadow(
      color: Color(0x8A000000),
      blurRadius: 20,
      offset: Offset(0, 10),
      spreadRadius: -8,
    ),
  ];
}
