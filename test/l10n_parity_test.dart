import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_app/l10n/app_localizations.dart';
import 'package:mcq_app/l10n/strings_en.dart';
import 'package:mcq_app/l10n/strings_ur.dart';

/// Urdu is a first-class language here, not a translation pass at the end.
/// A key that exists only in English is a screen a Quetta officer cannot
/// read, so it fails the build rather than shipping.
void main() {
  test('every English key exists in Urdu', () {
    expect(AppTranslations.missingKeys(AppLocale.ur), isEmpty);
  });

  test('Urdu carries no key English does not', () {
    final extra = stringsUr.keys.where((key) => !stringsEn.containsKey(key));
    expect(extra, isEmpty);
  });

  test('placeholders match between the two tables', () {
    final pattern = RegExp(r'\{(\w+)\}');
    final mismatched = <String>[];

    for (final entry in stringsEn.entries) {
      final english = pattern
          .allMatches(entry.value)
          .map((match) => match.group(1)!)
          .toSet();
      final urdu = pattern
          .allMatches(stringsUr[entry.key] ?? '')
          .map((match) => match.group(1)!)
          .toSet();
      if (english.length != urdu.length || !english.containsAll(urdu)) {
        mismatched.add(entry.key);
      }
    }

    expect(mismatched, isEmpty, reason: 'placeholders differ: $mismatched');
  });

  test('digits stay Western in Urdu', () {
    // Eastern Arabic numerals would break the alignment of a column of
    // figures, and are not the Pakistani software norm.
    final easternDigits = RegExp(r'[٠-٩۰-۹]');
    final offenders = stringsUr.entries
        .where((entry) => easternDigits.hasMatch(entry.value))
        .map((entry) => entry.key);
    expect(offenders, isEmpty);
  });

  test('t() falls back to English rather than rendering a key', () {
    AppTranslations.use(AppLocale.ur);
    expect(t('app.name'), stringsUr['app.name']);
    AppTranslations.use(AppLocale.en);
    expect(t('app.name'), stringsEn['app.name']);
  });

  test('t() substitutes named arguments', () {
    AppTranslations.use(AppLocale.en);
    expect(
      t('defaulters.behind', args: {'count': '5'}),
      contains('5'),
    );
  });

  test('plurals use two categories, as both languages do', () {
    AppTranslations.use(AppLocale.en);
    expect(
      tPlural(one: 'defaulters.behindOne', other: 'defaulters.behind', count: 1),
      stringsEn['defaulters.behindOne'],
    );
    expect(
      tPlural(one: 'defaulters.behindOne', other: 'defaulters.behind', count: 5),
      contains('5'),
    );
  });
}
