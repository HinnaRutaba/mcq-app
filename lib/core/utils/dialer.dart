import 'package:url_launcher/url_launcher.dart';

/// Hands a number to the handset's dialler.
///
/// The officer is standing in a bazaar with a shop's holder not in it; the
/// number on the card is worth nothing unless it can be pressed. Nothing is
/// dialled without them confirming it — `tel:` opens the dialler with the
/// number in it, it does not place the call.
class Dialer {
  const Dialer();

  /// True when the dialler opened. False when the platform refused it, which
  /// is the case on a tablet with no telephony.
  Future<bool> call(String mobileNo) {
    // Spaces and dashes as the register holds them ("0300 123-4504") are not
    // part of a `tel:` number.
    final String digits = mobileNo.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return Future<bool>.value(false);
    return launchUrl(Uri(scheme: 'tel', path: digits));
  }
}
