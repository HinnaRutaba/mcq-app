import 'package:url_launcher/url_launcher.dart';

/// Hands a number to the handset's dialler, or to its messaging app.
///
/// The officer is standing in a bazaar with a shop's holder not in it; the
/// number on the card is worth nothing unless it can be pressed. Nothing is
/// sent without them confirming it — both schemes open the app with the
/// number in it, neither places a call or sends a message.
class Dialer {
  const Dialer();

  /// True when the dialler opened. False when the platform refused it, which
  /// is the case on a tablet with no telephony.
  Future<bool> call(String mobileNo) => _open('tel', mobileNo);

  /// Opens the messaging app on the number, with nothing written in it: what
  /// an officer says to a shopkeeper is theirs to write, and a canned demand
  /// from an app is not a notice.
  Future<bool> message(String mobileNo) => _open('sms', mobileNo);

  Future<bool> _open(String scheme, String mobileNo) {
    // Spaces and dashes as the register holds them ("0300 123-4504") are not
    // part of a `tel:` or `sms:` number.
    final String digits = mobileNo.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return Future<bool>.value(false);
    return launchUrl(Uri(scheme: scheme, path: digits));
  }
}
