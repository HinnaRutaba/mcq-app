import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../models/api_response.dart';
import '../../models/challan.dart';

/// Challans — what the shopkeeper actually pays.
///
/// Note the spelling: this is the API's `challan`, and it is not the mock
/// `Chalaan` behind the existing screens.
abstract class ChallanRepository {
  /// The challan list, paged. [challanType] narrows it — pass [typeFine] for
  /// penalties only.
  ///
  /// When a row's `isSingleCharge` is true, draw one charge with one label: it
  /// is a fine, not a month's rent with arrears and surcharge. And never sum a
  /// rent challan's balance with a fine challan's — separate debts, separate
  /// links.
  Future<Paginated<Challan>> challans({
    int? page,
    int? perPage,
    String? challanType,
  });

  /// The `challan_type` filter for penalties. The server's full enum is not
  /// published, so the filter stays a string.
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
