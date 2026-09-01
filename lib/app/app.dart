import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import '../config/routes/app_router.dart';
import '../config/theme/app_text_theme_locale.dart';
import '../config/theme/app_theme.dart';
import '../controllers/api/locale_controller.dart';
import '../controllers/theme_controller.dart';
import '../core/utils/app_feedback.dart';
import '../l10n/app_localizations.dart';

/// Root widget: theming, language, layout direction, and routing.
///
/// Language is not a late pass here. It decides the text theme (Urdu needs a
/// taller line height and a face that draws Nastaliq), the layout direction
/// of the entire tree, and — through the Dio interceptor reading the same
/// setting — which language the server answers in.
class McqApp extends StatelessWidget {
  const McqApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final localeController = Get.find<LocaleController>();

    return Obx(() {
      final locale = localeController.locale.value;
      // The officer's own large-text setting, applied on top of whatever
      // the operating system already does. Some officers are older than the
      // accessibility settings they have never been shown.
      final textScale = themeController.textScale.value;

      return MaterialApp.router(
        onGenerateTitle: (context) => t('app.name'),
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: AppFeedback.messengerKey,

        locale: locale.locale,
        supportedLocales: [for (final option in AppLocale.values) option.locale],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // The localised scale is handed *into* the theme rather than
        // pasted over it, so the component themes that embed a text style
        // — the app bar title, a navigation label, a chip caption, a
        // dialog heading — are built from Urdu's face and line height too,
        // instead of keeping the Latin fallback under an Urdu body.
        theme: AppTheme.build(
          Brightness.light,
          textTheme: LocalisedTextTheme.of(
            locale,
            Brightness.light,
            factor: textScale,
          ),
        ),
        darkTheme: AppTheme.build(
          Brightness.dark,
          textTheme: LocalisedTextTheme.of(
            locale,
            Brightness.dark,
            factor: textScale,
          ),
        ),
        themeMode: themeController.themeMode.value,
        routerConfig: appRouter,

        // Every screen is laid out in the direction of the chosen language.
        // RTL is a layout problem, not a text problem — which is why the
        // widgets use EdgeInsetsDirectional and start/end throughout rather
        // than left/right.
        builder: (context, child) => Directionality(
          textDirection:
              locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        ),
      );
    });
  }
}
