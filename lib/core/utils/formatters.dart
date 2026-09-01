import 'package:intl/intl.dart';

/// Shared formatting helpers — use these instead of ad hoc `NumberFormat`/
/// `DateFormat` calls scattered around the app.
class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  static final DateFormat _date = DateFormat('d MMM yyyy');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, h:mm a');
  static final DateFormat _month = DateFormat('MMM');
  static final DateFormat _stamp = DateFormat('d MMM, h:mm a');
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  /// Formats a number as currency.
  ///
  /// **Not for API amounts.** Money from the server is a `String` and is
  /// never parsed — render it with `MoneyText`/`Money.format()`. This
  /// remains only for the demo screens that predate the API layer.
  static String currency(num amount) => _currency.format(amount);

  static String date(DateTime date) => _date.format(date);

  static String dateTime(DateTime date) => _dateTime.format(date);

  static String month(DateTime date) => _month.format(date);

  /// "12 Aug, 9:41 AM" — the stamp beside a cached figure, so it never
  /// looks live.
  static String stamp(DateTime date) => _stamp.format(date);

  /// The date format the API expects on a write.
  static String apiDate(DateTime date) => _apiDate.format(date);

  /// Human "days left/overdue" phrasing for a due date, e.g. "Due in 3
  /// days" / "3 days overdue" / "Due today".
  static String dueIn(DateTime dueDate) {
    final today = DateTime.now();
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final now = DateTime(today.year, today.month, today.day);
    final days = due.difference(now).inDays;

    if (days == 0) return 'Due today';
    if (days > 0) return 'Due in $days day${days == 1 ? '' : 's'}';
    final overdue = -days;
    return '$overdue day${overdue == 1 ? '' : 's'} overdue';
  }
}
