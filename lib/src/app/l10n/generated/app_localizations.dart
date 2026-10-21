import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

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
  /// **'Prayer times are calculated on this device. You set Iqama times for each mosque, and they stay on this phone.'**
  String get aboutBody;

  /// No description provided for @qiblaFrom.
  ///
  /// In en, this message translates to:
  /// **'From {place}'**
  String qiblaFrom(String place);

  /// No description provided for @qiblaDegrees.
  ///
  /// In en, this message translates to:
  /// **'{degrees}°'**
  String qiblaDegrees(String degrees);

  /// No description provided for @qiblaFromNorth.
  ///
  /// In en, this message translates to:
  /// **'{degrees}° from true north'**
  String qiblaFromNorth(String degrees);

  /// No description provided for @qiblaTurnRight.
  ///
  /// In en, this message translates to:
  /// **'Turn {degrees}° right'**
  String qiblaTurnRight(String degrees);

  /// No description provided for @qiblaTurnLeft.
  ///
  /// In en, this message translates to:
  /// **'Turn {degrees}° left'**
  String qiblaTurnLeft(String degrees);

  /// No description provided for @qiblaAligned.
  ///
  /// In en, this message translates to:
  /// **'Facing the Qibla'**
  String get qiblaAligned;

  /// No description provided for @qiblaDistance.
  ///
  /// In en, this message translates to:
  /// **'{distance} km to the Kaaba'**
  String qiblaDistance(String distance);

  /// No description provided for @qiblaHoldFlat.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone flat, away from metal and magnets.'**
  String get qiblaHoldFlat;

  /// No description provided for @qiblaDeclinationNote.
  ///
  /// In en, this message translates to:
  /// **'Measured from true north. The compass reads magnetic north, so {degrees}° is corrected for here.'**
  String qiblaDeclinationNote(String degrees);

  /// No description provided for @qiblaMagneticNote.
  ///
  /// In en, this message translates to:
  /// **'Measured from magnetic north, which can differ from true north by a few degrees.'**
  String get qiblaMagneticNote;

  /// No description provided for @qiblaNeedsCalibration.
  ///
  /// In en, this message translates to:
  /// **'The compass isn’t accurate right now.'**
  String get qiblaNeedsCalibration;

  /// No description provided for @qiblaCalibrate.
  ///
  /// In en, this message translates to:
  /// **'How to calibrate'**
  String get qiblaCalibrate;

  /// No description provided for @qiblaCalibrateTitle.
  ///
  /// In en, this message translates to:
  /// **'Calibrate the compass'**
  String get qiblaCalibrateTitle;

  /// No description provided for @qiblaCalibrateBody.
  ///
  /// In en, this message translates to:
  /// **'Move your phone in a slow figure-8 a few times, away from metal objects and magnets. The direction settles once the compass is accurate.'**
  String get qiblaCalibrateBody;

  /// No description provided for @qiblaCalibrateDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get qiblaCalibrateDone;

  /// No description provided for @qiblaNoCompassTitle.
  ///
  /// In en, this message translates to:
  /// **'Compass unavailable'**
  String get qiblaNoCompassTitle;

  /// No description provided for @qiblaNoCompassBody.
  ///
  /// In en, this message translates to:
  /// **'The Qibla is {degrees}° clockwise from true north for {place}. Use any compass or map app and face that bearing.'**
  String qiblaNoCompassBody(String degrees, String place);

  /// No description provided for @qiblaNeedsPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your location'**
  String get qiblaNeedsPlaceTitle;

  /// No description provided for @qiblaNeedsPlaceBody.
  ///
  /// In en, this message translates to:
  /// **'The direction of the Qibla is worked out on this device from where you are. Choose where you are to begin.'**
  String get qiblaNeedsPlaceBody;

  /// No description provided for @qiblaDialLabel.
  ///
  /// In en, this message translates to:
  /// **'Compass. The Qibla is {degrees}° from true north.'**
  String qiblaDialLabel(String degrees);

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

  /// No description provided for @jumuahEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Jumu’ah Khutbah'**
  String get jumuahEditorTitle;

  /// No description provided for @jumuahKhutbahTime.
  ///
  /// In en, this message translates to:
  /// **'Khutbah starts'**
  String get jumuahKhutbahTime;

  /// No description provided for @jumuahChooseKhutbahTime.
  ///
  /// In en, this message translates to:
  /// **'Choose Khutbah start time'**
  String get jumuahChooseKhutbahTime;

  /// No description provided for @jumuahKhutbahTimeNote.
  ///
  /// In en, this message translates to:
  /// **'Set the time the Khutbah begins at this mosque.'**
  String get jumuahKhutbahTimeNote;

  /// No description provided for @jumuahArrivalLeadTitle.
  ///
  /// In en, this message translates to:
  /// **'Minutes before Khutbah'**
  String get jumuahArrivalLeadTitle;

  /// No description provided for @jumuahSaved.
  ///
  /// In en, this message translates to:
  /// **'Jumu’ah Khutbah saved'**
  String get jumuahSaved;

  /// No description provided for @jumuahReminderLead.
  ///
  /// In en, this message translates to:
  /// **'Reminder {minutes} min before Khutbah'**
  String jumuahReminderLead(int minutes);

  /// No description provided for @jumuahReminderNeedsTime.
  ///
  /// In en, this message translates to:
  /// **'Set a Khutbah time to enable the reminder.'**
  String get jumuahReminderNeedsTime;

  /// No description provided for @jumuahReminderCustomEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter how many minutes before the Khutbah.'**
  String get jumuahReminderCustomEmpty;

  /// No description provided for @jumuahArriveBy.
  ///
  /// In en, this message translates to:
  /// **'Arrive by {time}'**
  String jumuahArriveBy(String time);

  /// No description provided for @jumuahReminderPreview.
  ///
  /// In en, this message translates to:
  /// **'Khutbah starts at {khutbah}. Your {minutes} min reminder is at {arrival}.'**
  String jumuahReminderPreview(String khutbah, int minutes, String arrival);

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
  /// **'Jama’ah reminders · {sound}'**
  String channelIqama(String sound);

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

  /// Title of every Jama’ah reminder: 'come to prayer', from the Adhan. Kept in Arabic in every language.
  ///
  /// In en, this message translates to:
  /// **'حيّ على الصلاة'**
  String get notifIqamaCall;

  /// No description provided for @notifIqamaBody.
  ///
  /// In en, this message translates to:
  /// **'{prayer} Iqama in {minutes} min, at {mosque}.'**
  String notifIqamaBody(String prayer, int minutes, String mosque);

  /// No description provided for @notifIqamaBodyNoMosque.
  ///
  /// In en, this message translates to:
  /// **'{prayer} Iqama in {minutes} min.'**
  String notifIqamaBodyNoMosque(String prayer, int minutes);

  /// No description provided for @scheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled notifications'**
  String get scheduledTitle;

  /// No description provided for @scheduledCount.
  ///
  /// In en, this message translates to:
  /// **'{count} scheduled for the next 14 days'**
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
  /// **'Plays a short part of the Adhan, chosen in Settings.'**
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
  /// **'Plays through the alarm volume, so you hear it on silent or vibrate. If Do Not Disturb blocks alarms, it stays quiet.'**
  String get alertRingInSilentHint;

  /// No description provided for @alertRingInSilentNeedsSound.
  ///
  /// In en, this message translates to:
  /// **'Silent has no sound to ring.'**
  String get alertRingInSilentNeedsSound;

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
  /// **'Stop it with either volume key, from the notification, or by turning the phone face down.'**
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
  /// **'Plays for every alert set to Full Adhan. Short Adhan is chosen separately in Settings.'**
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

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @latitudeNorth.
  ///
  /// In en, this message translates to:
  /// **'{degrees}°N'**
  String latitudeNorth(String degrees);

  /// No description provided for @latitudeSouth.
  ///
  /// In en, this message translates to:
  /// **'{degrees}°S'**
  String latitudeSouth(String degrees);

  /// The north letter on the Qibla compass dial.
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get compassNorth;

  /// No description provided for @compassSouth.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get compassSouth;

  /// No description provided for @recordingLength.
  ///
  /// In en, this message translates to:
  /// **'{minutes}:{seconds}'**
  String recordingLength(String minutes, String seconds);

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
  /// **'Far north or south'**
  String get settingsHighLatitude;

  /// No description provided for @settingsAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Adjust times by minutes'**
  String get settingsAdjustments;

  /// No description provided for @settingsHijri.
  ///
  /// In en, this message translates to:
  /// **'Hijri date'**
  String get settingsHijri;

  /// Shown when the place's time zone differs from the phone's, e.g. after a flight without changing the phone's zone.
  ///
  /// In en, this message translates to:
  /// **'Times are local time in {place} ({placeOffset}). Your phone\'s clock is on {phoneOffset}.'**
  String zoneNotePlace(String place, String placeOffset, String phoneOffset);

  /// No description provided for @inFlightTitle.
  ///
  /// In en, this message translates to:
  /// **'In flight'**
  String get inFlightTitle;

  /// No description provided for @onbStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onbStep(int current, int total);

  /// No description provided for @onbContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onbContinue;

  /// No description provided for @onbBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onbBack;

  /// No description provided for @onbNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onbNotNow;

  /// No description provided for @onbStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onbStart;

  /// No description provided for @onbWelcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Pray together, on time.'**
  String get onbWelcomeTagline;

  /// No description provided for @onbWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Know when to pray. Know when your mosque starts. Get a nudge before the congregation.'**
  String get onbWelcomeBody;

  /// No description provided for @onbLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get onbLanguage;

  /// No description provided for @onbPlaceFound.
  ///
  /// In en, this message translates to:
  /// **'Found you near {city}'**
  String onbPlaceFound(String city);

  /// No description provided for @placeNear.
  ///
  /// In en, this message translates to:
  /// **'{place}, near {city}'**
  String placeNear(String place, String city);

  /// No description provided for @onbPlaceDone.
  ///
  /// In en, this message translates to:
  /// **'Prayer times for {place}'**
  String onbPlaceDone(String place);

  /// No description provided for @onbMosqueTitle.
  ///
  /// In en, this message translates to:
  /// **'Your mosque'**
  String get onbMosqueTitle;

  /// No description provided for @onbMosqueBody.
  ///
  /// In en, this message translates to:
  /// **'Jama’ah means praying together. Add the mosque you pray at to see when its congregation starts, and get a nudge before it.'**
  String get onbMosqueBody;

  /// No description provided for @onbMosqueDone.
  ///
  /// In en, this message translates to:
  /// **'Added: {mosque}. Enter its Iqama times from the Mosques tab.'**
  String onbMosqueDone(String mosque);

  /// No description provided for @onbAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts'**
  String get onbAlertsTitle;

  /// No description provided for @onbAlertsBody.
  ///
  /// In en, this message translates to:
  /// **'An alert at each Adhan. You can choose the sound for each prayer later, from Today.'**
  String get onbAlertsBody;

  /// No description provided for @onbAlertsSwitch.
  ///
  /// In en, this message translates to:
  /// **'Alerts for the five prayers'**
  String get onbAlertsSwitch;

  /// No description provided for @onbAlertsSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Your phone will ask to allow notifications.'**
  String get onbAlertsSwitchHint;

  /// No description provided for @onbAlertsBattery.
  ///
  /// In en, this message translates to:
  /// **'Some phones stop apps in the background to save battery. If an alert ever comes late, let Jama’ah run unrestricted.'**
  String get onbAlertsBattery;

  /// No description provided for @onbTravelTitle.
  ///
  /// In en, this message translates to:
  /// **'Do you travel often?'**
  String get onbTravelTitle;

  /// No description provided for @onbTravelBody.
  ///
  /// In en, this message translates to:
  /// **'Travel mode follows your location, so times and the Qibla stay right wherever you land. On a plane it can show prayer times along the route.'**
  String get onbTravelBody;

  /// No description provided for @onbTravelSwitch.
  ///
  /// In en, this message translates to:
  /// **'Travel mode'**
  String get onbTravelSwitch;

  /// No description provided for @onbTravelHint.
  ///
  /// In en, this message translates to:
  /// **'You can switch it any time with the airplane at the top of the app.'**
  String get onbTravelHint;

  /// No description provided for @settingsShowIntro.
  ///
  /// In en, this message translates to:
  /// **'Show the introduction again'**
  String get settingsShowIntro;

  /// No description provided for @inFlightHelp.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get inFlightHelp;

  /// No description provided for @inFlightHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'In-flight mode'**
  String get inFlightHelpTitle;

  /// No description provided for @inFlightHelpIntro.
  ///
  /// In en, this message translates to:
  /// **'Prayer times and the Qibla on a plane, with no internet and without changing your phone\'s clock.'**
  String get inFlightHelpIntro;

  /// No description provided for @inFlightHelpStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Starting it'**
  String get inFlightHelpStartTitle;

  /// No description provided for @inFlightHelpStartBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on travel mode with the airplane at the top of the app. On Today, tap “On a flight?”, then “Start GPS” and allow precise location. Sit by a window if you can: the phone\'s GPS works in airplane mode, but needs a view of the sky and can take a minute or two to find you.'**
  String get inFlightHelpStartBody;

  /// No description provided for @inFlightHelpTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'The prayer times'**
  String get inFlightHelpTimesTitle;

  /// No description provided for @inFlightHelpTimesBody.
  ///
  /// In en, this message translates to:
  /// **'“Now” and “Next” are for where the aircraft is at this moment, shown on your phone\'s clock. Up high, the sun sets later and rises earlier than on the ground below, so Maghrib and sunrise follow the sun as you see it from the aircraft. Fajr and Isha follow your calculation method.'**
  String get inFlightHelpTimesBody;

  /// No description provided for @inFlightHelpRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Along the route'**
  String get inFlightHelpRouteTitle;

  /// No description provided for @inFlightHelpRouteBody.
  ///
  /// In en, this message translates to:
  /// **'While the aircraft is moving, Jama’ah estimates when you will meet the next prayers if it keeps the same course and speed. The estimate updates with each GPS reading, so it gets better as the flight goes on. Flying east, prayers come sooner; flying west, the aircraft almost keeps pace with the sun, so sunset can stay hours away.'**
  String get inFlightHelpRouteBody;

  /// No description provided for @inFlightHelpQiblaTitle.
  ///
  /// In en, this message translates to:
  /// **'The Qibla aboard'**
  String get inFlightHelpQiblaTitle;

  /// No description provided for @inFlightHelpQiblaBody.
  ///
  /// In en, this message translates to:
  /// **'The phone\'s compass is not reliable inside an aircraft, so the arrow uses the direction the aircraft is flying, from GPS. It shows how far to the right or left of the nose the Qibla is. On the ground, or if you prefer, enter the heading shown on the seat-back map.'**
  String get inFlightHelpQiblaBody;

  /// No description provided for @inFlightHelpAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts in flight'**
  String get inFlightHelpAlertsTitle;

  /// No description provided for @inFlightHelpAlertsBody.
  ///
  /// In en, this message translates to:
  /// **'While the aircraft is moving, your usual alerts for the place you left are paused, Jama’ah reminders too, and the next prayer along the route is alerted instead, marked as estimated. It uses that prayer\'s own Adhan settings. The pause ends by itself 90 minutes after the last GPS reading, or when you tap “End in-flight mode”. At home or at the gate nothing is paused.'**
  String get inFlightHelpAlertsBody;

  /// No description provided for @inFlightHelpTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get inFlightHelpTipsTitle;

  /// No description provided for @inFlightHelpTipsBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the in-flight screen open for the best updates; with the screen off for long, the phone may pause GPS. Nothing about where you are is sent anywhere. Questions about how to pray aboard, such as shortening or combining prayers, are for your scholar: Jama’ah gives the times and the direction only.'**
  String get inFlightHelpTipsBody;

  /// No description provided for @notifInFlightBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s time for {prayer}, estimated for the aircraft\'s route.'**
  String notifInFlightBody(String prayer);

  /// No description provided for @inFlightAlongRoute.
  ///
  /// In en, this message translates to:
  /// **'Along this route: {prayer}, {countdown}'**
  String inFlightAlongRoute(String prayer, String countdown);

  /// No description provided for @inFlightAlongRouteThen.
  ///
  /// In en, this message translates to:
  /// **'Then {prayer}, about {time} on your phone'**
  String inFlightAlongRouteThen(String prayer, String time);

  /// No description provided for @inFlightAboutOnPhone.
  ///
  /// In en, this message translates to:
  /// **'About {time} on your phone'**
  String inFlightAboutOnPhone(String time);

  /// No description provided for @inFlightAssumesCourse.
  ///
  /// In en, this message translates to:
  /// **'Assumes the aircraft keeps its course and speed; updated with each GPS fix.'**
  String get inFlightAssumesCourse;

  /// No description provided for @inFlightAlertsHeld.
  ///
  /// In en, this message translates to:
  /// **'Alerts for {place} are paused until {time}. The next prayer along the route is alerted instead.'**
  String inFlightAlertsHeld(String place, String time);

  /// No description provided for @inFlightEnd.
  ///
  /// In en, this message translates to:
  /// **'End in-flight mode'**
  String get inFlightEnd;

  /// No description provided for @inFlightHeldNote.
  ///
  /// In en, this message translates to:
  /// **'In-flight mode: regular alerts are paused until {time}.'**
  String inFlightHeldNote(String time);

  /// No description provided for @inFlightCardTitle.
  ///
  /// In en, this message translates to:
  /// **'On a flight?'**
  String get inFlightCardTitle;

  /// No description provided for @inFlightCardBody.
  ///
  /// In en, this message translates to:
  /// **'Prayer times and the Qibla aboard, from GPS, with no network.'**
  String get inFlightCardBody;

  /// No description provided for @inFlightExplainBody.
  ///
  /// In en, this message translates to:
  /// **'Jama’ah uses your phone\'s GPS, which works in airplane mode, to find where the aircraft is. It needs precise location, and works best by a window. Nothing is sent anywhere.'**
  String get inFlightExplainBody;

  /// No description provided for @inFlightStart.
  ///
  /// In en, this message translates to:
  /// **'Start GPS'**
  String get inFlightStart;

  /// No description provided for @inFlightWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS… A window seat helps.'**
  String get inFlightWaiting;

  /// No description provided for @inFlightServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location is off on this phone. Turn it on to use GPS aboard.'**
  String get inFlightServiceOff;

  /// No description provided for @inFlightNeedsPrecise.
  ///
  /// In en, this message translates to:
  /// **'In-flight mode needs precise location. Try again and choose “Precise”.'**
  String get inFlightNeedsPrecise;

  /// No description provided for @inFlightPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Precise location is turned off for Jama’ah. You can allow it in the app\'s settings.'**
  String get inFlightPermanentlyDenied;

  /// No description provided for @inFlightOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get inFlightOpenSettings;

  /// No description provided for @inFlightTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get inFlightTryAgain;

  /// No description provided for @inFlightAltitudeSpeed.
  ///
  /// In en, this message translates to:
  /// **'{altitude} m · {speed} km/h'**
  String inFlightAltitudeSpeed(String altitude, String speed);

  /// No description provided for @inFlightFixAge.
  ///
  /// In en, this message translates to:
  /// **'GPS fix {ago}'**
  String inFlightFixAge(String ago);

  /// No description provided for @inFlightFixLost.
  ///
  /// In en, this message translates to:
  /// **'GPS lost. Showing the last fix, from {ago}.'**
  String inFlightFixLost(String ago);

  /// No description provided for @inFlightNow.
  ///
  /// In en, this message translates to:
  /// **'Now: {prayer}'**
  String inFlightNow(String prayer);

  /// No description provided for @inFlightNoneNow.
  ///
  /// In en, this message translates to:
  /// **'No prayer is due now'**
  String get inFlightNoneNow;

  /// No description provided for @inFlightNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {prayer}, {countdown}'**
  String inFlightNext(String prayer, String countdown);

  /// No description provided for @inFlightOnPhone.
  ///
  /// In en, this message translates to:
  /// **'{time} on your phone'**
  String inFlightOnPhone(String time);

  /// No description provided for @inFlightSunsetLater.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{From up here the sun sets 1 min later than on the ground below.} other{From up here the sun sets {minutes} min later than on the ground below.}}'**
  String inFlightSunsetLater(int minutes);

  /// No description provided for @inFlightSunriseEarlier.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{From up here the sun rises 1 min earlier than on the ground below.} other{From up here the sun rises {minutes} min earlier than on the ground below.}}'**
  String inFlightSunriseEarlier(int minutes);

  /// No description provided for @inFlightMovingNote.
  ///
  /// In en, this message translates to:
  /// **'For where the aircraft is now. As it flies on, these times change; this screen keeps them up to date while it is open.'**
  String get inFlightMovingNote;

  /// No description provided for @inFlightTimesHeader.
  ///
  /// In en, this message translates to:
  /// **'Today aboard, on your phone\'s clock'**
  String get inFlightTimesHeader;

  /// No description provided for @inFlightQiblaHeader.
  ///
  /// In en, this message translates to:
  /// **'Qibla aboard'**
  String get inFlightQiblaHeader;

  /// No description provided for @inFlightQiblaRight.
  ///
  /// In en, this message translates to:
  /// **'{degrees}° to the right of the nose'**
  String inFlightQiblaRight(String degrees);

  /// No description provided for @inFlightQiblaLeft.
  ///
  /// In en, this message translates to:
  /// **'{degrees}° to the left of the nose'**
  String inFlightQiblaLeft(String degrees);

  /// No description provided for @inFlightQiblaAhead.
  ///
  /// In en, this message translates to:
  /// **'Straight ahead'**
  String get inFlightQiblaAhead;

  /// No description provided for @inFlightQiblaBehind.
  ///
  /// In en, this message translates to:
  /// **'Behind you, towards the tail'**
  String get inFlightQiblaBehind;

  /// No description provided for @inFlightHeadingGps.
  ///
  /// In en, this message translates to:
  /// **'Using the aircraft\'s GPS course, {degrees}°'**
  String inFlightHeadingGps(String degrees);

  /// No description provided for @inFlightHeadingManual.
  ///
  /// In en, this message translates to:
  /// **'Using your heading, {degrees}°'**
  String inFlightHeadingManual(String degrees);

  /// No description provided for @inFlightNoCourse.
  ///
  /// In en, this message translates to:
  /// **'The aircraft isn\'t moving yet, so there is no course. You can enter the heading from the seat-back map.'**
  String get inFlightNoCourse;

  /// No description provided for @inFlightEnterHeading.
  ///
  /// In en, this message translates to:
  /// **'Enter heading'**
  String get inFlightEnterHeading;

  /// No description provided for @inFlightUseGps.
  ///
  /// In en, this message translates to:
  /// **'Use GPS course'**
  String get inFlightUseGps;

  /// No description provided for @inFlightHeadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Heading from the seat-back map (0–359°)'**
  String get inFlightHeadingLabel;

  /// No description provided for @inFlightHeadingError.
  ///
  /// In en, this message translates to:
  /// **'Between 0 and 359'**
  String get inFlightHeadingError;

  /// No description provided for @inFlightQiblaBearing.
  ///
  /// In en, this message translates to:
  /// **'Qibla bearing {degrees}° from true north'**
  String inFlightQiblaBearing(String degrees);

  /// No description provided for @inFlightCompassNote.
  ///
  /// In en, this message translates to:
  /// **'The phone\'s compass isn\'t reliable inside an aircraft, so this uses the aircraft\'s direction instead.'**
  String get inFlightCompassNote;

  /// No description provided for @inFlightDiagramLabel.
  ///
  /// In en, this message translates to:
  /// **'Aircraft seen from above, nose up. The arrow points to the Qibla.'**
  String get inFlightDiagramLabel;

  /// No description provided for @zoneNoteHere.
  ///
  /// In en, this message translates to:
  /// **'Times are local time where you are ({placeOffset}). Your phone\'s clock is on {phoneOffset}.'**
  String zoneNoteHere(String placeOffset, String phoneOffset);

  /// No description provided for @hijriAsCalculated.
  ///
  /// In en, this message translates to:
  /// **'As calculated (Umm al-Qura)'**
  String get hijriAsCalculated;

  /// No description provided for @hijriLater.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day later} other{{days} days later}}'**
  String hijriLater(int days);

  /// No description provided for @hijriEarlier.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day earlier} other{{days} days earlier}}'**
  String hijriEarlier(int days);

  /// No description provided for @hijriAdjustNote.
  ///
  /// In en, this message translates to:
  /// **'Match the date your country announces. Kuwait and others start each month by moon sighting, which can differ from the calculation by a day or two. Prayer times stay as they are, except that with Umm al-Qura, Ramadan\'s later Isha follows this date.'**
  String get hijriAdjustNote;

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

  /// No description provided for @reminderSoundChime.
  ///
  /// In en, this message translates to:
  /// **'Chime'**
  String get reminderSoundChime;

  /// No description provided for @shortAdhanClipHint.
  ///
  /// In en, this message translates to:
  /// **'Preview this supplied short Adhan recording.'**
  String get shortAdhanClipHint;

  /// No description provided for @settingsShortAdhan.
  ///
  /// In en, this message translates to:
  /// **'Short Adhan'**
  String get settingsShortAdhan;

  /// No description provided for @settingsReminderSound.
  ///
  /// In en, this message translates to:
  /// **'Reminder sound'**
  String get settingsReminderSound;

  /// No description provided for @reminderSoundChimeHint.
  ///
  /// In en, this message translates to:
  /// **'A soft two-note chime, different from the Adhan and from other apps.'**
  String get reminderSoundChimeHint;

  /// No description provided for @reminderSoundStandardHint.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s usual notification sound.'**
  String get reminderSoundStandardHint;

  /// No description provided for @reminderSoundSilentHint.
  ///
  /// In en, this message translates to:
  /// **'Shown in your notifications without any sound.'**
  String get reminderSoundSilentHint;

  /// No description provided for @settingsReminderVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get settingsReminderVibrate;

  /// No description provided for @settingsPauseAllIqama.
  ///
  /// In en, this message translates to:
  /// **'Pause all Jama’ah reminders'**
  String get settingsPauseAllIqama;

  /// No description provided for @settingsPauseAllIqamaHint.
  ///
  /// In en, this message translates to:
  /// **'From every mosque. Iqama times are kept, and Adhan alerts carry on.'**
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

  /// No description provided for @prayerJumuah.
  ///
  /// In en, this message translates to:
  /// **'Jumu’ah'**
  String get prayerJumuah;

  /// No description provided for @extraImsak.
  ///
  /// In en, this message translates to:
  /// **'Imsak'**
  String get extraImsak;

  /// No description provided for @extraDuha.
  ///
  /// In en, this message translates to:
  /// **'Duha'**
  String get extraDuha;

  /// No description provided for @extraQiyam.
  ///
  /// In en, this message translates to:
  /// **'Last third of the night'**
  String get extraQiyam;

  /// No description provided for @notifImsakBody.
  ///
  /// In en, this message translates to:
  /// **'Imsak: stop eating before Fajr.'**
  String get notifImsakBody;

  /// No description provided for @notifDuhaBody.
  ///
  /// In en, this message translates to:
  /// **'The time for Duha prayer has begun.'**
  String get notifDuhaBody;

  /// No description provided for @notifQiyamBody.
  ///
  /// In en, this message translates to:
  /// **'The last third of the night has begun.'**
  String get notifQiyamBody;

  /// No description provided for @channelExtra.
  ///
  /// In en, this message translates to:
  /// **'Other times · {sound}'**
  String channelExtra(String sound);

  /// No description provided for @kindExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra time'**
  String get kindExtra;

  /// No description provided for @settingsExtraTimes.
  ///
  /// In en, this message translates to:
  /// **'Extra times'**
  String get settingsExtraTimes;

  /// No description provided for @extraTimesIntro.
  ///
  /// In en, this message translates to:
  /// **'Times beside the five prayers, worked out from your prayer times. They have no Iqama.'**
  String get extraTimesIntro;

  /// No description provided for @extraShowOnToday.
  ///
  /// In en, this message translates to:
  /// **'Show on Today'**
  String get extraShowOnToday;

  /// No description provided for @extraAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get extraAlert;

  /// No description provided for @extraAlertHint.
  ///
  /// In en, this message translates to:
  /// **'Uses your Jama’ah reminder sound.'**
  String get extraAlertHint;

  /// No description provided for @extraImsakRule.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before Fajr'**
  String extraImsakRule(int minutes);

  /// No description provided for @extraDuhaRule.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min after sunrise'**
  String extraDuhaRule(int minutes);

  /// No description provided for @extraQiyamRule.
  ///
  /// In en, this message translates to:
  /// **'The last third of the time from Maghrib to Fajr.'**
  String get extraQiyamRule;

  /// No description provided for @extraNoneShown.
  ///
  /// In en, this message translates to:
  /// **'None shown'**
  String get extraNoneShown;

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @jumuahNotSetNote.
  ///
  /// In en, this message translates to:
  /// **'Jumu’ah time not set · showing Dhuhr Iqama'**
  String get jumuahNotSetNote;

  /// No description provided for @jumuahRowHint.
  ///
  /// In en, this message translates to:
  /// **'Fridays, in place of Dhuhr'**
  String get jumuahRowHint;

  /// No description provided for @jumuahRowNotSet.
  ///
  /// In en, this message translates to:
  /// **'Jumu’ah time not set'**
  String get jumuahRowNotSet;

  /// No description provided for @settingsAdhanRingInSilent.
  ///
  /// In en, this message translates to:
  /// **'Adhan rings on silent'**
  String get settingsAdhanRingInSilent;

  /// No description provided for @settingsPreAdhanRingInSilent.
  ///
  /// In en, this message translates to:
  /// **'Reminders before the Adhan ring on silent'**
  String get settingsPreAdhanRingInSilent;

  /// No description provided for @ringInSilentSome.
  ///
  /// In en, this message translates to:
  /// **'On for some prayers. Each prayer’s page can change it.'**
  String get ringInSilentSome;

  /// No description provided for @alertPreAdhanRingInSilent.
  ///
  /// In en, this message translates to:
  /// **'Reminder rings on silent'**
  String get alertPreAdhanRingInSilent;

  /// No description provided for @onbRingInSilent.
  ///
  /// In en, this message translates to:
  /// **'Ring even when my phone is on silent'**
  String get onbRingInSilent;

  /// No description provided for @onbRingInSilentHint.
  ///
  /// In en, this message translates to:
  /// **'For the Adhan, the reminder before it and Jama’ah reminders, through the alarm volume. You can change each one in Settings.'**
  String get onbRingInSilentHint;

  /// No description provided for @iqamaModeAfterAdhan.
  ///
  /// In en, this message translates to:
  /// **'Minutes after Adhan'**
  String get iqamaModeAfterAdhan;

  /// No description provided for @iqamaModeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed time'**
  String get iqamaModeFixed;

  /// No description provided for @iqamaMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes after the Adhan'**
  String get iqamaMinutesLabel;

  /// No description provided for @iqamaAfterAdhanPreview.
  ///
  /// In en, this message translates to:
  /// **'Adhan {adhan} + {minutes} min = Iqama {iqama} today'**
  String iqamaAfterAdhanPreview(String adhan, int minutes, String iqama);

  /// No description provided for @iqamaMinutesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter 1 to 90 minutes'**
  String get iqamaMinutesInvalid;

  /// No description provided for @iqamaNeedsAdhan.
  ///
  /// In en, this message translates to:
  /// **'Set your location to see today’s time.'**
  String get iqamaNeedsAdhan;

  /// No description provided for @rowAfterAdhan.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min after Adhan'**
  String rowAfterAdhan(int minutes);

  /// No description provided for @enterAllFive.
  ///
  /// In en, this message translates to:
  /// **'Enter minutes for all five'**
  String get enterAllFive;

  /// No description provided for @enterAllFiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Iqama: minutes after the Adhan'**
  String get enterAllFiveTitle;

  /// No description provided for @enterAllFiveHint.
  ///
  /// In en, this message translates to:
  /// **'As your mosque publishes them, e.g. Fajr 22. Empty fields stay as they are.'**
  String get enterAllFiveHint;

  /// No description provided for @iqamaAfterAdhanPreviewTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Adhan {adhan} + {minutes} min = Iqama {iqama} tomorrow'**
  String iqamaAfterAdhanPreviewTomorrow(
    String adhan,
    int minutes,
    String iqama,
  );

  /// No description provided for @reminderSoundCustom.
  ///
  /// In en, this message translates to:
  /// **'Your own sound'**
  String get reminderSoundCustom;

  /// No description provided for @reminderSoundCustomHint.
  ///
  /// In en, this message translates to:
  /// **'A file from your phone. Plays for up to 30 seconds.'**
  String get reminderSoundCustomHint;

  /// No description provided for @reminderSoundCustomNamed.
  ///
  /// In en, this message translates to:
  /// **'Your own: {name}'**
  String reminderSoundCustomNamed(String name);

  /// No description provided for @recordingsYours.
  ///
  /// In en, this message translates to:
  /// **'Your recordings'**
  String get recordingsYours;

  /// No description provided for @soundAddFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Add from your phone'**
  String get soundAddFromPhone;

  /// No description provided for @soundRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get soundRename;

  /// No description provided for @soundDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get soundDelete;

  /// No description provided for @soundName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get soundName;

  /// No description provided for @soundDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”? Anything using it goes back to the built-in sound.'**
  String soundDeleteConfirm(String name);

  /// No description provided for @soundCouldNotAdd.
  ///
  /// In en, this message translates to:
  /// **'That file could not be added.'**
  String get soundCouldNotAdd;

  /// No description provided for @recordingPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'This recording could not be played.'**
  String get recordingPreviewFailed;

  /// No description provided for @soundOptions.
  ///
  /// In en, this message translates to:
  /// **'Options for {name}'**
  String soundOptions(String name);

  /// No description provided for @prayerRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get prayerRecording;

  /// No description provided for @prayerRecordingSame.
  ///
  /// In en, this message translates to:
  /// **'Same as in Settings ({name})'**
  String prayerRecordingSame(String name);

  /// No description provided for @prayerRecordingHint.
  ///
  /// In en, this message translates to:
  /// **'Plays when this prayer’s sound is Full Adhan.'**
  String get prayerRecordingHint;

  /// No description provided for @recordingsForPrayer.
  ///
  /// In en, this message translates to:
  /// **'Recording for {prayer}'**
  String recordingsForPrayer(String prayer);

  /// No description provided for @heroKickerTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Next prayer · tomorrow'**
  String get heroKickerTomorrow;

  /// No description provided for @heroKickerHeld.
  ///
  /// In en, this message translates to:
  /// **'{prayer} · Iqama {countdown}'**
  String heroKickerHeld(String prayer, String countdown);

  /// No description provided for @heroKickerAdhan.
  ///
  /// In en, this message translates to:
  /// **'Adhan'**
  String get heroKickerAdhan;

  /// No description provided for @heroKickerInForce.
  ///
  /// In en, this message translates to:
  /// **'In force at {time}'**
  String heroKickerInForce(String time);

  /// No description provided for @heroKickerSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise · not a prayer'**
  String get heroKickerSunrise;

  /// No description provided for @heroBackToNow.
  ///
  /// In en, this message translates to:
  /// **'Back to now'**
  String get heroBackToNow;

  /// No description provided for @heroMeta.
  ///
  /// In en, this message translates to:
  /// **'{period} · {relative}'**
  String heroMeta(String period, String relative);

  /// No description provided for @heroAdhanAgo.
  ///
  /// In en, this message translates to:
  /// **'Adhan {ago}'**
  String heroAdhanAgo(String ago);

  /// No description provided for @sunNow.
  ///
  /// In en, this message translates to:
  /// **'Now {time}'**
  String sunNow(String time);

  /// No description provided for @sunPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Look through the day'**
  String get sunPathLabel;

  /// No description provided for @sunPathValue.
  ///
  /// In en, this message translates to:
  /// **'{time}, {prayer}'**
  String sunPathValue(String time, String prayer);

  /// No description provided for @placeSubline.
  ///
  /// In en, this message translates to:
  /// **'{date} · {hijri}'**
  String placeSubline(String date, String hijri);

  /// No description provided for @placeButtonSemantics.
  ///
  /// In en, this message translates to:
  /// **'Place: {place}. Change place'**
  String placeButtonSemantics(String place);

  /// No description provided for @moreNotes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more note} other{{count} more notes}}'**
  String moreNotes(int count);

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// No description provided for @ticketKicker.
  ///
  /// In en, this message translates to:
  /// **'Iqama · {mosque}'**
  String ticketKicker(String mosque);

  /// No description provided for @jumuahTicketKicker.
  ///
  /// In en, this message translates to:
  /// **'Khutbah · {mosque}'**
  String jumuahTicketKicker(String mosque);

  /// No description provided for @jumuahTicketSemantics.
  ///
  /// In en, this message translates to:
  /// **'Khutbah at {mosque}: {time}, {relative}. {rule}. {reminder}.'**
  String jumuahTicketSemantics(
    String mosque,
    String time,
    String relative,
    String rule,
    String reminder,
  );

  /// No description provided for @jumuahTicketUnsetSemantics.
  ///
  /// In en, this message translates to:
  /// **'Khutbah at {mosque}: not configured. Set time'**
  String jumuahTicketUnsetSemantics(String mosque);

  /// No description provided for @ticketWhen.
  ///
  /// In en, this message translates to:
  /// **'· {relative}'**
  String ticketWhen(String relative);

  /// No description provided for @ticketRuleAfter.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Adhan + 1 min · set by you} other{Adhan + {minutes} min · set by you}}'**
  String ticketRuleAfter(int minutes);

  /// No description provided for @ticketRuleFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed time · set by you'**
  String get ticketRuleFixed;

  /// No description provided for @ticketReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder {time}'**
  String ticketReminder(String time);

  /// No description provided for @ticketNoReminder.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get ticketNoReminder;

  /// No description provided for @ticketSetTime.
  ///
  /// In en, this message translates to:
  /// **'Set time'**
  String get ticketSetTime;

  /// No description provided for @ticketSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise ends the time for Fajr. It has no Iqama.'**
  String get ticketSunrise;

  /// No description provided for @ticketNoMosque.
  ///
  /// In en, this message translates to:
  /// **'Add your mosque to see when its congregation starts.'**
  String get ticketNoMosque;

  /// No description provided for @ticketJumuahNotSet.
  ///
  /// In en, this message translates to:
  /// **'Jumu’ah time not set · Dhuhr Iqama {time}'**
  String ticketJumuahNotSet(String time);

  /// No description provided for @ticketSemantics.
  ///
  /// In en, this message translates to:
  /// **'Iqama at {mosque}: {time}, {relative}. {rule}. {reminder}.'**
  String ticketSemantics(
    String mosque,
    String time,
    String relative,
    String rule,
    String reminder,
  );

  /// No description provided for @ticketUnsetSemantics.
  ///
  /// In en, this message translates to:
  /// **'Iqama at {mosque}: not configured. Set time'**
  String ticketUnsetSemantics(String mosque);

  /// No description provided for @alertShortFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get alertShortFull;

  /// No description provided for @alertShortShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get alertShortShort;

  /// No description provided for @alertShortStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get alertShortStandard;

  /// No description provided for @alertShortSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get alertShortSilent;

  /// No description provided for @alertShortOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get alertShortOff;

  /// No description provided for @alertSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'{prayer} alert'**
  String alertSheetTitle(String prayer);

  /// No description provided for @alertSheetAdhan.
  ///
  /// In en, this message translates to:
  /// **'Adhan {time}'**
  String alertSheetAdhan(String time);

  /// No description provided for @alertGroupSound.
  ///
  /// In en, this message translates to:
  /// **'Notify with sound'**
  String get alertGroupSound;

  /// No description provided for @alertGroupQuiet.
  ///
  /// In en, this message translates to:
  /// **'Notify without sound'**
  String get alertGroupQuiet;

  /// No description provided for @alertDescSilent.
  ///
  /// In en, this message translates to:
  /// **'Shown in the notification shade, no sound'**
  String get alertDescSilent;

  /// No description provided for @alertDescOff.
  ///
  /// In en, this message translates to:
  /// **'No notification at all'**
  String get alertDescOff;

  /// No description provided for @alertDefaultMark.
  ///
  /// In en, this message translates to:
  /// **'{label} · Default'**
  String alertDefaultMark(String label);

  /// No description provided for @alertDefaultSuffix.
  ///
  /// In en, this message translates to:
  /// **'{label} · default'**
  String alertDefaultSuffix(String label);

  /// No description provided for @alertDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get alertDone;

  /// No description provided for @alertButtonSemantics.
  ///
  /// In en, this message translates to:
  /// **'{prayer} Adhan alert: {mode}. Change'**
  String alertButtonSemantics(String prayer, String mode);

  /// No description provided for @rowIqamaNotSet.
  ///
  /// In en, this message translates to:
  /// **'Iqama not set'**
  String get rowIqamaNotSet;

  /// No description provided for @sunLabelCombined.
  ///
  /// In en, this message translates to:
  /// **'{prayer} · {time}'**
  String sunLabelCombined(String prayer, String time);

  /// No description provided for @placeNearCity.
  ///
  /// In en, this message translates to:
  /// **'Near {city}'**
  String placeNearCity(String city);

  /// No description provided for @mosquesLead.
  ///
  /// In en, this message translates to:
  /// **'Today and your Jama’ah reminders follow your active mosque, now {mosque}.'**
  String mosquesLead(String mosque);

  /// No description provided for @mosquesLeadNoActive.
  ///
  /// In en, this message translates to:
  /// **'Make one mosque active and Today follows it.'**
  String get mosquesLeadNoActive;

  /// No description provided for @mosquesFindNearby.
  ///
  /// In en, this message translates to:
  /// **'Find nearby'**
  String get mosquesFindNearby;

  /// No description provided for @mosquesAddManually.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get mosquesAddManually;

  /// No description provided for @mosqueSourceGoogleUnverified.
  ///
  /// In en, this message translates to:
  /// **'From Google Maps · not verified'**
  String get mosqueSourceGoogleUnverified;

  /// No description provided for @mosqueSourceOsmUnverified.
  ///
  /// In en, this message translates to:
  /// **'From OpenStreetMap · not verified'**
  String get mosqueSourceOsmUnverified;

  /// No description provided for @mosqueNoIqamaYet.
  ///
  /// In en, this message translates to:
  /// **'No Iqama set yet'**
  String get mosqueNoIqamaYet;

  /// No description provided for @mosqueActiveLong.
  ///
  /// In en, this message translates to:
  /// **'Active · Today uses this mosque'**
  String get mosqueActiveLong;

  /// No description provided for @mosqueMakeActive.
  ///
  /// In en, this message translates to:
  /// **'Make active'**
  String get mosqueMakeActive;

  /// No description provided for @mosqueMadeActive.
  ///
  /// In en, this message translates to:
  /// **'{mosque} is now your active mosque'**
  String mosqueMadeActive(String mosque);

  /// No description provided for @mosquesFooter.
  ///
  /// In en, this message translates to:
  /// **'Mosques found online show where they came from and are not verified. Your Iqama times stay on this phone.'**
  String get mosquesFooter;

  /// No description provided for @mosquesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'There’s a place for you'**
  String get mosquesEmptyTitle;

  /// No description provided for @mosquesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add the mosque you pray at. Jama’ah will show when its congregation starts and remind you before it.'**
  String get mosquesEmptyBody;

  /// No description provided for @mosquesEmptyFind.
  ///
  /// In en, this message translates to:
  /// **'Find mosques nearby'**
  String get mosquesEmptyFind;

  /// No description provided for @mosquesEmptyAdd.
  ///
  /// In en, this message translates to:
  /// **'Add one yourself'**
  String get mosquesEmptyAdd;

  /// No description provided for @mosquesEmptyNote.
  ///
  /// In en, this message translates to:
  /// **'You enter its Iqama times. Nothing is guessed, and nothing leaves your phone.'**
  String get mosquesEmptyNote;

  /// No description provided for @mosqueRowSemantics.
  ///
  /// In en, this message translates to:
  /// **'{mosque}. {source}. {count}'**
  String mosqueRowSemantics(String mosque, String source, String count);

  /// No description provided for @mosqueKicker.
  ///
  /// In en, this message translates to:
  /// **'Your mosque'**
  String get mosqueKicker;

  /// No description provided for @mosqueNextJamaah.
  ///
  /// In en, this message translates to:
  /// **'Next Jama’ah · {prayer} {time} · {relative}'**
  String mosqueNextJamaah(String prayer, String time, String relative);

  /// No description provided for @mosqueNoNextJamaah.
  ///
  /// In en, this message translates to:
  /// **'No more Jama’ah set for today'**
  String get mosqueNoNextJamaah;

  /// No description provided for @mosquePauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause Jama’ah reminders'**
  String get mosquePauseTitle;

  /// No description provided for @mosquePauseHint.
  ///
  /// In en, this message translates to:
  /// **'Your Iqama times and settings are kept.'**
  String get mosquePauseHint;

  /// No description provided for @scheduleSection.
  ///
  /// In en, this message translates to:
  /// **'Iqama schedule'**
  String get scheduleSection;

  /// No description provided for @scheduleTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a prayer to set it'**
  String get scheduleTapHint;

  /// No description provided for @rowAdhanPlus.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Adhan + 1 min} other{Adhan + {minutes} min}}'**
  String rowAdhanPlus(int minutes);

  /// No description provided for @rowFixedTime.
  ///
  /// In en, this message translates to:
  /// **'Fixed time'**
  String get rowFixedTime;

  /// No description provided for @rowPausedReminder.
  ///
  /// In en, this message translates to:
  /// **'Paused · Reminder at {time}'**
  String rowPausedReminder(String time);

  /// No description provided for @reminderSwitchNeedsIqama.
  ///
  /// In en, this message translates to:
  /// **'{prayer} Jama’ah reminder, available once an Iqama time is set'**
  String reminderSwitchNeedsIqama(String prayer);

  /// No description provided for @scheduleNeverFills.
  ///
  /// In en, this message translates to:
  /// **'The app never fills in an Iqama.'**
  String get scheduleNeverFills;

  /// No description provided for @removeThisMosque.
  ///
  /// In en, this message translates to:
  /// **'Remove this mosque'**
  String get removeThisMosque;

  /// No description provided for @mosqueBack.
  ///
  /// In en, this message translates to:
  /// **'Back to Mosques'**
  String get mosqueBack;

  /// No description provided for @iqamaRowSet.
  ///
  /// In en, this message translates to:
  /// **'Edit {prayer} Iqama'**
  String iqamaRowSet(String prayer);

  /// No description provided for @iqamaRowUnset.
  ///
  /// In en, this message translates to:
  /// **'Set {prayer} Iqama'**
  String iqamaRowUnset(String prayer);

  /// No description provided for @scheduleFooter.
  ///
  /// In en, this message translates to:
  /// **'Set by you · last updated {date}. The app never fills in an Iqama.'**
  String scheduleFooter(String date);

  /// No description provided for @iqamaEditorSub.
  ///
  /// In en, this message translates to:
  /// **'{mosque} · Adhan {time} today'**
  String iqamaEditorSub(String mosque, String time);

  /// No description provided for @iqamaEditorSubFriday.
  ///
  /// In en, this message translates to:
  /// **'{mosque} · Fridays, in place of Dhuhr'**
  String iqamaEditorSubFriday(String mosque);

  /// No description provided for @iqamaModeAfterDesc.
  ///
  /// In en, this message translates to:
  /// **'Moves with the Adhan'**
  String get iqamaModeAfterDesc;

  /// No description provided for @iqamaModeFixedDesc.
  ///
  /// In en, this message translates to:
  /// **'Same time every day'**
  String get iqamaModeFixedDesc;

  /// No description provided for @iqamaMinutesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Choose how many minutes after the Adhan this mosque starts. Nothing is saved until you do.'**
  String get iqamaMinutesEmpty;

  /// No description provided for @iqamaFixedEmptyNote.
  ///
  /// In en, this message translates to:
  /// **'Nothing is saved until you choose a time.'**
  String get iqamaFixedEmptyNote;

  /// No description provided for @iqamaFixedNote.
  ///
  /// In en, this message translates to:
  /// **'The same time every day, whatever the Adhan.'**
  String get iqamaFixedNote;

  /// No description provided for @iqamaReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Jama’ah reminder'**
  String get iqamaReminderTitle;

  /// No description provided for @iqamaReminderHint.
  ///
  /// In en, this message translates to:
  /// **'A nudge before the congregation starts'**
  String get iqamaReminderHint;

  /// No description provided for @iqamaSaved.
  ///
  /// In en, this message translates to:
  /// **'{prayer} Iqama saved'**
  String iqamaSaved(String prayer);

  /// No description provided for @clearThisIqama.
  ///
  /// In en, this message translates to:
  /// **'Clear this Iqama'**
  String get clearThisIqama;

  /// No description provided for @iqamaFewerMinutes.
  ///
  /// In en, this message translates to:
  /// **'One minute less'**
  String get iqamaFewerMinutes;

  /// No description provided for @iqamaMoreMinutes.
  ///
  /// In en, this message translates to:
  /// **'One minute more'**
  String get iqamaMoreMinutes;

  /// No description provided for @iqamaEarlier.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute earlier} other{{minutes} minutes earlier}}'**
  String iqamaEarlier(int minutes);

  /// No description provided for @iqamaLater.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute later} other{{minutes} minutes later}}'**
  String iqamaLater(int minutes);

  /// No description provided for @settingsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get settingsBack;

  /// No description provided for @settingsGroupEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get settingsGroupEveryDay;

  /// No description provided for @settingsGroupPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsGroupPreferences;

  /// No description provided for @settingsGroupHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsGroupHelp;

  /// No description provided for @settingsLanguageLook.
  ///
  /// In en, this message translates to:
  /// **'Language and look'**
  String get settingsLanguageLook;

  /// No description provided for @settingsHelpAbout.
  ///
  /// In en, this message translates to:
  /// **'Help and about'**
  String get settingsHelpAbout;

  /// No description provided for @settingsHubFooter.
  ///
  /// In en, this message translates to:
  /// **'Iqama times live on each mosque, in the Mosques tab, not here.'**
  String get settingsHubFooter;

  /// No description provided for @settingsPrayerTimesSummary.
  ///
  /// In en, this message translates to:
  /// **'{method} · Asr {asr}'**
  String settingsPrayerTimesSummary(String method, String asr);

  /// No description provided for @settingsAlertsSummary.
  ///
  /// In en, this message translates to:
  /// **'{sound} · {on} of {total} on'**
  String settingsAlertsSummary(String sound, int on, int total);

  /// No description provided for @settingsSummaryPair.
  ///
  /// In en, this message translates to:
  /// **'{first} · {second}'**
  String settingsSummaryPair(String first, String second);

  /// No description provided for @settingsRemindersPausedShort.
  ///
  /// In en, this message translates to:
  /// **'All paused'**
  String get settingsRemindersPausedShort;

  /// No description provided for @settingsNoActiveMosque.
  ///
  /// In en, this message translates to:
  /// **'No active mosque'**
  String get settingsNoActiveMosque;

  /// No description provided for @travelSummaryOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get travelSummaryOff;

  /// No description provided for @travelSummaryOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get travelSummaryOn;

  /// No description provided for @travelSummaryFollowing.
  ///
  /// In en, this message translates to:
  /// **'On · following your location'**
  String get travelSummaryFollowing;

  /// No description provided for @settingsHelpSummary.
  ///
  /// In en, this message translates to:
  /// **'Introduction, late alerts, about'**
  String get settingsHelpSummary;

  /// No description provided for @settingsPrayerTimesLead.
  ///
  /// In en, this message translates to:
  /// **'How the times on Today are worked out.'**
  String get settingsPrayerTimesLead;

  /// No description provided for @settingsAlertsLead.
  ///
  /// In en, this message translates to:
  /// **'What you hear at each Adhan.'**
  String get settingsAlertsLead;

  /// No description provided for @settingsRemindersLead.
  ///
  /// In en, this message translates to:
  /// **'How the reminder before your mosque’s Iqama sounds.'**
  String get settingsRemindersLead;

  /// No description provided for @settingsTravelLead.
  ///
  /// In en, this message translates to:
  /// **'Times that follow you on a journey.'**
  String get settingsTravelLead;

  /// No description provided for @settingsLanguageLookLead.
  ///
  /// In en, this message translates to:
  /// **'The app’s language and theme.'**
  String get settingsLanguageLookLead;

  /// No description provided for @settingsHelpLead.
  ///
  /// In en, this message translates to:
  /// **'Getting started, late alerts, and this build.'**
  String get settingsHelpLead;

  /// No description provided for @extraOnTodaySection.
  ///
  /// In en, this message translates to:
  /// **'Extra times on Today'**
  String get extraOnTodaySection;

  /// No description provided for @extraAlertsAndTiming.
  ///
  /// In en, this message translates to:
  /// **'Alerts and timing'**
  String get extraAlertsAndTiming;

  /// No description provided for @extraNoAlerts.
  ///
  /// In en, this message translates to:
  /// **'No alerts'**
  String get extraNoAlerts;

  /// No description provided for @extraAlertsFor.
  ///
  /// In en, this message translates to:
  /// **'Alerts: {names}'**
  String extraAlertsFor(String names);

  /// No description provided for @settingsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsAdvanced;

  /// No description provided for @highLatitudeLead.
  ///
  /// In en, this message translates to:
  /// **'When the night is short, Fajr and Isha need a rule.'**
  String get highLatitudeLead;

  /// No description provided for @alertsEachPrayer.
  ///
  /// In en, this message translates to:
  /// **'Each prayer'**
  String get alertsEachPrayer;

  /// No description provided for @alertsAlsoFromToday.
  ///
  /// In en, this message translates to:
  /// **'Also from Today: tap the sound beside any prayer.'**
  String get alertsAlsoFromToday;

  /// No description provided for @alertsRecordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get alertsRecordings;

  /// No description provided for @alertsSilentSection.
  ///
  /// In en, this message translates to:
  /// **'On the lock screen and on silent'**
  String get alertsSilentSection;

  /// No description provided for @settingsRemindersOnMosque.
  ///
  /// In en, this message translates to:
  /// **'Iqama times and which prayers remind you are set on each mosque.'**
  String get settingsRemindersOnMosque;

  /// No description provided for @followNeedsTravel.
  ///
  /// In en, this message translates to:
  /// **'Available while travel mode is on.'**
  String get followNeedsTravel;

  /// No description provided for @travelInFlightValue.
  ///
  /// In en, this message translates to:
  /// **'Prayer times and the Qibla on a plane'**
  String get travelInFlightValue;

  /// No description provided for @themeSkyNote.
  ///
  /// In en, this message translates to:
  /// **'The sky always follows the time of day. Dark keeps it dimmer.'**
  String get themeSkyNote;

  /// No description provided for @helpLateAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts arriving late?'**
  String get helpLateAlerts;

  /// No description provided for @helpLateAlertsLead.
  ///
  /// In en, this message translates to:
  /// **'Most often the phone is saving battery.'**
  String get helpLateAlertsLead;

  /// No description provided for @helpBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery use'**
  String get helpBatteryTitle;

  /// No description provided for @helpCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check what is scheduled'**
  String get helpCheckTitle;

  /// No description provided for @helpCheckBody.
  ///
  /// In en, this message translates to:
  /// **'The list shows every alert and reminder waiting on this phone, and says if a permission is missing.'**
  String get helpCheckBody;

  /// No description provided for @helpAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get helpAbout;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsLead.
  ///
  /// In en, this message translates to:
  /// **'Help us understand notification problems on this phone.'**
  String get diagnosticsLead;

  /// No description provided for @diagnosticsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'A small event history stays on this phone. Reports include app build, Android version, notification permission status, and recent scheduling outcomes. They exclude your place, mosque, prayer times, notification text, and identity.'**
  String get diagnosticsPrivacy;

  /// No description provided for @diagnosticsSentry.
  ///
  /// In en, this message translates to:
  /// **'Send error reports to Sentry'**
  String get diagnosticsSentry;

  /// No description provided for @diagnosticsSentryHint.
  ///
  /// In en, this message translates to:
  /// **'When enabled, app errors are sent automatically so we can investigate crashes.'**
  String get diagnosticsSentryHint;

  /// No description provided for @diagnosticsSentryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Error reporting is not configured in this build.'**
  String get diagnosticsSentryUnavailable;

  /// No description provided for @diagnosticsHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent notification activity'**
  String get diagnosticsHistory;

  /// No description provided for @diagnosticsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No diagnostic events yet.'**
  String get diagnosticsEmpty;

  /// No description provided for @diagnosticsSend.
  ///
  /// In en, this message translates to:
  /// **'Prepare a diagnostic report'**
  String get diagnosticsSend;

  /// No description provided for @diagnosticsSending.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get diagnosticsSending;

  /// No description provided for @diagnosticsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Share diagnostic report?'**
  String get diagnosticsConfirmTitle;

  /// No description provided for @diagnosticsConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The report contains app and Android versions plus recent notification scheduling and permission events. It contains no place, mosque, prayer times, notification text, or account identity. Continue only if you are comfortable sharing this information.'**
  String get diagnosticsConfirmBody;

  /// No description provided for @diagnosticsUpload.
  ///
  /// In en, this message translates to:
  /// **'Send to Sentry'**
  String get diagnosticsUpload;

  /// No description provided for @diagnosticsShare.
  ///
  /// In en, this message translates to:
  /// **'Open share sheet'**
  String get diagnosticsShare;

  /// No description provided for @diagnosticsReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Jama’ah diagnostic report'**
  String get diagnosticsReportTitle;

  /// No description provided for @diagnosticsUploaded.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic report sent.'**
  String get diagnosticsUploaded;

  /// No description provided for @diagnosticsEventIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Sentry event ID (select to copy)'**
  String get diagnosticsEventIdLabel;

  /// No description provided for @diagnosticsShareOpened.
  ///
  /// In en, this message translates to:
  /// **'Choose an app to share the report.'**
  String get diagnosticsShareOpened;

  /// No description provided for @diagnosticsSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare or send the report.'**
  String get diagnosticsSendFailed;

  /// No description provided for @methodListLead.
  ///
  /// In en, this message translates to:
  /// **'Each method\'s angles, and where it is used.'**
  String get methodListLead;

  /// No description provided for @compassEast.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get compassEast;

  /// No description provided for @compassWest.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get compassWest;

  /// No description provided for @qiblaLead.
  ///
  /// In en, this message translates to:
  /// **'From {place} · {distance} km to the Kaaba'**
  String qiblaLead(String place, String distance);

  /// No description provided for @compassPointNorth.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get compassPointNorth;

  /// No description provided for @compassPointNorthEast.
  ///
  /// In en, this message translates to:
  /// **'North-east'**
  String get compassPointNorthEast;

  /// No description provided for @compassPointEast.
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get compassPointEast;

  /// No description provided for @compassPointSouthEast.
  ///
  /// In en, this message translates to:
  /// **'South-east'**
  String get compassPointSouthEast;

  /// No description provided for @compassPointSouth.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get compassPointSouth;

  /// No description provided for @compassPointSouthWest.
  ///
  /// In en, this message translates to:
  /// **'South-west'**
  String get compassPointSouthWest;

  /// No description provided for @compassPointWest.
  ///
  /// In en, this message translates to:
  /// **'West'**
  String get compassPointWest;

  /// No description provided for @compassPointNorthWest.
  ///
  /// In en, this message translates to:
  /// **'North-west'**
  String get compassPointNorthWest;

  /// No description provided for @compassLowerNorth.
  ///
  /// In en, this message translates to:
  /// **'north'**
  String get compassLowerNorth;

  /// No description provided for @compassLowerEast.
  ///
  /// In en, this message translates to:
  /// **'east'**
  String get compassLowerEast;

  /// No description provided for @compassLowerSouth.
  ///
  /// In en, this message translates to:
  /// **'south'**
  String get compassLowerSouth;

  /// No description provided for @compassLowerWest.
  ///
  /// In en, this message translates to:
  /// **'west'**
  String get compassLowerWest;

  /// No description provided for @compassLeanToward.
  ///
  /// In en, this message translates to:
  /// **'{point}, a little towards the {toward}'**
  String compassLeanToward(String point, String toward);

  /// No description provided for @compassLeanMore.
  ///
  /// In en, this message translates to:
  /// **'{point}, a little more {more} than {less}'**
  String compassLeanMore(String point, String more, String less);

  /// No description provided for @qiblaNoCompassHint.
  ///
  /// In en, this message translates to:
  /// **'This phone has no compass, so the arrow can’t follow you. Line it up with a direction you know, such as where the sun sets.'**
  String get qiblaNoCompassHint;

  /// No description provided for @qiblaNeedsMoment.
  ///
  /// In en, this message translates to:
  /// **'The compass needs a moment'**
  String get qiblaNeedsMoment;

  /// No description provided for @qiblaSteadyNow.
  ///
  /// In en, this message translates to:
  /// **'It’s steady now'**
  String get qiblaSteadyNow;

  /// No description provided for @onbLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language · اللغة'**
  String get onbLanguageLabel;

  /// No description provided for @onbLanguageLater.
  ///
  /// In en, this message translates to:
  /// **'You can change it later in Settings.'**
  String get onbLanguageLater;

  /// No description provided for @onbPlaceBody.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are worked out on your phone from your place. An approximate location is enough, and it never leaves your phone.'**
  String get onbPlaceBody;

  /// No description provided for @onbPlaceDetails.
  ///
  /// In en, this message translates to:
  /// **'Method: {method} · next Adhan {prayer} {time}'**
  String onbPlaceDetails(String method, String prayer, String time);

  /// No description provided for @onbPlaceNotRight.
  ///
  /// In en, this message translates to:
  /// **'Not right? Choose a city'**
  String get onbPlaceNotRight;

  /// No description provided for @onbMosqueRowOpen.
  ///
  /// In en, this message translates to:
  /// **'A row of worshippers, with one place open for you'**
  String get onbMosqueRowOpen;

  /// No description provided for @onbMosqueRowFull.
  ///
  /// In en, this message translates to:
  /// **'A full row, with you in it'**
  String get onbMosqueRowFull;

  /// No description provided for @onbMosqueAdded.
  ///
  /// In en, this message translates to:
  /// **'{mosque} added'**
  String onbMosqueAdded(String mosque);

  /// No description provided for @onbMosqueAddedBody.
  ///
  /// In en, this message translates to:
  /// **'Its Iqama times are not configured yet. Set them from the Mosques tab whenever you are ready.'**
  String get onbMosqueAddedBody;

  /// No description provided for @onbAlertsFiveHint.
  ///
  /// In en, this message translates to:
  /// **'Fajr, Dhuhr, Asr, Maghrib and Isha'**
  String get onbAlertsFiveHint;

  /// No description provided for @onbAllowNote.
  ///
  /// In en, this message translates to:
  /// **'Android will ask if Jama’ah may send notifications. Without it, alerts can’t appear.'**
  String get onbAllowNote;

  /// No description provided for @onbNotificationsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications allowed'**
  String get onbNotificationsAllowed;

  /// No description provided for @onbBatterySettings.
  ///
  /// In en, this message translates to:
  /// **'Battery settings'**
  String get onbBatterySettings;

  /// No description provided for @onbTravelOnSub.
  ///
  /// In en, this message translates to:
  /// **'On: times follow you'**
  String get onbTravelOnSub;

  /// No description provided for @onbTravelOffSub.
  ///
  /// In en, this message translates to:
  /// **'Off: times stay where you set them'**
  String get onbTravelOffSub;

  /// No description provided for @onbTravelSame.
  ///
  /// In en, this message translates to:
  /// **'The same switch sits at the top of Today.'**
  String get onbTravelSame;

  /// No description provided for @inFlightStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer times at 11,000 metres'**
  String get inFlightStartTitle;

  /// No description provided for @inFlightStartLead.
  ///
  /// In en, this message translates to:
  /// **'Worked out from your phone’s GPS. It works in airplane mode, with no network.'**
  String get inFlightStartLead;

  /// No description provided for @inFlightWindowNote.
  ///
  /// In en, this message translates to:
  /// **'Sit by a window if you can. The first fix can take a few minutes.'**
  String get inFlightWindowNote;

  /// No description provided for @inFlightLookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Looking for satellites'**
  String get inFlightLookingTitle;

  /// No description provided for @inFlightKeepLooking.
  ///
  /// In en, this message translates to:
  /// **'Keep the phone near a window, screen up.'**
  String get inFlightKeepLooking;

  /// No description provided for @inFlightAircraftTime.
  ///
  /// In en, this message translates to:
  /// **'Aircraft time {time} ({offset}), from your position'**
  String inFlightAircraftTime(String time, String offset);

  /// No description provided for @inFlightPosition.
  ///
  /// In en, this message translates to:
  /// **'{lat} · {lon}'**
  String inFlightPosition(String lat, String lon);

  /// No description provided for @inFlightLatNorth.
  ///
  /// In en, this message translates to:
  /// **'{degrees}° N'**
  String inFlightLatNorth(String degrees);

  /// No description provided for @inFlightLatSouth.
  ///
  /// In en, this message translates to:
  /// **'{degrees}° S'**
  String inFlightLatSouth(String degrees);

  /// No description provided for @inFlightLonEast.
  ///
  /// In en, this message translates to:
  /// **'{degrees}° E'**
  String inFlightLonEast(String degrees);

  /// No description provided for @inFlightLonWest.
  ///
  /// In en, this message translates to:
  /// **'{degrees}° W'**
  String inFlightLonWest(String degrees);

  /// No description provided for @inFlightAlongTitle.
  ///
  /// In en, this message translates to:
  /// **'Along the route'**
  String get inFlightAlongTitle;

  /// No description provided for @inFlightEstimates.
  ///
  /// In en, this message translates to:
  /// **'Estimates'**
  String get inFlightEstimates;

  /// No description provided for @inFlightHeadingHint.
  ///
  /// In en, this message translates to:
  /// **'Aircraft heading: from the seat-back map, or ask the crew.'**
  String get inFlightHeadingHint;

  /// No description provided for @inFlightQiblaWords.
  ///
  /// In en, this message translates to:
  /// **'{words} · {degrees}°'**
  String inFlightQiblaWords(String words, String degrees);

  /// No description provided for @qiblaDirStraightAhead.
  ///
  /// In en, this message translates to:
  /// **'Straight ahead'**
  String get qiblaDirStraightAhead;

  /// No description provided for @qiblaDirAheadRight.
  ///
  /// In en, this message translates to:
  /// **'Ahead, to your right'**
  String get qiblaDirAheadRight;

  /// No description provided for @qiblaDirRight.
  ///
  /// In en, this message translates to:
  /// **'To your right'**
  String get qiblaDirRight;

  /// No description provided for @qiblaDirBehindRight.
  ///
  /// In en, this message translates to:
  /// **'Behind you, to the right'**
  String get qiblaDirBehindRight;

  /// No description provided for @qiblaDirBehind.
  ///
  /// In en, this message translates to:
  /// **'Behind you'**
  String get qiblaDirBehind;

  /// No description provided for @qiblaDirBehindLeft.
  ///
  /// In en, this message translates to:
  /// **'Behind you, to the left'**
  String get qiblaDirBehindLeft;

  /// No description provided for @qiblaDirLeft.
  ///
  /// In en, this message translates to:
  /// **'To your left'**
  String get qiblaDirLeft;

  /// No description provided for @qiblaDirAheadLeft.
  ///
  /// In en, this message translates to:
  /// **'Ahead, to your left'**
  String get qiblaDirAheadLeft;

  /// No description provided for @adhanScreenKicker.
  ///
  /// In en, this message translates to:
  /// **'It’s time for'**
  String get adhanScreenKicker;

  /// No description provided for @adhanScreenAdhanAt.
  ///
  /// In en, this message translates to:
  /// **'Adhan · {time}'**
  String adhanScreenAdhanAt(String time);

  /// No description provided for @adhanScreenIqamaIn.
  ///
  /// In en, this message translates to:
  /// **'Iqama at {mosque} · {time}, {countdown}'**
  String adhanScreenIqamaIn(String mosque, String time, String countdown);

  /// No description provided for @adhanScreenIqamaAt.
  ///
  /// In en, this message translates to:
  /// **'Iqama at {mosque} · {time}'**
  String adhanScreenIqamaAt(String mosque, String time);

  /// No description provided for @adhanScreenNoIqama.
  ///
  /// In en, this message translates to:
  /// **'No Iqama set at {mosque}'**
  String adhanScreenNoIqama(String mosque);

  /// No description provided for @adhanScreenHint.
  ///
  /// In en, this message translates to:
  /// **'Volume keys or turning the phone face down also stop it.'**
  String get adhanScreenHint;

  /// No description provided for @adhanScreenStopped.
  ///
  /// In en, this message translates to:
  /// **'Adhan stopped'**
  String get adhanScreenStopped;

  /// No description provided for @adhanScreenDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get adhanScreenDismiss;

  /// No description provided for @adhanScreenStopLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop the {prayer} Adhan'**
  String adhanScreenStopLabel(String prayer);

  /// No description provided for @onbExactNote.
  ///
  /// In en, this message translates to:
  /// **'For alerts at the very minute, Android also asks you to let Jama’ah set alarms. Without it, an alert can come a few minutes late.'**
  String get onbExactNote;

  /// No description provided for @onbExactAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow on-time alerts'**
  String get onbExactAllow;

  /// No description provided for @onbExactHow.
  ///
  /// In en, this message translates to:
  /// **'Turn on the switch on the next screen, then come back.'**
  String get onbExactHow;

  /// No description provided for @onbExactAllowed.
  ///
  /// In en, this message translates to:
  /// **'On-time alerts allowed'**
  String get onbExactAllowed;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
