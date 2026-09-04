import 'package:url_launcher/url_launcher.dart';

import '../../models/api_refs.dart';

class MapLauncher {
  const MapLauncher();

  Future<bool> open({GeoPoint? point, String? address}) {
    final Uri? target = targetFor(point: point, address: address);
    if (target == null) return Future<bool>.value(false);

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
