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
}
