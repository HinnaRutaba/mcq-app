import 'package:url_launcher/url_launcher.dart';

/// Placing a call from a row in a list.
///
/// A defaulter row's `mobile_no` is often the fastest enforcement action
/// there is — a reminder call costs nothing and settles some accounts
/// without a visit.
class Dialer {
  Dialer._();

  /// A text message, pre-addressed. Most recovery conversations in
  /// Pakistan happen on a phone rather than at a counter, and a reminder
  /// costs nothing.
  static Future<bool> sms(String? mobileNo, {String? body}) async {
    final number = _digits(mobileNo);
    if (number.isEmpty) return false;
    final uri = Uri(
      scheme: 'sms',
      path: number,
      queryParameters: body == null ? null : {'body': body},
    );
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  /// WhatsApp, where most of these conversations actually happen. Falls
  /// back to nothing rather than opening a browser the officer then has to
  /// close.
  static Future<bool> whatsApp(String? mobileNo, {String? message}) async {
    final number = _digits(mobileNo).replaceAll('+', '');
    if (number.isEmpty) return false;
    // Pakistani numbers are stored as 03xxxxxxxxx; WhatsApp wants the
    // country code.
    final international =
        number.startsWith('0') ? '92${number.substring(1)}' : number;
    final uri = Uri.parse(
      'https://wa.me/$international'
      '${message == null ? '' : '?text=${Uri.encodeComponent(message)}'}',
    );
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _digits(String? mobileNo) =>
      (mobileNo ?? '').replaceAll(RegExp(r'[^0-9+]'), '');

  static Future<bool> call(String? mobileNo) async {
    final number = (mobileNo ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) return false;
    final uri = Uri(scheme: 'tel', path: number);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }
}
