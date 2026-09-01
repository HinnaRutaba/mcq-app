import 'package:get/get.dart';

import '../../core/storage/key_value_store.dart';
import '../../l10n/app_localizations.dart';

/// The active language.
///
/// The officer's own `locale` on the user record is the default; an
/// explicit choice in settings overrides it and is remembered on the
/// handset. Changing this rebuilds the whole app — the language decides
/// layout direction, not just words.
class LocaleController extends GetxController {
  LocaleController(this._store);

  final KeyValueStore _store;

  final Rx<AppLocale> locale = AppLocale.en.obs;

  /// Whether the officer has chosen a language themselves, in which case
  /// their user record's `locale` no longer overrides it.
  bool get hasExplicitChoice =>
      (_store.getString(KeyValueStore.localeKey) ?? '').isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    final stored = _store.getString(KeyValueStore.localeKey);
    _apply(AppLocale.fromCode(stored));
  }

  /// Follow the language on the officer's user record, unless they have
  /// already overridden it on this handset.
  void followUserPreference(String? code) {
    if (hasExplicitChoice || code == null) return;
    _apply(AppLocale.fromCode(code));
  }

  Future<void> use(AppLocale next) async {
    await _store.setString(KeyValueStore.localeKey, next.code);
    _apply(next);
  }

  void _apply(AppLocale next) {
    // AppTranslations is what `t()` reads, and the Dio interceptor reads
    // it too for `Accept-Language` — so this one line also decides which
    // language the server answers in.
    AppTranslations.use(next);
    locale.value = next;
    update();
  }

  bool get isRtl => locale.value.isRtl;
}
