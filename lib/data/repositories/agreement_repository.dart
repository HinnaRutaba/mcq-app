import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/json_parse.dart';
import '../../models/agreement_case.dart';
import '../../models/agreement_dashboard.dart';
import '../../models/agreement_requests.dart';
import '../../models/api_response.dart';

/// The agreement workspace: the CMO's and the Administrator's reviews.
///
/// A 403 here means "not yours to act on", not a dead session, so none of
/// these calls signs the officer out on one — a 401 still does.
abstract class AgreementRepository {
  Future<AgreementDashboard> dashboard({
    int? marketId,
    DateTime? from,
    DateTime? to,
  });

  Future<Paginated<AgreementCase>> cases(
    IntakeListQuery query, {
    String? search,
    int? marketId,
    int page = 1,
    int perPage = 25,
  });

  Future<AgreementCase> caseDetail(String id);

  /// Posts [option]'s act and answers the updated case.
  Future<AgreementCase> act(
    String caseId,
    IntakeActOption option,
    IntakeDecisionRequest request,
  );

  /// A document's bytes, streamed with the token. Kept in memory only.
  Future<ApiDownload> document(String url);
}

class ApiAgreementRepository implements AgreementRepository {
  ApiAgreementRepository({required this._api});

  final ApiService _api;

  @override
  Future<AgreementDashboard> dashboard({
    int? marketId,
    DateTime? from,
    DateTime? to,
  }) async {
    final ApiResponse response = await _api.get(
      ApiPaths.intakesDashboard,
      forbiddenEndsSession: false,
      query: <String, dynamic>{
        'market_id': marketId,
        'from': Json.dateOnly(from),
        'to': Json.dateOnly(to),
      },
    );
    return AgreementDashboard.fromJson(response.dataMap);
  }

  @override
  Future<Paginated<AgreementCase>> cases(
    IntakeListQuery query, {
    String? search,
    int? marketId,
    int page = 1,
    int perPage = 25,
  }) async {
    final ApiResponse response = await _api.get(
      ApiPaths.intakes,
      forbiddenEndsSession: false,
      query: <String, dynamic>{
        ...query.toQuery(search: search, page: page, perPage: perPage),
        'market_id': marketId,
      },
    );
    return Paginated<AgreementCase>.fromResponse(
      response,
      AgreementCase.fromJson,
    );
  }

  @override
  Future<AgreementCase> caseDetail(String id) async {
    final ApiResponse response = await _api.get(
      ApiPaths.intake(id),
      forbiddenEndsSession: false,
    );
    return AgreementCase.fromJson(response.dataMap);
  }

  @override
  Future<AgreementCase> act(
    String caseId,
    IntakeActOption option,
    IntakeDecisionRequest request,
  ) async {
    // The server's own path when it sent one; the documented one otherwise.
    final String path = option.path == null
        ? ApiPaths.intakeAct(caseId, option.act)
        : _local(option.path!);
    final ApiResponse response = await _api.post(
      path,
      forbiddenEndsSession: false,
      body: request.toJson(),
      files: request.files,
    );
    return AgreementCase.fromJson(response.dataMap);
  }

  @override
  Future<ApiDownload> document(String url) =>
      _api.download(_local(url), forbiddenEndsSession: false);

  /// An absolute or relative server URL, as a path on our own base URL — so
  /// the token never goes to a host the app was not built against.
  static String _local(String url) {
    final resolved = ApiPaths.resolve(url);
    return resolved.query.isEmpty
        ? resolved.path
        : Uri(
            path: resolved.path,
            queryParameters: resolved.query.map(
              (String k, dynamic v) => MapEntry<String, String>(k, '$v'),
            ),
          ).toString();
  }
}
