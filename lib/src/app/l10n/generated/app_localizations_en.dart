// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Awqaity';

  @override
  String get tabToday => 'Today';

  @override
  String get tabMosques => 'Mosques';

  @override
  String get tabQibla => 'Qibla';

  @override
  String get settings => 'Settings';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get notConfigured => 'Not configured';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get todayLoading => 'Loading your day…';

  @override
  String get todayNeedsPlaceTitle => 'Set your location';

  @override
  String get todayNeedsPlaceBody =>
      'Prayer times are worked out for the place you are in, on this device. Choose where you are to begin.';

  @override
  String get todayChoosePlace => 'Choose where you are';

  @override
  String get todayErrorTitle => 'Your saved setup could not be read';

  @override
  String get todayErrorBody =>
      'Awqaity could not open its own data on this device. Nothing has been lost — try again, or choose your location.';

  @override
  String get todaySectionTimes => 'Prayer times (Adhan)';

  @override
  String get nextPrayerAdhan => 'Next prayer · Adhan';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get tagNext => 'Next';

  @override
  String prayerAtTime(String prayer, String time) {
    return '$prayer $time';
  }

  @override
  String countdownHours(int hours, int minutes) {
    return 'in ${hours}h ${minutes}m';
  }

  @override
  String countdownMinutes(int minutes) {
    return 'in $minutes min';
  }

  @override
  String nextIqamaLabel(String mosque) {
    return 'Next Iqama · $mosque';
  }

  @override
  String rowIqama(String time) {
    return 'Iqama $time';
  }

  @override
  String reminderBeforeIqama(int minutes) {
    return 'Reminder $minutes min before';
  }

  @override
  String get reminderOffForPrayer => 'No reminder for this prayer';

  @override
  String get remindersAreSettingsNote =>
      'Reminders are stored as settings. Notifications arrive in a later step.';

  @override
  String highLatitudeNote(String prayers, String rule) {
    return 'At this latitude, $prayers follow the $rule rule.';
  }

  @override
  String twoNames(String first, String second) {
    return '$first and $second';
  }

  @override
  String get ruleMiddleOfTheNight => 'middle of the night';

  @override
  String get ruleSeventhOfTheNight => 'one seventh of the night';

  @override
  String get ruleTwilightAngle => 'twilight angle';

  @override
  String estimatedFromLatitudeNote(String latitude) {
    return 'The sun neither rises nor sets here today, so these times are estimated from $latitude, nearer the equator.';
  }

  @override
  String get noTimeToday => 'no time today';

  @override
  String get timesUnavailableTitle => 'No times to show for this day';

  @override
  String get timesUnavailableBody =>
      'Here the sun does not cross the horizon today, so there is no honest prayer time to work out. Choose a nearby city, or a day with a normal sunrise.';

  @override
  String get addMosqueTitle => 'Add your mosque';

  @override
  String get addMosqueBody =>
      'Pick a mosque and enter its Iqama times to see them here. We never guess them.';

  @override
  String mosqueHasNoIqama(String mosque) {
    return '$mosque has no Iqama times yet. Tap to set them.';
  }

  @override
  String get reminderOnSemantics => 'Iqama reminder on';

  @override
  String get aboutBody =>
      'Early build. Prayer times are calculated on this device. Iqama times are entered by you, per mosque.';

  @override
  String get mosquesComingTitle => 'Mosques come next';

  @override
  String get mosquesComingBody =>
      'Adding a mosque and entering its Iqama times is the step after this one. Today already works without a mosque, and no time here is ever guessed.';

  @override
  String get qiblaComingTitle => 'Qibla comes later';

  @override
  String get qiblaComingBody =>
      'The direction of prayer is worked out on this device and gets its own screen after the mosque and reminder steps. No bearing is shown until it has been measured.';

  @override
  String get settingsComingTitle => 'Settings come later';

  @override
  String get settingsComingBody =>
      'Calculation method, Asr opinion, sounds and reminders will live here. None of them are built yet, so there is nothing honest to change.';

  @override
  String get locationSheetTitle => 'Where are you?';

  @override
  String get locationSheetBody =>
      'Awqaity works out prayer times for the place you are in, on this device. There is no account and nothing is uploaded.';

  @override
  String get locationSheetCoarse =>
      'We ask for approximate location — city level, never your exact position. Times across one city differ by only a few minutes.';

  @override
  String get locationUseDevice => 'Use my location';

  @override
  String get locationChooseCity => 'Choose a city';

  @override
  String get locationRequesting => 'Finding your location…';

  @override
  String get locationCurrentPlace => 'Current location';

  @override
  String get placeRenameAction => 'Name this place';

  @override
  String get placeRenameTitle => 'Give this place a name';

  @override
  String get placeRenameHint => 'For example, Home';

  @override
  String get locationDenied =>
      'You declined the location permission. That is completely fine — choose your city and the times will be right.';

  @override
  String get locationPermanentlyDenied =>
      'Location is switched off for Awqaity in your device settings. You can change that there, or choose your city now.';

  @override
  String get locationServiceDisabled =>
      'Location services are turned off on this device. Choose your city, or switch location on and try again.';

  @override
  String get locationTimeout =>
      'Your device did not answer in time. You can try again, or choose your city.';

  @override
  String get locationUnavailable =>
      'Your location could not be read right now. Choose your city instead.';

  @override
  String get locationOpenSettings => 'Open app settings';

  @override
  String get locationTryAgain => 'Try again';

  @override
  String get cityListTitle => 'Choose a city';

  @override
  String get cityListPlaceholderNote =>
      'This list ships with the app, so it works with no network. It is a placeholder — a starting point, not a directory. Pick the city nearest to you.';

  @override
  String get cityListSearchHint => 'Search';

  @override
  String get cityListNoMatches =>
      'No city matches that. Choose the nearest one — prayer times differ by only a few minutes.';

  @override
  String currentPlaceLabel(String place) {
    return 'Prayer times for $place';
  }
}
