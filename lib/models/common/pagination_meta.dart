/// The `meta` block every paginated list endpoint returns.
class PaginationMeta {
  const PaginationMeta({
    required this.currentPage,
    required this.perPage,
    required this.lastPage,
    required this.total,
    this.from,
    this.to,
  });

  final int currentPage;
  final int perPage;
  final int lastPage;
  final int total;
  final int? from;
  final int? to;

  static const PaginationMeta single = PaginationMeta(
    currentPage: 1,
    perPage: 0,
    lastPage: 1,
    total: 0,
  );

  factory PaginationMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return single;
    int intOf(String key, [int fallback = 0]) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      // Counts are safe to parse — the API computes them server-side.
      return int.tryParse('${value ?? ''}') ?? fallback;
    }

    return PaginationMeta(
      currentPage: intOf('current_page', 1),
      perPage: intOf('per_page', 25),
      lastPage: intOf('last_page', 1),
      total: intOf('total'),
      from: json['from'] == null ? null : intOf('from'),
      to: json['to'] == null ? null : intOf('to'),
    );
  }

  bool get hasMore => currentPage < lastPage;
}

/// A page of [T] plus its [meta] — what every list repository returns.
class Paginated<T> {
  const Paginated({required this.items, required this.meta});

  final List<T> items;
  final PaginationMeta meta;

  bool get isEmpty => items.isEmpty;
  bool get hasMore => meta.hasMore;

  Paginated<T> followedBy(Paginated<T> next) => Paginated<T>(
        items: [...items, ...next.items],
        meta: next.meta,
      );
}
