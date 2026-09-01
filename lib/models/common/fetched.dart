/// A value together with where it came from and when.
///
/// Every list and dashboard read is cached, and a cached figure must never
/// look live: [fromCache] drives the "showing data saved at …" banner and
/// [fetchedAt] fills in the stamp. A magistrate reading this morning's
/// defaulter list in a basement is useful; a spinner is not.
class Fetched<T> {
  const Fetched({
    required this.value,
    required this.fetchedAt,
    this.fromCache = false,
  });

  final T value;
  final DateTime fetchedAt;
  final bool fromCache;

  Fetched<R> map<R>(R Function(T value) transform) => Fetched<R>(
        value: transform(value),
        fetchedAt: fetchedAt,
        fromCache: fromCache,
      );
}
