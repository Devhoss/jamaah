import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// App name shown in the OS task switcher. Keep in sync with branding.yaml.
  ///
  /// In en, this message translates to:
  /// **'Awqaity'**
  String get appTitle;

  /// Neutral wordmark shown in the top bar of every screen.
  ///
  /// In en, this message translates to:
  /// **'Prayer companion'**
  String get wordmark;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabMosques.
  ///
  /// In en, this message translates to:
  /// **'Mosques'**
  String get tabMosques;

  /// No description provided for @tabQibla.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get tabQibla;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Shown wherever an Iqama time has not been entered. Never fill an Iqama default.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Early build. Prayer times are calculated on this device. Iqama times are entered by you, per mosque.'**
  String get aboutBody;

  /// No description provided for @nextStepPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Screens arrive step by step.'**
  String get nextStepPlaceholder;

  /// Title of the explanation sheet shown before any location permission is requested.
  ///
  /// In en, this message translates to:
  /// **'Where are you?'**
  String get locationSheetTitle;

  /// No description provided for @locationSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Awqaity works out prayer times for the place you are in, on this device. There is no account and nothing is uploaded.'**
  String get locationSheetBody;

  /// No description provided for @locationSheetCoarse.
  ///
  /// In en, this message translates to:
  /// **'We ask for approximate location — city level, never your exact position. Times across one city differ by only a few minutes.'**
  String get locationSheetCoarse;

  /// No description provided for @locationUseDevice.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get locationUseDevice;

  /// No description provided for @locationChooseCity.
  ///
  /// In en, this message translates to:
  /// **'Choose a city'**
  String get locationChooseCity;

  /// No description provided for @locationRequesting.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get locationRequesting;

  /// Label for a place that came from the device rather than the bundled list.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get locationThisDevice;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'You declined the location permission. That is completely fine — choose your city and the times will be right.'**
  String get locationDenied;

  /// No description provided for @locationPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location is switched off for Awqaity in your device settings. You can change that there, or choose your city now.'**
  String get locationPermanentlyDenied;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off on this device. Choose your city, or switch location on and try again.'**
  String get locationServiceDisabled;

  /// No description provided for @locationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Your device did not answer in time. You can try again, or choose your city.'**
  String get locationTimeout;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your location could not be read right now. Choose your city instead.'**
  String get locationUnavailable;

  /// No description provided for @locationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get locationOpenSettings;

  /// No description provided for @locationTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get locationTryAgain;

  /// No description provided for @cityListTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a city'**
  String get cityListTitle;

  /// No description provided for @cityListPlaceholderNote.
  ///
  /// In en, this message translates to:
  /// **'This list ships with the app, so it works with no network. It is a placeholder — a starting point, not a directory. Pick the city nearest to you.'**
  String get cityListPlaceholderNote;

  /// No description provided for @cityListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get cityListSearchHint;

  /// No description provided for @cityListNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No city matches that. Choose the nearest one — prayer times differ by only a few minutes.'**
  String get cityListNoMatches;

  /// Shown where the app names the place its times come from.
  ///
  /// In en, this message translates to:
  /// **'Prayer times for {place}'**
  String currentPlaceLabel(String place);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
