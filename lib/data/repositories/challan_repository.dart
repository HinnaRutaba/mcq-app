import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../models/api_response.dart';
import '../../models/challan.dart';


abstract class ChallanRepository {

  Future<Paginated<Challan>> challans({
    int? page,
    int? perPage,
    String? challanType,
  });


  static const String typeFine = 'fine';
}

class ApiChallanRepository implements ChallanRepository {
  ApiChallanRepository({required this._api});

  final ApiService _api;

  @override
  Future<Paginated<Challan>> challans({
    int? page,
    int? perPage,
    String? challanType,
  }) async {
    final response = await _api.get(
      ApiPaths.challans,
      query: <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'challan_type': challanType,
      },
    );
    return Paginated<Challan>.fromResponse(response, Challan.fromJson);
  }
}
