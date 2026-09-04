import 'package:flutter/material.dart';

/// Bringing a form's error banner back into view.
///
/// The submit button sits in the bottom bar and the banner sits at the top of
/// the list, so an officer who presses Send at the foot of a long form is told
/// nothing: the server's sentence lands off-screen behind them. Scrolling back
/// to it is what makes a refusal visible without turning it into a toast that
/// slides away while they are standing in front of a shopkeeper.
extension RevealBanner on ScrollController {
  /// Animates to the top of the list, where the banner is. Safe to call before
  /// the list has been laid out — an unattached controller has nothing to move.
  void revealBanner() {
    if (!hasClients) return;
    animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}
