import 'package:flutter/foundation.dart';

/// An amount of money, exactly as the server sent it.
///
/// The API keeps money in `decimal(14,2)` and sends it as a string —
/// `"2198409.10"` — precisely so no client can lose paisa in a
/// floating-point conversion. This type holds that string and never
/// converts it to a number.
///
/// There is **no `+` operator on this class and there must never be one.**
/// Every total, subtotal, share and percentage the app displays is computed
/// by the server. If a figure looks like it needs adding up on the device,
/// the endpoint that returns it probably already exists — and if it truly
/// does not, that is a backend request, not a client workaround.
@immutable
class Money {
  const Money(this.raw);

  /// Exactly as the server sent it: `"2198409.10"`. Never modified.
  final String raw;

  static const Money zero = Money('0.00');

  factory Money.fromJson(Object? value) {
    if (value == null) return Money.zero;
    if (value is String) return Money(value);
    // A number here means the API changed shape. Keep the digits rather
    // than throwing in a magistrate's hand, but make it loud in debug.
    assert(false, 'Money arrived as ${value.runtimeType}, expected String');
    return Money(value.toString());
  }

  String toJson() => raw;

  /// `"2,198,409.10"` — groups the integer part and appends the fraction
  /// verbatim.
  ///
  /// Deliberately string surgery. Parsing to a num and formatting is where
  /// paisa go missing, and this is a ledger.
  String format() {
    final negative = raw.startsWith('-');
    final body = negative ? raw.substring(1) : raw;

    final parts = body.split('.');
    final whole = parts.first.isEmpty ? '0' : parts.first;
    final fraction = parts.length > 1 ? parts[1] : '00';

    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
      buffer.write(whole[i]);
    }
    return '${negative ? '-' : ''}$buffer.$fraction';
  }

  /// `"Rs 2,198,409.10"`. Western digits in both languages — the Pakistani
  /// software norm, and it keeps figures aligned in a column.
  String withSymbol([String symbol = 'Rs']) => '$symbol ${format()}';

  /// Ordering only — **never** an amount.
  ///
  /// Returns a negative number if this is smaller than [other], zero if
  /// they are the same size, positive if larger. It exists so a list can
  /// be sorted and so a screen can say "this has come down" without
  /// inventing a figure for *by how much*.
  ///
  /// It parses, and that is exactly why nothing may be displayed from it.
  /// The moment a difference is shown to a shopkeeper it is a quoted
  /// figure, and a quoted figure comes from the server or not at all. If
  /// the app needs "paid ₨3,000 since promising", that is a field on the
  /// payload and a backend request — see QUESTIONS.md.
  int compareMagnitude(Money other) {
    final a = double.tryParse(raw) ?? 0;
    final b = double.tryParse(other.raw) ?? 0;
    return a.compareTo(b);
  }

  /// True when this is smaller than [other]. Same rule as
  /// [compareMagnitude]: a comparison, not an amount.
  bool isLessThan(Money other) => compareMagnitude(other) < 0;

  bool get isZero {
    final body = raw.startsWith('-') ? raw.substring(1) : raw;
    return RegExp(r'^0*(\.0*)?$').hasMatch(body);
  }

  @override
  bool operator ==(Object other) => other is Money && other.raw == raw;

  @override
  int get hashCode => raw.hashCode;

  @override
  String toString() => raw;
}
