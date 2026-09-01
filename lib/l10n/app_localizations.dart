import 'package:flutter/material.dart';

import 'strings_en.dart';
import 'strings_ur.dart';

/// The two languages the app ships in. Urdu is a first-class target, not a
/// translation pass — see `AppLocale.isRtl` and [lineHeight].
enum AppLocale {
  en,
  ur;

  /// The value sent as `Accept-Language` and stored on the user record.
  String get code => name;

  Locale get locale => Locale(code);

  bool get isRtl => this == AppLocale.ur;

  /// Urdu needs a taller line height than Latin — Nastaliq ascenders and
  /// descenders collide otherwise. The web app uses ~1.85 against ~1.5.
  double get lineHeight => this == AppLocale.ur ? 1.85 : 1.5;

  /// The name of the language in the language itself.
  String get nativeLabel => this == AppLocale.ur ? 'اردو' : 'English';

  static AppLocale fromCode(String? code) {
    return AppLocale.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLocale.en,
    );
  }
}

/// Translation lookup.
///
/// Every string the app itself renders goes through [t] — a hardcoded
/// English literal in a widget is a screen a Quetta officer cannot read.
/// Strings that come *from the server* (enum labels, validation messages,
/// domain refusals) are already translated by the API and must be shown
/// verbatim; never pass one through here.
///
/// This is deliberately a plain map lookup rather than generated ARB
/// bindings: it needs no build step, and controllers (not just widgets)
/// need translations, so a `BuildContext`-only API would not do.
class AppTranslations {
  AppTranslations._();

  static const Map<AppLocale, Map<String, String>> _tables = {
    AppLocale.en: stringsEn,
    AppLocale.ur: stringsUr,
  };

  static AppLocale _active = AppLocale.en;

  static AppLocale get active => _active;

  /// The table for [locale], for lookups that must not assert on a miss.
  static Map<String, String> tableFor(AppLocale locale) =>
      _tables[locale] ?? stringsEn;

  /// Set by `LocaleController` — the single place the active language changes.
  static void use(AppLocale locale) => _active = locale;

  static String lookup(String key, {Map<String, String>? args}) {
    final table = _tables[_active] ?? stringsEn;
    var value = table[key] ?? stringsEn[key];
    if (value == null) {
      assert(false, 'Missing translation for "$key"');
      return key;
    }
    if (args != null) {
      args.forEach((name, replacement) {
        value = value!.replaceAll('{$name}', replacement);
      });
    }
    return value!;
  }

  /// Every key present in English must exist in Urdu too. Asserted in
  /// debug and covered by a test, so a new screen cannot ship half
  /// translated.
  static List<String> missingKeys(AppLocale locale) {
    final table = _tables[locale] ?? const {};
    return stringsEn.keys.where((key) => !table.containsKey(key)).toList();
  }
}

/// Shorthand for [AppTranslations.lookup].
String t(String key, {Map<String, String>? args}) =>
    AppTranslations.lookup(key, args: args);

/// A label for a server-side enum value the app carries its own words for.
///
/// Two enums have no options endpoint — `action_type` and
/// `inspection_type` — so the app holds their labels, which makes it a
/// second source of truth. Unlike [t] this does **not** assert on a miss:
/// a value MCQ adds next month must render as itself on the handsets
/// already in the field rather than as a debug failure. See QUESTIONS.md.
String tEnum(String group, String value, {String? fallback}) {
  if (value.isEmpty) return fallback ?? '';
  final key = '$group.$value';
  final table = AppTranslations.tableFor(AppTranslations.active);
  return table[key] ?? stringsEn[key] ?? fallback ?? value;
}

/// Urdu, like English, has exactly two plural categories — one and other.
/// Do not copy Arabic's six; a plurals file lifted from an Arabic example
/// is wrong here.
String tPlural({
  required String one,
  required String other,
  required int count,
  Map<String, String>? args,
}) {
  final merged = {'count': '$count', ...?args};
  return AppTranslations.lookup(count == 1 ? one : other, args: merged);
}

/// Installs Material/Cupertino/Widgets localizations for `en` and `ur`, and
/// keeps [AppTranslations] pointed at whatever locale the app resolved to.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocale> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocale.values.any((l) => l.code == locale.languageCode);

  @override
  Future<AppLocale> load(Locale locale) async {
    final resolved = AppLocale.fromCode(locale.languageCode);
    AppTranslations.use(resolved);
    return resolved;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocale> old) => false;
}
