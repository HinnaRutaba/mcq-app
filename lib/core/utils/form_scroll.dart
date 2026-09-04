import 'package:flutter/material.dart';

/// Moving a long form to whatever the officer has to deal with.
///
/// The button is in the bottom bar and the form runs well above it, so an
/// officer who presses Send at the foot of it never sees what the press turned
/// up. These carry the form to it instead of turning it into a toast that
/// slides away while they are standing in front of a shopkeeper.
extension RevealBanner on ScrollController {
  /// Animates to the top of the list, where a block that needs a decision
  /// sits. Safe to call before the list has been laid out — an unattached
  /// controller has nothing to move.
  void revealBanner() {
    if (!hasClients) return;
    animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}

/// Scrolls to the first field on the form carrying an error, and says whether
/// it found one.
///
/// `FormState` will not say *which* field failed, so the form's own subtree is
/// walked instead and the first `FormField` holding an error wins. The walk is
/// depth-first, so "first" means topmost on the form rather than first to have
/// been validated — which is the one the officer should be taken to.
bool scrollToFirstError(GlobalKey<FormState> formKey) {
  final BuildContext? form = formKey.currentContext;
  if (form == null) return false;

  Element? failed;
  void visit(Element element) {
    if (failed != null) return;
    if (element is StatefulElement && element.state is FormFieldState) {
      if ((element.state as FormFieldState<dynamic>).hasError) {
        failed = element;
        return;
      }
    }
    element.visitChildren(visit);
  }

  form.visitChildElements(visit);
  final Element? target = failed;
  if (target == null) return false;

  // Short of the top edge, not flush against it: a field pinned to the very
  // top of the viewport hides the label that says what it is.
  Scrollable.ensureVisible(
    target,
    alignment: 0.15,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );
  return true;
}
