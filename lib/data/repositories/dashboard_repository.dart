import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../models/field_activity.dart';
import '../../models/field_beat.dart';

/// The home screen: the officer's beat and their own recent work.
abstract class DashboardRepository {
  /// One call draws the whole home screen — the officer, the bazaars they are
  /// posted to, and the work queues.
  ///
  /// `FieldBeat.scope.areaNames` must reach the screen: the figures cover those
  /// bazaars only, and a reader who cannot see which ones will take them for
  /// city-wide totals.
  Future<FieldBeat> beat();

  /// The officer's own work over the last [days].
  Future<FieldActivity> activity({int days});
}

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository({required this._api});

  final ApiService _api;

  @override
  Future<FieldBeat> beat() async {
    final response = await _api.get(ApiPaths.beat);
    return FieldBeat.fromJson(response.dataMap);
  }

  @override
  Future<FieldActivity> activity({int days = 30}) async {
    final response = await _api.get(
      ApiPaths.activity,
      query: <String, dynamic>{'days': days},
    );
    return FieldActivity.fromJson(response.dataMap);
  }
}
