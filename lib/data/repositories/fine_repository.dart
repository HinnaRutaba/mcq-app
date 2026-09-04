import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../models/fine.dart';
import '../../models/fine_request.dart';

abstract class FineRepository {

  Future<Fine> impose({required int propertyId, required FineRequest request});

  Future<Fine> imposeInArea({required FineRequest request});
}

class ApiFineRepository implements FineRepository {
  ApiFineRepository({required this._api});

  final ApiService _api;

  @override
  Future<Fine> impose({
    required int propertyId,
    required FineRequest request,
  }) async {
    final response = await _api.post(
      ApiPaths.propertyFines(propertyId),
      body: request.toJson(),
    );
    return Fine.fromJson(response.dataMap);
  }

  @override
  Future<Fine> imposeInArea({required FineRequest request}) async {
    final response = await _api.post(ApiPaths.fines, body: request.toJson());
    return Fine.fromJson(response.dataMap);
  }
}
