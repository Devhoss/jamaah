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

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunrise;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// Names of the six daily times, in order. Transliterate rather than translate: these words are the prayer names users recognise.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// Shown for the moment while the stored settings are being read. Never a blank screen.
  ///
  /// In en, this message translates to:
  /// **'Loading your day…'**
  String get todayLoading;

  /// No description provided for @todayNeedsPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your location'**
  String get todayNeedsPlaceTitle;

  /// No description provided for @todayNeedsPlaceBody.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are worked out for the place you are in, on this device. Choose where you are to begin.'**
  String get todayNeedsPlaceBody;

  /// No description provided for @todayChoosePlace.
  ///
  /// In en, this message translates to:
  /// **'Choose where you are'**
  String get todayChoosePlace;

  /// The settings stream failed. Nothing is lost, so the message must not sound like it is.
  ///
  /// In en, this message translates to:
  /// **'Your saved setup could not be read'**
  String get todayErrorTitle;

  /// No description provided for @todayErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Awqaity could not open its own data on this device. Nothing has been lost — try again, or choose your location.'**
  String get todayErrorBody;

  /// Section header over the six rows. Says Adhan so it is never confused with Iqama.
  ///
  /// In en, this message translates to:
  /// **'Prayer times (Adhan)'**
  String get todaySectionTimes;

  /// Label of the hero card. Adhan and Iqama are separate concepts and the card names which one it is counting down to.
  ///
  /// In en, this message translates to:
  /// **'Next prayer · Adhan'**
  String get nextPrayerAdhan;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @tagNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tagNext;

  /// No description provided for @prayerAtTime.
  ///
  /// In en, this message translates to:
  /// **'{prayer} {time}'**
  String prayerAtTime(String prayer, String time);

  /// Used when the wait is an hour or more. Whole minutes, refreshed every minute in the foreground.
  ///
  /// In en, this message translates to:
  /// **'in {hours}h {minutes}m'**
  String countdownHours(int hours, int minutes);

  /// No description provided for @countdownMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {minutes} min'**
  String countdownMinutes(int minutes);

  /// Sub-block of the hero card, for the active mosque only. Iqama belongs to a mosque, never to a prayer in general.
  ///
  /// In en, this message translates to:
  /// **'Next Iqama · {mosque}'**
  String nextIqamaLabel(String mosque);

  /// The mosque has Iqama times, every one of them is behind the clock, and no Fajr time is entered for tomorrow. Not the same as a schedule that has never been configured, which gets its own prompt.
  ///
  /// In en, this message translates to:
  /// **'No more Iqama times today.'**
  String get noIqamaLeftToday;

  /// Shown on a prayer row only when the active mosque has that Iqama time entered.
  ///
  /// In en, this message translates to:
  /// **'Iqama {time}'**
  String rowIqama(String time);

  /// The saved setting for this prayer's Iqama. Wording must not claim a notification has been scheduled.
  ///
  /// In en, this message translates to:
  /// **'Reminder {minutes} min before'**
  String reminderBeforeIqama(int minutes);

  /// No description provided for @reminderOffForPrayer.
  ///
  /// In en, this message translates to:
  /// **'No reminder for this prayer'**
  String get reminderOffForPrayer;

  /// Honest label while the notification step has not been built: nothing here has scheduled anything.
  ///
  /// In en, this message translates to:
  /// **'Reminders are stored as settings. Notifications arrive in a later step.'**
  String get remindersAreSettingsNote;

  /// Quiet note added only when the high-latitude rule actually moved a time. Names the rule so the user can check it in Settings.
  ///
  /// In en, this message translates to:
  /// **'At this latitude, {prayers} follow the {rule} rule.'**
  String highLatitudeNote(String prayers, String rule);

  /// Joins the two prayer names the night rule can move.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String twoNames(String first, String second);

  /// No description provided for @ruleMiddleOfTheNight.
  ///
  /// In en, this message translates to:
  /// **'middle of the night'**
  String get ruleMiddleOfTheNight;

  /// No description provided for @ruleSeventhOfTheNight.
  ///
  /// In en, this message translates to:
  /// **'one seventh of the night'**
  String get ruleSeventhOfTheNight;

  /// Names of the three high-latitude rules, matching the Settings choice. Lower-case: they appear inside a sentence.
  ///
  /// In en, this message translates to:
  /// **'twilight angle'**
  String get ruleTwilightAngle;

  /// Shown when the place's own latitude has no sunrise or sunset on this day. Must name the latitude actually used.
  ///
  /// In en, this message translates to:
  /// **'The sun neither rises nor sets here today, so these times are estimated from {latitude}, nearer the equator.'**
  String estimatedFromLatitudeNote(String latitude);

  /// A row whose time could not be worked out keeps its place on the list and admits it.
  ///
  /// In en, this message translates to:
  /// **'no time today'**
  String get noTimeToday;

  /// No description provided for @timesUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'No times to show for this day'**
  String get timesUnavailableTitle;

  /// Polar day or polar night: the app says it cannot calculate rather than inventing a number.
  ///
  /// In en, this message translates to:
  /// **'Here the sun does not cross the horizon today, so there is no honest prayer time to work out. Choose a nearby city, or a day with a normal sunrise.'**
  String get timesUnavailableBody;

  /// No description provided for @addMosqueTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your mosque'**
  String get addMosqueTitle;

  /// No description provided for @addMosqueBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a mosque and enter its Iqama times to see them here. We never guess them.'**
  String get addMosqueBody;

  /// No description provided for @mosqueHasNoIqama.
  ///
  /// In en, this message translates to:
  /// **'{mosque} has no Iqama times yet. Tap to set them.'**
  String mosqueHasNoIqama(String mosque);

  /// Screen-reader label for the bell on a row.
  ///
  /// In en, this message translates to:
  /// **'Iqama reminder on'**
  String get reminderOnSemantics;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Early build. Prayer times are calculated on this device. Iqama times are entered by you, per mosque.'**
  String get aboutBody;

  /// Honest empty state on the Mosques tab. The tab exists so the bar matches the app being built; the copy says the feature does not.
  ///
  /// In en, this message translates to:
  /// **'Mosques come next'**
  String get mosquesComingTitle;

  /// No description provided for @mosquesComingBody.
  ///
  /// In en, this message translates to:
  /// **'Adding a mosque and entering its Iqama times is the step after this one. Today already works without a mosque, and no time here is ever guessed.'**
  String get mosquesComingBody;

  /// No description provided for @qiblaComingTitle.
  ///
  /// In en, this message translates to:
  /// **'Qibla comes later'**
  String get qiblaComingTitle;

  /// No description provided for @qiblaComingBody.
  ///
  /// In en, this message translates to:
  /// **'The direction of prayer is worked out on this device and gets its own screen after the mosque and reminder steps. No bearing is shown until it has been measured.'**
  String get qiblaComingBody;

  /// No description provided for @settingsComingTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings come later'**
  String get settingsComingTitle;

  /// The gear is on every tab because the prototype puts it there; this is what it says until Settings is a real screen.
  ///
  /// In en, this message translates to:
  /// **'Calculation method, Asr opinion, sounds and reminders will live here. None of them are built yet, so there is nothing honest to change.'**
  String get settingsComingBody;

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

  /// Label for a place that came from the device rather than the bundled list. It says what the reading is, not that we know a city name.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get locationCurrentPlace;

  /// Action under the saved place in the sheet, for the one part of a place the user is allowed to own.
  ///
  /// In en, this message translates to:
  /// **'Name this place'**
  String get placeRenameAction;

  /// No description provided for @placeRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Give this place a name'**
  String get placeRenameTitle;

  /// No description provided for @placeRenameHint.
  ///
  /// In en, this message translates to:
  /// **'For example, Home'**
  String get placeRenameHint;

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
