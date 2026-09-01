import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/utils/json_reader.dart';
import '../../../models/location/posting.dart';

/// The `/location` module: the officer's postings, and the areas of Quetta.
class LocationRepository {
  LocationRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// `GET /location/postings?user_id={me}` — the assignments that give this
  /// officer authority over an area.
  Future<List<Posting>> postings({required int userId}) async {
    final envelope = await _client.get(
      ApiConstants.postings,
      query: {ApiConstants.qUserId: userId},
    );
    return envelope.list
        .whereType<Map<String, dynamic>>()
        .map(Posting.fromJson)
        .toList();
  }

  /// Areas, for display only. The officer's scope is a server control; this
  /// is never used to build a client-side filter that pretends to be one.
  Future<List<String>> areaNames() async {
    final envelope = await _client.get(ApiConstants.areas);
    return envelope.list
        .whereType<Map<String, dynamic>>()
        .map((json) => json.strOr('name'))
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
