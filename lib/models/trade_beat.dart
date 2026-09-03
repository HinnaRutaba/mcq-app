import '../core/utils/json_parse.dart';
import 'field_beat.dart';

/// The licensing home screen — the same shape as the enforcement beat, minus
/// the officer block and the money.
///
/// Show [FieldScope.areaNames]: these queues cover the officer's own bazaars,
/// and [TradeBeat] carries no city-wide figure to fall back on. Route each
/// tile from [FieldQueue.endpoint] rather than matching its key against a
/// hard-coded path.
class TradeBeat {
  const TradeBeat({
    required this.scope,
    this.queues = const <FieldQueue>[],
    this.generatedAt,
  });

  /// The bazaars these counts cover. Reuses the enforcement scope: the payload
  /// is the same block with fewer keys, and the names are derived from
  /// `areas` when the server does not send them separately.
  final FieldScope scope;

  /// Known keys: `expiring`, `lapsed`, `live`. Every queue here is
  /// [FieldQueue.areaScoped]; none carries an amount.
  final List<FieldQueue> queues;

  final DateTime? generatedAt;

  factory TradeBeat.fromJson(Map<String, dynamic> json) => TradeBeat(
    scope: FieldScope.fromJson(Json.map(json['scope'])),
    queues: Json.list(json['queues']).map(FieldQueue.fromJson).toList(),
    generatedAt: Json.dateTime(json['generated_at']),
  );

  FieldQueue? queue(String key) {
    for (final queue in queues) {
      if (queue.key == key) return queue;
    }
    return null;
  }
}
