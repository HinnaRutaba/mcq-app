import 'package:url_launcher/url_launcher.dart';

import '../../models/api_refs.dart';

/// Opens where a unit stands in whatever map app the handset has.
///
/// A fix when the register holds one, so the pin lands on the shop itself; the
/// printed address otherwise, which gets the officer to the bazaar and leaves
/// the last few yards to them. Google's universal maps URL either way — the
/// installed app claims it on both platforms, and a handset without one falls
/// back to the browser.
class MapLauncher {
  const MapLauncher();

  /// True when a map opened. False when there was nothing to open it on, or
  /// the platform refused.
  Future<bool> open({GeoPoint? point, String? address}) {
    final Uri? target = targetFor(point: point, address: address);
    if (target == null) return Future<bool>.value(false);
    // Out to the map app, not an in-app view: what the officer wants next is
    // walking directions from where they are standing.
    return launchUrl(target, mode: LaunchMode.externalApplication);
  }

  /// The URL a press would open, or null when there is nothing to open one
  /// on. Public so it can be asserted without a platform to launch it.
  static Uri? targetFor({GeoPoint? point, String? address}) {
    final String query;
    if (point != null && point.hasFix) {
      query = '${point.latitudeValue},${point.longitudeValue}';
    } else {
      query = address?.trim() ?? '';
      if (query.isEmpty) return null;
    }
    return Uri.https('www.google.com', '/maps/search/', <String, String>{
      'api': '1',
      'query': query,
    });
  }
}
