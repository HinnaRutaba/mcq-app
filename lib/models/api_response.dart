import '../core/utils/json_parse.dart';

/// The success envelope every endpoint returns: `{"data": …, "message": "…"}`.
///
/// [data] is whatever sat under `data` — a map on a single resource, a list on
/// a collection. Repositories read it through [dataMap] / [dataList] and map it
/// onto a model; nothing above the data layer sees this class's raw shape.
class ApiResponse {
  const ApiResponse({this.data, this.message, this.meta, this.statusCode});

  final Object? data;

  /// The server's own wording for what happened, e.g. "Fine imposed and
  /// payable. The allottee has been told." Show this rather than inventing a
  /// confirmation of your own.
  final String? message;

  /// Pagination block, present on the paged collections. See [PageMeta].
  final Map<String, dynamic>? meta;

  final int? statusCode;

  /// Unwraps a decoded JSON body. A body with no `data` key is taken whole, so
  /// an endpoint that answers with a bare object still parses.
  factory ApiResponse.fromBody(Object? body, {int? statusCode}) {
    if (body is Map) {
      final json = Map<String, dynamic>.from(body);
      return ApiResponse(
        data: json.containsKey('data') ? json['data'] : json,
        message: Json.string(json['message']),
        meta: Json.mapOrNull(json['meta']),
        statusCode: statusCode,
      );
    }
    return ApiResponse(data: body, statusCode: statusCode);
  }

  Map<String, dynamic> get dataMap => Json.map(data);

  List<Map<String, dynamic>> get dataList => Json.list(data);
}

/// A `data` + `meta` collection, e.g. `enforcement/cases` and
/// `billing/challans`.
class Paginated<T> {
  const Paginated({required this.items, required this.meta});

  final List<T> items;
  final PageMeta meta;

  factory Paginated.fromResponse(
    ApiResponse response,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) => Paginated<T>(
    items: response.dataList.map(itemFromJson).toList(),
    meta: PageMeta.fromJson(response.meta ?? const <String, dynamic>{}),
  );

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Whether another page exists — ask this before requesting `page + 1`.
  bool get hasMore => meta.currentPage < meta.lastPage;

  int? get nextPage => hasMore ? meta.currentPage + 1 : null;
}

class PageMeta {
  const PageMeta({
    this.currentPage = 1,
    this.perPage = 0,
    this.lastPage = 1,
    this.total = 0,
    this.from,
    this.to,
  });

  final int currentPage;
  final int perPage;
  final int lastPage;
  final int total;

  /// 1-based index of the first and last row on this page; both null when the
  /// page is empty.
  final int? from;
  final int? to;

  factory PageMeta.fromJson(Map<String, dynamic> json) => PageMeta(
    currentPage: Json.integerOr(json['current_page'], 1),
    perPage: Json.integerOr(json['per_page']),
    lastPage: Json.integerOr(json['last_page'], 1),
    total: Json.integerOr(json['total']),
    from: Json.integer(json['from']),
    to: Json.integer(json['to']),
  );
}
