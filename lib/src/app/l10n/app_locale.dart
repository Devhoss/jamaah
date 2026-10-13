import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'arabic_digits_localizations.dart';
import 'generated/app_localizations.dart';

/// The languages the app speaks (Arabic added 2026-10-14).
///
/// Arabic is `ar_EG` so that Flutter's own widgets and intl format dates and
/// numbers with Arabic-Indic digits; see digits.dart. Any Arabic the phone asks
/// for (ar_KW, ar_SA…) resolves to it.
const kArabicLocale = Locale('ar', 'EG');
const kEnglishLocale = Locale('en');
const kSupportedLocales = [kEnglishLocale, kArabicLocale];

/// Every delegate the app needs, with the app's own strings first.
const kLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  _AppStringsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

/// The app's strings for [locale]: Arabic with Arabic-Indic digits, or English.
AppLocalizations appStringsFor(Locale locale) => locale.languageCode == 'ar'
    ? AppLocalizationsArDigits()
    : lookupAppLocalizations(kEnglishLocale);

/// The supported locale for whatever the phone asks for: any Arabic becomes
/// [kArabicLocale]; anything else English.
Locale resolveAppLocale(Locale? requested) =>
    requested?.languageCode == 'ar' ? kArabicLocale : kEnglishLocale;

class _AppStringsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      kSupportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(appStringsFor(locale));

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
