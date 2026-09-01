import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../models/map_pins.dart';
import '../../models/property_profile.dart';

/// The shopkeeper profile, and the map of the officer's bazaars.
abstract class ReportingRepository {
  /// The full profile of one unit: holder, money position, seal, open cases.
  ///
  /// Opened from a card, so draw the header from the card already in hand and
  /// let this fill in the rest — the officer should not be looking at an empty
  /// screen while it loads.
  Future<PropertyProfile> propertyProfile(int propertyId);

  /// Map pins for the officer's bazaars.
  ///
  /// Check `MapPins.meta.truncated` and `meta.unmapped` before letting the map
  /// imply it is showing everything: units without coordinates cannot be
  /// pinned, and a large scope gets cut off at [limit].
  Future<MapPins> mapPins({bool defaultersOnly, int? limit});
}

class ApiReportingRepository implements ReportingRepository {
  ApiReportingRepository({required this._api});

  final ApiService _api;

  @override
  Future<PropertyProfile> propertyProfile(int propertyId) async {
    final response = await _api.get(ApiPaths.propertyProfile(propertyId));
    return PropertyProfile.fromJson(response.dataMap);
  }

  @override
  Future<MapPins> mapPins({bool defaultersOnly = false, int? limit}) async {
    final response = await _api.get(
      ApiPaths.map,
      query: <String, dynamic>{
        'defaulters_only': defaultersOnly ? 1 : null,
        'limit': limit,
      },
    );
    // `pins` and `meta` both sit inside `data` on this endpoint, rather than
    // `meta` sitting beside it as on the paged collections.
    return MapPins.fromJson(response.dataMap);
  }
}
