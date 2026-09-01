import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../models/defaulter_card.dart';
import '../../models/round_group.dart';

/// Which promises to show on the follow-ups list.
enum FollowUpState {
  /// Due today or already broken — the ones needing a visit now.
  due('due'),

  /// Promised for a date still ahead.
  upcoming('upcoming');

  const FollowUpState(this.wireValue);

  final String wireValue;
}

/// Who owes money, where to go today, and which promises have come due.
abstract class DefaultersRepository {
  /// Everyone behind on rent in the officer's bazaars, worst first.
  ///
  /// [neverPaid] narrows to the units that have never paid anything at all,
  /// which is a different problem from having fallen behind.
  Future<List<DefaulterCard>> defaulters({
    int? areaId,
    String? search,
    bool? neverPaid,
    int? limit,
  });

  /// The same defaulters grouped by bazaar, broken promises first, a handful of
  /// stops each — a walking order rather than a list.
  Future<List<RoundGroup>> round();

  /// Promises due or broken. Omit [state] for all of them.
  ///
  /// The published spec only ever captured this list empty; the rows are read
  /// as defaulter cards, which is the shape every other `field/*` list uses and
  /// which already carries `commitment` and `next_visit_date`.
  Future<List<DefaulterCard>> followUps({FollowUpState? state});
}

class ApiDefaultersRepository implements DefaultersRepository {
  ApiDefaultersRepository({required this._api});

  final ApiService _api;

  @override
  Future<List<DefaulterCard>> defaulters({
    int? areaId,
    String? search,
    bool? neverPaid,
    int? limit,
  }) async {
    final response = await _api.get(
      ApiPaths.defaulters,
      query: <String, dynamic>{
        'area_id': areaId,
        'search': search,
        // The API reads this flag as `never_paid=1`.
        'never_paid': neverPaid == true ? 1 : null,
        'limit': limit,
      },
    );
    return response.dataList.map(DefaulterCard.fromJson).toList();
  }

  @override
  Future<List<RoundGroup>> round() async {
    final response = await _api.get(ApiPaths.round);
    return response.dataList.map(RoundGroup.fromJson).toList();
  }

  @override
  Future<List<DefaulterCard>> followUps({FollowUpState? state}) async {
    final response = await _api.get(
      ApiPaths.followUps,
      query: <String, dynamic>{'state': state?.wireValue},
    );
    return response.dataList.map(DefaulterCard.fromJson).toList();
  }
}
