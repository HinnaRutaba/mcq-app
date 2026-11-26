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

  static final NumberFormat _paise = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs ',
    decimalDigits: 2,
  );

  static final DateFormat _date = DateFormat('d MMM yyyy');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, h:mm a');
  static final DateFormat _month = DateFormat('MMM');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');

  static String currency(num amount) => _currency.format(amount);

  /// The API sends money as a decimal string ("2213409.10"), and it stays a
  /// string everywhere but here — never total two of them in Dart. This parses
  /// one only to print it, and hands back the raw text if it will not parse,
  /// so a figure is never silently dropped.
  static String? money(String? amount) {
    if (amount == null) return null;
    final trimmed = amount.trim();
    if (trimmed.isEmpty) return null;
    final value = num.tryParse(trimmed);
    return value == null ? trimmed : currency(value);
  }

  /// As [money], but paise are kept when there are any: "Rs 10,248.70".
  static String? moneyExact(String? amount) {
    final String? whole = money(amount);
    final num? value = num.tryParse(amount?.trim() ?? '');
    if (value == null || value == value.truncate()) return whole;
    return _paise.format(value);
  }

  static String date(DateTime date) => _date.format(date);

  static String dateTime(DateTime date) => _dateTime.format(date);

  static String month(DateTime date) => _month.format(date);

  /// "Nov 2026" — a billing period.
  static String monthYear(DateTime date) => _monthYear.format(date);

  /// The two largest units of a span: "3d 4h", "1h 20m", "45m", "33s".
  static String span(Duration d) {
    final List<String> parts = <String>[
      if (d.inDays > 0) '${d.inDays}d',
      if (d.inHours % 24 > 0) '${d.inHours % 24}h',
      if (d.inMinutes % 60 > 0) '${d.inMinutes % 60}m',
      if (d.inMinutes == 0) '${d.inSeconds}s',
    ];
    return parts.take(2).join(' ');
  }

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
