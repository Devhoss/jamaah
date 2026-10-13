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
  /// **'Jama’ah'**
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
  /// **'Jama’ah could not open its own data on this device. Nothing has been lost — try again, or choose your location.'**
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
  /// **'Jama’ah reminder on'**
  String get reminderOnSemantics;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Early build. Prayer times are calculated on this device. Iqama times are entered by you, per mosque.'**
  String get aboutBody;

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

  /// Title of the explanation sheet shown before any location permission is requested.
  ///
  /// In en, this message translates to:
  /// **'Where are you?'**
  String get locationSheetTitle;

  /// No description provided for @locationSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Jama’ah works out prayer times for the place you are in, on this device. There is no account and nothing is uploaded.'**
  String get locationSheetBody;

  /// No description provided for @locationSheetCoarse.
  ///
  /// In en, this message translates to:
  /// **'Prayer times need only approximate location — city level. Times across one city differ by only a few minutes. Finding mosques near you asks separately for precise location.'**
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
  /// **'Location is switched off for Jama’ah in your device settings. You can change that there, or choose your city now.'**
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

  /// No description provided for @mosquesTitle.
  ///
  /// In en, this message translates to:
  /// **'Mosques'**
  String get mosquesTitle;

  /// No description provided for @mosquesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Iqama times belong to each mosque.'**
  String get mosquesSubtitle;

  /// No description provided for @findNearbyMosques.
  ///
  /// In en, this message translates to:
  /// **'Find nearby mosques'**
  String get findNearbyMosques;

  /// No description provided for @addMosqueManually.
  ///
  /// In en, this message translates to:
  /// **'Add a mosque manually'**
  String get addMosqueManually;

  /// No description provided for @savedMosquesHeader.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedMosquesHeader;

  /// No description provided for @noSavedMosques.
  ///
  /// In en, this message translates to:
  /// **'No saved mosques yet. Add your mosque, then enter its Iqama times.'**
  String get noSavedMosques;

  /// Tag on the mosque whose Iqama times Today shows and reminders use.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tagActive;

  /// No description provided for @iqamaStatusAll.
  ///
  /// In en, this message translates to:
  /// **'Iqama set'**
  String get iqamaStatusAll;

  /// No description provided for @iqamaStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} Iqama set'**
  String iqamaStatusPartial(int count, int total);

  /// No description provided for @iqamaStatusNone.
  ///
  /// In en, this message translates to:
  /// **'Iqama not configured'**
  String get iqamaStatusNone;

  /// Where the mosque came from. There is no verification; label by source only.
  ///
  /// In en, this message translates to:
  /// **'Added by you'**
  String get mosqueSourceManual;

  /// No description provided for @mosqueSourceGoogle.
  ///
  /// In en, this message translates to:
  /// **'From Google Maps'**
  String get mosqueSourceGoogle;

  /// No description provided for @mosqueSourceOsm.
  ///
  /// In en, this message translates to:
  /// **'From OpenStreetMap'**
  String get mosqueSourceOsm;

  /// No description provided for @addMosqueSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a mosque'**
  String get addMosqueSheetTitle;

  /// No description provided for @addMosqueSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Its Iqama schedule starts as “Not configured”. You enter the times.'**
  String get addMosqueSheetBody;

  /// No description provided for @mosqueNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Mosque name'**
  String get mosqueNameLabel;

  /// No description provided for @mosqueAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address or area (optional)'**
  String get mosqueAddressLabel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @setAsActive.
  ///
  /// In en, this message translates to:
  /// **'Set as active'**
  String get setAsActive;

  /// No description provided for @activeMosqueNote.
  ///
  /// In en, this message translates to:
  /// **'Today and Jama’ah reminders use this mosque.'**
  String get activeMosqueNote;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editDetails;

  /// No description provided for @editMosqueTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit mosque'**
  String get editMosqueTitle;

  /// No description provided for @iqamaScheduleHeader.
  ///
  /// In en, this message translates to:
  /// **'Iqama schedule · {mosque}'**
  String iqamaScheduleHeader(String mosque);

  /// Secondary line on an Iqama row. Adhan and Iqama stay visibly separate.
  ///
  /// In en, this message translates to:
  /// **'Adhan {time}'**
  String rowAdhanTime(String time);

  /// No description provided for @rowReminderAt.
  ///
  /// In en, this message translates to:
  /// **'Reminder at {time}'**
  String rowReminderAt(String time);

  /// The Iqama is just after midnight and the reminder falls on the evening before it.
  ///
  /// In en, this message translates to:
  /// **'Reminder at {time}, before midnight'**
  String rowReminderBeforeMidnight(String time);

  /// No description provided for @rowReminderOff.
  ///
  /// In en, this message translates to:
  /// **'Reminder off'**
  String get rowReminderOff;

  /// No description provided for @rowReminderNeedsIqama.
  ///
  /// In en, this message translates to:
  /// **'Set an Iqama time to add a reminder'**
  String get rowReminderNeedsIqama;

  /// No description provided for @reminderSwitchLabel.
  ///
  /// In en, this message translates to:
  /// **'{prayer} Jama’ah reminder'**
  String reminderSwitchLabel(String prayer);

  /// No description provided for @scheduleSetByYou.
  ///
  /// In en, this message translates to:
  /// **'Set by you · last updated {date}'**
  String scheduleSetByYou(String date);

  /// No description provided for @scheduleNothingEntered.
  ///
  /// In en, this message translates to:
  /// **'No Iqama times entered yet. Tap a prayer to set one.'**
  String get scheduleNothingEntered;

  /// No description provided for @iqamaScheduleNote.
  ///
  /// In en, this message translates to:
  /// **'Tap a prayer to edit. Iqama times are entered by you for this mosque and never taken from Adhan times. Sunrise has no Iqama.'**
  String get iqamaScheduleNote;

  /// No description provided for @removeMosque.
  ///
  /// In en, this message translates to:
  /// **'Remove mosque'**
  String get removeMosque;

  /// No description provided for @removeMosqueTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {mosque}?'**
  String removeMosqueTitle(String mosque);

  /// No description provided for @removeMosqueBody.
  ///
  /// In en, this message translates to:
  /// **'Its Iqama times will be deleted from this device.'**
  String get removeMosqueBody;

  /// No description provided for @removeMosqueBodyActive.
  ///
  /// In en, this message translates to:
  /// **'Its Iqama times will be deleted from this device. It is your active mosque, so Today will show no mosque until you choose another.'**
  String get removeMosqueBodyActive;

  /// No description provided for @iqamaEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer} Iqama'**
  String iqamaEditorTitle(String prayer);

  /// No description provided for @iqamaEditorEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing {mosque}'**
  String iqamaEditorEditing(String mosque);

  /// No description provided for @iqamaChooseTime.
  ///
  /// In en, this message translates to:
  /// **'Choose a time'**
  String get iqamaChooseTime;

  /// Empty Iqama field when the day's Adhan time is known. The picker opens at the Adhan time; nothing is saved until the user confirms a time. Never present it as the Iqama.
  ///
  /// In en, this message translates to:
  /// **'Adhan {time} · tap to set'**
  String iqamaStartsAtAdhan(String time);

  /// No description provided for @iqamaTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Iqama time'**
  String get iqamaTimeLabel;

  /// No description provided for @remindMeBefore.
  ///
  /// In en, this message translates to:
  /// **'Remind me before Iqama'**
  String get remindMeBefore;

  /// No description provided for @reminderNeedsTime.
  ///
  /// In en, this message translates to:
  /// **'Choose an Iqama time first.'**
  String get reminderNeedsTime;

  /// No description provided for @reminderMinutesChip.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String reminderMinutesChip(int minutes);

  /// No description provided for @reminderCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reminderCustom;

  /// No description provided for @reminderCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes before (1–120)'**
  String get reminderCustomLabel;

  /// No description provided for @reminderCustomEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter how many minutes before Iqama.'**
  String get reminderCustomEmpty;

  /// No description provided for @reminderCustomNotWhole.
  ///
  /// In en, this message translates to:
  /// **'Use whole minutes, like 20.'**
  String get reminderCustomNotWhole;

  /// No description provided for @reminderCustomOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Choose between 1 and 120 minutes.'**
  String get reminderCustomOutOfRange;

  /// No description provided for @summaryNoTime.
  ///
  /// In en, this message translates to:
  /// **'Choose an Iqama time to see the reminder summary.'**
  String get summaryNoTime;

  /// No description provided for @summaryReminderOff.
  ///
  /// In en, this message translates to:
  /// **'{prayer} · {time} Iqama · Reminder off'**
  String summaryReminderOff(String prayer, String time);

  /// No description provided for @summaryReminderAt.
  ///
  /// In en, this message translates to:
  /// **'{prayer} · {time} Iqama · Reminder at {reminder}'**
  String summaryReminderAt(String prayer, String time, String reminder);

  /// Iqama just after midnight; the reminder is on the evening before. Must not read as the same calendar day.
  ///
  /// In en, this message translates to:
  /// **'{prayer} · {time} Iqama · Reminder at {reminder}, before midnight'**
  String summaryReminderBeforeMidnight(
    String prayer,
    String time,
    String reminder,
  );

  /// No description provided for @clearIqamaTime.
  ///
  /// In en, this message translates to:
  /// **'Clear Iqama time'**
  String get clearIqamaTime;

  /// No description provided for @nearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby mosques'**
  String get nearbyTitle;

  /// No description provided for @nearbyExplainTitle.
  ///
  /// In en, this message translates to:
  /// **'Find mosques near you'**
  String get nearbyExplainTitle;

  /// No description provided for @nearbyExplainBody.
  ///
  /// In en, this message translates to:
  /// **'We use your precise location once, to list the mosques around you. If you keep location approximate, the search still works, just less exactly.'**
  String get nearbyExplainBody;

  /// Honest about the one network call that carries the position.
  ///
  /// In en, this message translates to:
  /// **'Your position is sent to {provider} for this search only. Jama’ah does not store it.'**
  String nearbyExplainSent(String provider);

  /// No description provided for @providerGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get providerGoogle;

  /// No description provided for @providerOsm.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap'**
  String get providerOsm;

  /// No description provided for @nearbyUseLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get nearbyUseLocation;

  /// No description provided for @nearbySearchCity.
  ///
  /// In en, this message translates to:
  /// **'Search around a city'**
  String get nearbySearchCity;

  /// No description provided for @nearbyLocating.
  ///
  /// In en, this message translates to:
  /// **'Finding where you are…'**
  String get nearbyLocating;

  /// No description provided for @nearbySearching.
  ///
  /// In en, this message translates to:
  /// **'Looking for mosques…'**
  String get nearbySearching;

  /// No description provided for @nearbyHeaderHere.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km of you'**
  String nearbyHeaderHere(int km);

  /// No description provided for @nearbyHeaderCity.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km of {place}'**
  String nearbyHeaderCity(int km, String place);

  /// No description provided for @nearbyApproximateNote.
  ///
  /// In en, this message translates to:
  /// **'Your phone shared approximate location, so this list may be a few kilometres off. You can allow precise location in settings.'**
  String get nearbyApproximateNote;

  /// No description provided for @nearbyFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by name'**
  String get nearbyFilterHint;

  /// The provider has no name for this place. Never invent one; the user names it when saving.
  ///
  /// In en, this message translates to:
  /// **'Unnamed mosque'**
  String get nearbyUnnamed;

  /// No description provided for @nearbyNoAddress.
  ///
  /// In en, this message translates to:
  /// **'No address listed'**
  String get nearbyNoAddress;

  /// A result at (or listed at) almost the searched point. Providers often place mosques at a map grid centre, so a precise-looking "0 m" would claim more than they know.
  ///
  /// In en, this message translates to:
  /// **'Under 50 m'**
  String get distanceUnder50;

  /// No description provided for @distanceMetres.
  ///
  /// In en, this message translates to:
  /// **'{metres} m'**
  String distanceMetres(int metres);

  /// No description provided for @distanceKilometres.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKilometres(String km);

  /// No description provided for @nearbyAttributionGoogle.
  ///
  /// In en, this message translates to:
  /// **'Results from Google Maps. Not verified — check the name before saving.'**
  String get nearbyAttributionGoogle;

  /// No description provided for @nearbyAttributionOsm.
  ///
  /// In en, this message translates to:
  /// **'Results © OpenStreetMap contributors. Not verified — check the name before saving.'**
  String get nearbyAttributionOsm;

  /// No description provided for @nearbyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No mosques found within {km} km. Try a city, or add your mosque by hand.'**
  String nearbyEmpty(int km);

  /// No description provided for @nearbyNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No mosque in this list matches that name.'**
  String get nearbyNoMatches;

  /// No description provided for @nearbyAddManually.
  ///
  /// In en, this message translates to:
  /// **'Not listed? Add it by hand'**
  String get nearbyAddManually;

  /// No description provided for @nearbyTryOsm.
  ///
  /// In en, this message translates to:
  /// **'Search OpenStreetMap instead'**
  String get nearbyTryOsm;

  /// No description provided for @nearbyFailNoKey.
  ///
  /// In en, this message translates to:
  /// **'Google Maps search isn\'t set up in this build. You can search OpenStreetMap, or add your mosque by hand.'**
  String get nearbyFailNoKey;

  /// No description provided for @nearbyFailKeyRejected.
  ///
  /// In en, this message translates to:
  /// **'Google Maps refused the search. That\'s a setup problem with the app, not your phone. You can search OpenStreetMap instead.'**
  String get nearbyFailKeyRejected;

  /// No description provided for @nearbyFailNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection right now. Your saved mosques and prayer times still work offline.'**
  String get nearbyFailNetwork;

  /// No description provided for @nearbyFailRateLimited.
  ///
  /// In en, this message translates to:
  /// **'{provider} is busy. Try again in a minute, or add your mosque by hand.'**
  String nearbyFailRateLimited(String provider);

  /// No description provided for @nearbyFailServer.
  ///
  /// In en, this message translates to:
  /// **'{provider} didn\'t answer properly. Try again, or add your mosque by hand.'**
  String nearbyFailServer(String provider);

  /// No description provided for @nearbyFailLimit.
  ///
  /// In en, this message translates to:
  /// **'That\'s all the searching for this session, to keep the app free to run. It resets when you reopen the app. You can still add a mosque by hand.'**
  String get nearbyFailLimit;

  /// No description provided for @nearbyLocDenied.
  ///
  /// In en, this message translates to:
  /// **'Location wasn\'t allowed. You can search around a city instead.'**
  String get nearbyLocDenied;

  /// No description provided for @nearbyLocPermanent.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off for Jama’ah in your settings. Allow it there, or search around a city.'**
  String get nearbyLocPermanent;

  /// No description provided for @nearbyLocService.
  ///
  /// In en, this message translates to:
  /// **'Location services are off on this phone. Turn them on, or search around a city.'**
  String get nearbyLocService;

  /// No description provided for @nearbyLocTimeout.
  ///
  /// In en, this message translates to:
  /// **'Your phone didn\'t find its position in time. Try again, or search around a city.'**
  String get nearbyLocTimeout;

  /// No description provided for @nearbyLocUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your position couldn\'t be read right now. Search around a city instead.'**
  String get nearbyLocUnavailable;

  /// No description provided for @tagSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get tagSaved;

  /// No description provided for @saveMosqueTitle.
  ///
  /// In en, this message translates to:
  /// **'Save this mosque'**
  String get saveMosqueTitle;

  /// No description provided for @saveMosqueBody.
  ///
  /// In en, this message translates to:
  /// **'Check the name and address — they come from {provider}, not from the mosque. Its Iqama times start as “Not configured”.'**
  String saveMosqueBody(String provider);

  /// No description provided for @soundModeFull.
  ///
  /// In en, this message translates to:
  /// **'Full Adhan'**
  String get soundModeFull;

  /// No description provided for @soundModeShort.
  ///
  /// In en, this message translates to:
  /// **'Short Adhan'**
  String get soundModeShort;

  /// The phone's own default notification sound.
  ///
  /// In en, this message translates to:
  /// **'Standard sound'**
  String get soundModeStandard;

  /// Shown in the notification shade with no sound. Not the same as turned off.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get soundModeSilent;

  /// No description provided for @channelAdhan.
  ///
  /// In en, this message translates to:
  /// **'Adhan · {sound}'**
  String channelAdhan(String sound);

  /// No description provided for @channelNoVibration.
  ///
  /// In en, this message translates to:
  /// **'{name} · no vibration'**
  String channelNoVibration(String name);

  /// No description provided for @channelAlarmVolume.
  ///
  /// In en, this message translates to:
  /// **'{name} · alarm volume'**
  String channelAlarmVolume(String name);

  /// No description provided for @channelPreAdhan.
  ///
  /// In en, this message translates to:
  /// **'Reminders before the Adhan'**
  String get channelPreAdhan;

  /// No description provided for @channelIqama.
  ///
  /// In en, this message translates to:
  /// **'Jama’ah reminders'**
  String get channelIqama;

  /// No description provided for @notifAdhanTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer}'**
  String notifAdhanTitle(String prayer);

  /// No description provided for @notifAdhanBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s time for {prayer}.'**
  String notifAdhanBody(String prayer);

  /// No description provided for @notifSunriseBody.
  ///
  /// In en, this message translates to:
  /// **'The sun is rising. The time for Fajr has ended.'**
  String get notifSunriseBody;

  /// No description provided for @notifPreAdhanTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer} in {minutes} min'**
  String notifPreAdhanTitle(String prayer, int minutes);

  /// No description provided for @notifPreAdhanBody.
  ///
  /// In en, this message translates to:
  /// **'A reminder before the Adhan.'**
  String get notifPreAdhanBody;

  /// No description provided for @notifPreSunriseBody.
  ///
  /// In en, this message translates to:
  /// **'The time for Fajr ends at sunrise.'**
  String get notifPreSunriseBody;

  /// No description provided for @notifIqamaTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer} Iqama in {minutes} min'**
  String notifIqamaTitle(String prayer, int minutes);

  /// No description provided for @notifIqamaBody.
  ///
  /// In en, this message translates to:
  /// **'At {mosque}.'**
  String notifIqamaBody(String mosque);

  /// No description provided for @scheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled notifications'**
  String get scheduledTitle;

  /// No description provided for @scheduledCount.
  ///
  /// In en, this message translates to:
  /// **'{count} scheduled for the next 7 days'**
  String scheduledCount(int count);

  /// No description provided for @scheduledNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing is scheduled. Turn on an Adhan alert, or a Jama’ah reminder on your mosque.'**
  String get scheduledNothing;

  /// No description provided for @scheduledNotificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for Jama’ah, so nothing will show. You can allow them now.'**
  String get scheduledNotificationsOff;

  /// No description provided for @scheduledExactOff.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms aren\'t allowed, so notifications may arrive a few minutes late. You can allow them in settings.'**
  String get scheduledExactOff;

  /// No description provided for @scheduledAllowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get scheduledAllowNotifications;

  /// No description provided for @scheduledAllowExact.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms'**
  String get scheduledAllowExact;

  /// No description provided for @scheduledRescheduleNow.
  ///
  /// In en, this message translates to:
  /// **'Reschedule now'**
  String get scheduledRescheduleNow;

  /// No description provided for @scheduledBatteryHint.
  ///
  /// In en, this message translates to:
  /// **'Some phones stop reminders to save battery. If one doesn\'t arrive, set Jama’ah\'s battery use to Unrestricted in the phone\'s app settings.'**
  String get scheduledBatteryHint;

  /// No description provided for @scheduledOpenAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get scheduledOpenAppSettings;

  /// No description provided for @kindAdhan.
  ///
  /// In en, this message translates to:
  /// **'Adhan'**
  String get kindAdhan;

  /// No description provided for @kindPreAdhan.
  ///
  /// In en, this message translates to:
  /// **'Reminder before Adhan'**
  String get kindPreAdhan;

  /// No description provided for @kindIqama.
  ///
  /// In en, this message translates to:
  /// **'Jama’ah reminder'**
  String get kindIqama;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAdhanSection.
  ///
  /// In en, this message translates to:
  /// **'Adhan alerts'**
  String get settingsAdhanSection;

  /// No description provided for @settingsDefaultSound.
  ///
  /// In en, this message translates to:
  /// **'Default sound'**
  String get settingsDefaultSound;

  /// No description provided for @settingsDefaultSoundHint.
  ///
  /// In en, this message translates to:
  /// **'Used by every prayer that doesn\'t choose its own.'**
  String get settingsDefaultSoundHint;

  /// No description provided for @settingsAlertOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsAlertOff;

  /// No description provided for @settingsAlertOn.
  ///
  /// In en, this message translates to:
  /// **'On · {sound}'**
  String settingsAlertOn(String sound);

  /// No description provided for @settingsAlertReminderOnly.
  ///
  /// In en, this message translates to:
  /// **'Reminder only · {minutes} min before'**
  String settingsAlertReminderOnly(int minutes);

  /// No description provided for @settingsAlertOnWithReminder.
  ///
  /// In en, this message translates to:
  /// **'On · {sound} · reminder {minutes} min before'**
  String settingsAlertOnWithReminder(String sound, int minutes);

  /// No description provided for @settingsIqamaSection.
  ///
  /// In en, this message translates to:
  /// **'Jama’ah reminders'**
  String get settingsIqamaSection;

  /// No description provided for @settingsIqamaBody.
  ///
  /// In en, this message translates to:
  /// **'A Jama’ah reminder comes before your mosque’s Iqama time. Iqama times and their reminders belong to each mosque, so you set them on the mosque.'**
  String get settingsIqamaBody;

  /// No description provided for @settingsIqamaOpenActive.
  ///
  /// In en, this message translates to:
  /// **'Open {mosque}'**
  String settingsIqamaOpenActive(String mosque);

  /// No description provided for @settingsIqamaNoMosque.
  ///
  /// In en, this message translates to:
  /// **'Add a mosque to set Jama’ah reminders.'**
  String get settingsIqamaNoMosque;

  /// No description provided for @settingsTravelSection.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get settingsTravelSection;

  /// No description provided for @settingsNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsSection;

  /// No description provided for @alertPageTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer}'**
  String alertPageTitle(String prayer);

  /// No description provided for @alertAdhanSwitch.
  ///
  /// In en, this message translates to:
  /// **'Adhan alert'**
  String get alertAdhanSwitch;

  /// No description provided for @alertAdhanSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'A notification at the Adhan time.'**
  String get alertAdhanSwitchHint;

  /// No description provided for @alertSunriseHint.
  ///
  /// In en, this message translates to:
  /// **'Sunrise is not a prayer. An alert marks the end of the time for Fajr.'**
  String get alertSunriseHint;

  /// No description provided for @alertSoundHeader.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get alertSoundHeader;

  /// No description provided for @alertUseDefault.
  ///
  /// In en, this message translates to:
  /// **'Default ({sound})'**
  String alertUseDefault(String sound);

  /// No description provided for @alertSilentHint.
  ///
  /// In en, this message translates to:
  /// **'Shown in your notifications without any sound. Turning the alert off is different: then nothing shows.'**
  String get alertSilentHint;

  /// No description provided for @alertFullHint.
  ///
  /// In en, this message translates to:
  /// **'Plays the whole Adhan, in the recording chosen in Settings.'**
  String get alertFullHint;

  /// No description provided for @alertShortHint.
  ///
  /// In en, this message translates to:
  /// **'Plays the opening of the Adhan, about 8 seconds.'**
  String get alertShortHint;

  /// No description provided for @alertStandardHint.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s usual notification sound.'**
  String get alertStandardHint;

  /// No description provided for @alertPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get alertPreview;

  /// No description provided for @alertStopPreview.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get alertStopPreview;

  /// No description provided for @alertVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get alertVibrate;

  /// No description provided for @alertRingInSilent.
  ///
  /// In en, this message translates to:
  /// **'Ring when the phone is on silent'**
  String get alertRingInSilent;

  /// No description provided for @alertRingInSilentHint.
  ///
  /// In en, this message translates to:
  /// **'Plays through the alarm volume, so you hear it even on silent. Off by default, so nothing surprises you in a quiet room.'**
  String get alertRingInSilentHint;

  /// No description provided for @alertRingInSilentNeedsAdhan.
  ///
  /// In en, this message translates to:
  /// **'Only for the full or short Adhan.'**
  String get alertRingInSilentNeedsAdhan;

  /// No description provided for @alertReminderHeader.
  ///
  /// In en, this message translates to:
  /// **'Reminder before the Adhan'**
  String get alertReminderHeader;

  /// No description provided for @alertReminderHint.
  ///
  /// In en, this message translates to:
  /// **'A separate heads-up, even if the Adhan alert itself is off.'**
  String get alertReminderHint;

  /// No description provided for @alertReminderNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get alertReminderNone;

  /// No description provided for @alertTryIt.
  ///
  /// In en, this message translates to:
  /// **'Send a test notification'**
  String get alertTryIt;

  /// No description provided for @alertTrySent.
  ///
  /// In en, this message translates to:
  /// **'Sent. Check your notifications.'**
  String get alertTrySent;

  /// No description provided for @notifTestTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer} · test'**
  String notifTestTitle(String prayer);

  /// No description provided for @notifTestBody.
  ///
  /// In en, this message translates to:
  /// **'This is how this alert will sound.'**
  String get notifTestBody;

  /// No description provided for @adhanStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get adhanStop;

  /// No description provided for @settingsFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full-screen Adhan'**
  String get settingsFullScreen;

  /// No description provided for @settingsFullScreenHint.
  ///
  /// In en, this message translates to:
  /// **'When the phone is idle, the Adhan fills the screen with a large Stop. The volume keys, or turning the phone face down, stop it too.'**
  String get settingsFullScreenHint;

  /// No description provided for @settingsFullScreenDenied.
  ///
  /// In en, this message translates to:
  /// **'Your phone doesn\'t allow full-screen alerts for Jama’ah, so the Adhan shows as a regular notification.'**
  String get settingsFullScreenDenied;

  /// No description provided for @settingsFullScreenAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow full-screen alerts'**
  String get settingsFullScreenAllow;

  /// No description provided for @alertStopHint.
  ///
  /// In en, this message translates to:
  /// **'Stop it from the notification, or turn the phone face down.'**
  String get alertStopHint;

  /// No description provided for @settingsFollowLocation.
  ///
  /// In en, this message translates to:
  /// **'Follow my location'**
  String get settingsFollowLocation;

  /// No description provided for @settingsFollowLocationHint.
  ///
  /// In en, this message translates to:
  /// **'While travel mode is on, your place updates to where you are when you open the app, so times follow you between cities and time zones.'**
  String get settingsFollowLocationHint;

  /// No description provided for @settingsTravelMode.
  ///
  /// In en, this message translates to:
  /// **'Travel mode'**
  String get settingsTravelMode;

  /// No description provided for @settingsTravelModeHint.
  ///
  /// In en, this message translates to:
  /// **'Turns on the travel options below. The airplane at the top of the app switches it too.'**
  String get settingsTravelModeHint;

  /// No description provided for @travelModeTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on travel mode'**
  String get travelModeTurnOn;

  /// No description provided for @travelModeTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off travel mode'**
  String get travelModeTurnOff;

  /// No description provided for @travelModeOnSnack.
  ///
  /// In en, this message translates to:
  /// **'Travel mode on'**
  String get travelModeOnSnack;

  /// No description provided for @travelModeOffSnack.
  ///
  /// In en, this message translates to:
  /// **'Travel mode off'**
  String get travelModeOffSnack;

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSection;

  /// No description provided for @settingsFullRecording.
  ///
  /// In en, this message translates to:
  /// **'Full Adhan recording'**
  String get settingsFullRecording;

  /// No description provided for @recordingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Full Adhan recording'**
  String get recordingsTitle;

  /// No description provided for @recordingsBody.
  ///
  /// In en, this message translates to:
  /// **'Plays for every alert set to Full Adhan. Short Adhan is the opening of Naghshbandi.'**
  String get recordingsBody;

  /// No description provided for @recordingPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get recordingPlay;

  /// No description provided for @recordingStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get recordingStop;

  /// No description provided for @recordingPlayLabel.
  ///
  /// In en, this message translates to:
  /// **'Play {name}'**
  String recordingPlayLabel(String name);

  /// No description provided for @recordingStopLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}'**
  String recordingStopLabel(String name);

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as the phone'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @followDenied.
  ///
  /// In en, this message translates to:
  /// **'Location wasn\'t allowed, so the app can\'t follow you. You can still choose a city.'**
  String get followDenied;

  /// No description provided for @followUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your location couldn\'t be read right now, so following stays off. Try again in a moment.'**
  String get followUnavailable;

  /// No description provided for @followingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Following your location · updated {ago}'**
  String followingUpdated(String ago);

  /// Following is on but the latest try failed (in the air, location off). Never silent.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your location. Using the last one, from {ago}.'**
  String followingStale(String ago);

  /// No description provided for @agoJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get agoJustNow;

  /// No description provided for @agoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String agoMinutes(int count);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String agoHours(int count);

  /// No description provided for @agoDays.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String agoDays(int count);

  /// No description provided for @previewCity.
  ///
  /// In en, this message translates to:
  /// **'Preview another city'**
  String get previewCity;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'{place}'**
  String previewTitle(String place);

  /// No description provided for @previewNote.
  ///
  /// In en, this message translates to:
  /// **'Prayer times for {place}. Your own place stays {current}.'**
  String previewNote(String place, String current);

  /// No description provided for @methodAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto detect'**
  String get methodAuto;

  /// No description provided for @methodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom angles'**
  String get methodCustom;

  /// No description provided for @methodEgyptian.
  ///
  /// In en, this message translates to:
  /// **'Egyptian General Authority of Survey (EGAS)'**
  String get methodEgyptian;

  /// No description provided for @methodRegionEgyptian.
  ///
  /// In en, this message translates to:
  /// **'Africa, Syria, Lebanon'**
  String get methodRegionEgyptian;

  /// No description provided for @methodIsna.
  ///
  /// In en, this message translates to:
  /// **'Islamic Society of North America (ISNA)'**
  String get methodIsna;

  /// No description provided for @methodRegionIsna.
  ///
  /// In en, this message translates to:
  /// **'North America (US and Canada)'**
  String get methodRegionIsna;

  /// No description provided for @methodMoonsightingCommittee.
  ///
  /// In en, this message translates to:
  /// **'Moonsighting Committee Worldwide (MCW)'**
  String get methodMoonsightingCommittee;

  /// No description provided for @methodRegionMoonsightingCommittee.
  ///
  /// In en, this message translates to:
  /// **'Parts of the US, parts of the UK'**
  String get methodRegionMoonsightingCommittee;

  /// No description provided for @methodMuslimWorldLeague.
  ///
  /// In en, this message translates to:
  /// **'Muslim World League (MWL)'**
  String get methodMuslimWorldLeague;

  /// No description provided for @methodRegionMuslimWorldLeague.
  ///
  /// In en, this message translates to:
  /// **'Europe, Far East, parts of the US, and other countries'**
  String get methodRegionMuslimWorldLeague;

  /// No description provided for @methodUmmAlQura.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura University, Makkah'**
  String get methodUmmAlQura;

  /// No description provided for @methodRegionUmmAlQura.
  ///
  /// In en, this message translates to:
  /// **'The Arabian Peninsula'**
  String get methodRegionUmmAlQura;

  /// No description provided for @methodKarachi.
  ///
  /// In en, this message translates to:
  /// **'University of Islamic Sciences, Karachi'**
  String get methodKarachi;

  /// No description provided for @methodRegionKarachi.
  ///
  /// In en, this message translates to:
  /// **'Pakistan, Afghanistan, Bangladesh, India, parts of Europe'**
  String get methodRegionKarachi;

  /// No description provided for @methodJakim.
  ///
  /// In en, this message translates to:
  /// **'Department of Islamic Advancement of Malaysia (JAKIM)'**
  String get methodJakim;

  /// No description provided for @methodRegionJakim.
  ///
  /// In en, this message translates to:
  /// **'Malaysia'**
  String get methodRegionJakim;

  /// No description provided for @methodSingapore.
  ///
  /// In en, this message translates to:
  /// **'Islamic Religious Council of Singapore (MUIS)'**
  String get methodSingapore;

  /// No description provided for @methodRegionSingapore.
  ///
  /// In en, this message translates to:
  /// **'Singapore'**
  String get methodRegionSingapore;

  /// No description provided for @methodIndonesia.
  ///
  /// In en, this message translates to:
  /// **'Ministry of Religious Affairs of Indonesia (KEMENAG)'**
  String get methodIndonesia;

  /// No description provided for @methodRegionIndonesia.
  ///
  /// In en, this message translates to:
  /// **'Indonesia'**
  String get methodRegionIndonesia;

  /// No description provided for @methodTurkiye.
  ///
  /// In en, this message translates to:
  /// **'Presidency of Religious Affairs of Türkiye (Diyanet)'**
  String get methodTurkiye;

  /// No description provided for @methodRegionTurkiye.
  ///
  /// In en, this message translates to:
  /// **'Türkiye'**
  String get methodRegionTurkiye;

  /// No description provided for @methodFrance.
  ///
  /// In en, this message translates to:
  /// **'Union of Islamic Organisations of France (UOIF)'**
  String get methodFrance;

  /// No description provided for @methodRegionFrance.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get methodRegionFrance;

  /// No description provided for @methodKuwait.
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get methodKuwait;

  /// No description provided for @methodRegionKuwait.
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get methodRegionKuwait;

  /// No description provided for @methodQatar.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get methodQatar;

  /// No description provided for @methodRegionQatar.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get methodRegionQatar;

  /// No description provided for @methodDubai.
  ///
  /// In en, this message translates to:
  /// **'Dubai (UAE)'**
  String get methodDubai;

  /// No description provided for @methodRegionDubai.
  ///
  /// In en, this message translates to:
  /// **'United Arab Emirates'**
  String get methodRegionDubai;

  /// No description provided for @methodGulfRegion.
  ///
  /// In en, this message translates to:
  /// **'Gulf region'**
  String get methodGulfRegion;

  /// No description provided for @methodRegionGulfRegion.
  ///
  /// In en, this message translates to:
  /// **'Bahrain, Oman'**
  String get methodRegionGulfRegion;

  /// No description provided for @methodJordan.
  ///
  /// In en, this message translates to:
  /// **'Jordan'**
  String get methodJordan;

  /// No description provided for @methodRegionJordan.
  ///
  /// In en, this message translates to:
  /// **'Jordan'**
  String get methodRegionJordan;

  /// No description provided for @methodAlgeria.
  ///
  /// In en, this message translates to:
  /// **'Algeria'**
  String get methodAlgeria;

  /// No description provided for @methodRegionAlgeria.
  ///
  /// In en, this message translates to:
  /// **'Algeria'**
  String get methodRegionAlgeria;

  /// No description provided for @methodMorocco.
  ///
  /// In en, this message translates to:
  /// **'Morocco'**
  String get methodMorocco;

  /// No description provided for @methodRegionMorocco.
  ///
  /// In en, this message translates to:
  /// **'Morocco'**
  String get methodRegionMorocco;

  /// No description provided for @methodTunisia.
  ///
  /// In en, this message translates to:
  /// **'Tunisia'**
  String get methodTunisia;

  /// No description provided for @methodRegionTunisia.
  ///
  /// In en, this message translates to:
  /// **'Tunisia'**
  String get methodRegionTunisia;

  /// No description provided for @methodRussia.
  ///
  /// In en, this message translates to:
  /// **'Spiritual Administration of Muslims of Russia'**
  String get methodRussia;

  /// No description provided for @methodRegionRussia.
  ///
  /// In en, this message translates to:
  /// **'Russia'**
  String get methodRegionRussia;

  /// No description provided for @methodPortugal.
  ///
  /// In en, this message translates to:
  /// **'Islamic Community of Lisbon'**
  String get methodPortugal;

  /// No description provided for @methodRegionPortugal.
  ///
  /// In en, this message translates to:
  /// **'Portugal'**
  String get methodRegionPortugal;

  /// No description provided for @methodTehran.
  ///
  /// In en, this message translates to:
  /// **'Institute of Geophysics, University of Tehran'**
  String get methodTehran;

  /// No description provided for @methodRegionTehran.
  ///
  /// In en, this message translates to:
  /// **'Iran (Shia)'**
  String get methodRegionTehran;

  /// No description provided for @methodJafari.
  ///
  /// In en, this message translates to:
  /// **'Shia Ithna-Ashari, Leva Institute, Qum'**
  String get methodJafari;

  /// No description provided for @methodRegionJafari.
  ///
  /// In en, this message translates to:
  /// **'Shia communities'**
  String get methodRegionJafari;

  /// No description provided for @settingsPrayerTimesSection.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get settingsPrayerTimesSection;

  /// No description provided for @settingsMethod.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get settingsMethod;

  /// No description provided for @settingsAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr method'**
  String get settingsAsr;

  /// No description provided for @settingsHighLatitude.
  ///
  /// In en, this message translates to:
  /// **'Higher latitudes'**
  String get settingsHighLatitude;

  /// No description provided for @settingsAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Manual adjustments'**
  String get settingsAdjustments;

  /// No description provided for @methodAngles.
  ///
  /// In en, this message translates to:
  /// **'Fajr {fajr}° · Isha {isha}°'**
  String methodAngles(String fajr, String isha);

  /// No description provided for @methodAnglesInterval.
  ///
  /// In en, this message translates to:
  /// **'Fajr {fajr}° · Isha {minutes} min after Maghrib'**
  String methodAnglesInterval(String fajr, int minutes);

  /// No description provided for @methodUmmAlQuraRamadan.
  ///
  /// In en, this message translates to:
  /// **'Isha 120 min after Maghrib during Ramadan'**
  String get methodUmmAlQuraRamadan;

  /// No description provided for @methodMoonsightingNote.
  ///
  /// In en, this message translates to:
  /// **'Also adjusts Fajr and Isha by season'**
  String get methodMoonsightingNote;

  /// No description provided for @methodAutoResolved.
  ///
  /// In en, this message translates to:
  /// **'Uses {method} for {place}'**
  String methodAutoResolved(String method, String place);

  /// No description provided for @methodAutoNoPlace.
  ///
  /// In en, this message translates to:
  /// **'Chooses by your place once one is set'**
  String get methodAutoNoPlace;

  /// No description provided for @customTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom angles'**
  String get customTitle;

  /// No description provided for @customFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr angle (°)'**
  String get customFajr;

  /// No description provided for @customIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha angle (°)'**
  String get customIsha;

  /// No description provided for @customIshaByMinutes.
  ///
  /// In en, this message translates to:
  /// **'Isha by minutes after Maghrib'**
  String get customIshaByMinutes;

  /// No description provided for @customIshaMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes after Maghrib'**
  String get customIshaMinutes;

  /// No description provided for @customAngleError.
  ///
  /// In en, this message translates to:
  /// **'Between 10° and 22°'**
  String get customAngleError;

  /// No description provided for @customMinutesError.
  ///
  /// In en, this message translates to:
  /// **'Between 1 and 180 minutes'**
  String get customMinutesError;

  /// No description provided for @asrStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get asrStandard;

  /// No description provided for @asrStandardHint.
  ///
  /// In en, this message translates to:
  /// **'Shafi\'i, Maliki, Hanbali: the earlier Asr time'**
  String get asrStandardHint;

  /// No description provided for @asrHanafi.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get asrHanafi;

  /// No description provided for @asrHanafiHint.
  ///
  /// In en, this message translates to:
  /// **'The later Asr time'**
  String get asrHanafiHint;

  /// No description provided for @ruleMiddleOfTheNightTitle.
  ///
  /// In en, this message translates to:
  /// **'Middle of the night'**
  String get ruleMiddleOfTheNightTitle;

  /// No description provided for @ruleSeventhOfTheNightTitle.
  ///
  /// In en, this message translates to:
  /// **'One seventh of the night'**
  String get ruleSeventhOfTheNightTitle;

  /// No description provided for @ruleTwilightAngleTitle.
  ///
  /// In en, this message translates to:
  /// **'Twilight angle'**
  String get ruleTwilightAngleTitle;

  /// No description provided for @ruleMiddleOfTheNightHint.
  ///
  /// In en, this message translates to:
  /// **'Fajr and Isha no later than the middle of the night (default)'**
  String get ruleMiddleOfTheNightHint;

  /// No description provided for @ruleSeventhOfTheNightHint.
  ///
  /// In en, this message translates to:
  /// **'Fajr and Isha within the first and last seventh of the night'**
  String get ruleSeventhOfTheNightHint;

  /// No description provided for @ruleTwilightAngleHint.
  ///
  /// In en, this message translates to:
  /// **'A share of the night proportional to the method\'s angles'**
  String get ruleTwilightAngleHint;

  /// No description provided for @highLatitudeSettingsNote.
  ///
  /// In en, this message translates to:
  /// **'Only used where the sun stays close to the horizon at night; elsewhere it changes nothing.'**
  String get highLatitudeSettingsNote;

  /// No description provided for @adjustmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Minutes added to or taken from the calculated time, for example to match your mosque\'s printed timetable.'**
  String get adjustmentsHint;

  /// No description provided for @adjustmentsMinus.
  ///
  /// In en, this message translates to:
  /// **'{prayer}: one minute earlier'**
  String adjustmentsMinus(String prayer);

  /// No description provided for @adjustmentsPlus.
  ///
  /// In en, this message translates to:
  /// **'{prayer}: one minute later'**
  String adjustmentsPlus(String prayer);

  /// No description provided for @adjustmentsValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String adjustmentsValue(int minutes);

  /// No description provided for @adjustmentsNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get adjustmentsNone;

  /// No description provided for @adjustmentsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset all to 0'**
  String get adjustmentsReset;

  /// No description provided for @settingsPauseAllIqama.
  ///
  /// In en, this message translates to:
  /// **'Pause all Jama’ah reminders'**
  String get settingsPauseAllIqama;

  /// No description provided for @settingsPauseAllIqamaHint.
  ///
  /// In en, this message translates to:
  /// **'No Jama’ah reminders from any mosque until you turn this off. Your Iqama times are kept. Adhan alerts are not affected.'**
  String get settingsPauseAllIqamaHint;

  /// No description provided for @mosquePauseReminders.
  ///
  /// In en, this message translates to:
  /// **'Pause this mosque\'s reminders'**
  String get mosquePauseReminders;

  /// No description provided for @mosquePauseRemindersHint.
  ///
  /// In en, this message translates to:
  /// **'Its Iqama times and reminder settings are kept. Applies while this is your active mosque.'**
  String get mosquePauseRemindersHint;

  /// No description provided for @mosquePauseAllOn.
  ///
  /// In en, this message translates to:
  /// **'All Jama’ah reminders are paused in Settings.'**
  String get mosquePauseAllOn;

  /// No description provided for @pausedAllNote.
  ///
  /// In en, this message translates to:
  /// **'All Jama’ah reminders are paused.'**
  String get pausedAllNote;

  /// No description provided for @pausedMosqueNote.
  ///
  /// In en, this message translates to:
  /// **'{mosque}\'s Jama’ah reminders are paused.'**
  String pausedMosqueNote(String mosque);

  /// No description provided for @tagRemindersPaused.
  ///
  /// In en, this message translates to:
  /// **'Reminders paused'**
  String get tagRemindersPaused;
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
