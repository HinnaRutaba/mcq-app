import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../models/unit_card.dart';

/// Search across every unit on the register, not only the defaulters.
///
/// A shop that is fully paid up never appears in the defaulter list, and it is
/// exactly the one the officer is standing in front of — so this is the list
/// behind the search box, and the only one that includes vacant units.
abstract class UnitsRepository {
  /// [search] matches a shop number, a property code, a holder's name or their
  /// CNIC. Vacant units are included, with their tenancy fields null.
  Future<List<UnitCard>> units({int? areaId, String? search, int? limit});
}

class ApiUnitsRepository implements UnitsRepository {
  ApiUnitsRepository({required this._api});

  final ApiService _api;

  @override
  Future<List<UnitCard>> units({int? areaId, String? search, int? limit}) async {
    final response = await _api.get(
      ApiPaths.units,
      query: <String, dynamic>{
        'area_id': areaId,
        'search': search,
        'limit': limit,
      },
    );
    return response.dataList.map(UnitCard.fromJson).toList();
  }
}
