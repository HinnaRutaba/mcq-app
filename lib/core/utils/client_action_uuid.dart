import 'dart:math';

/// Generates the `client_action_uuid` that accompanies every field write.
///
/// The server keys idempotency off this value: resending a visit, a fine or a
/// seal with the same uuid records it once, which is what makes a retry on a
/// weak signal safe instead of a second fine. So generate it **once**, when
/// the officer commits the action, and reuse that exact value on every retry —
/// never regenerate inside a retry loop.
///
/// The API accepts `^[A-Za-z0-9_\-]{8,64}$`; this emits 32 lowercase hex
/// characters, matching the shape the API examples use.
class ClientActionUuid {
  ClientActionUuid._();

  static final Random _random = Random.secure();

  static String generate({int bytes = 16}) {
    final buffer = StringBuffer();
    for (var i = 0; i < bytes; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// A dashed v4 UUID, for the agreement acts' `client_uuid`. Same rule:
  /// one per tap, reused on every retry of that tap.
  static String v4() {
    final List<int> b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final String hex = b
        .map((int x) => x.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
