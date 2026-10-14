// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Jama’ah';

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
      'Jama’ah could not open its own data on this device. Nothing has been lost — try again, or choose your location.';

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
  String get noIqamaLeftToday => 'No more Iqama times today.';

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
  String get reminderOnSemantics => 'Jama’ah reminder on';

  @override
  String get aboutBody =>
      'Early build. Prayer times are calculated on this device. Iqama times are entered by you, per mosque.';

  @override
  String qiblaFrom(String place) {
    return 'From $place';
  }

  @override
  String qiblaDegrees(String degrees) {
    return '$degrees°';
  }

  @override
  String qiblaFromNorth(String degrees) {
    return '$degrees° from true north';
  }

  @override
  String qiblaTurnRight(String degrees) {
    return 'Turn $degrees° right';
  }

  @override
  String qiblaTurnLeft(String degrees) {
    return 'Turn $degrees° left';
  }

  @override
  String get qiblaAligned => 'Facing the Qibla';

  @override
  String qiblaDistance(String distance) {
    return '$distance km to the Kaaba';
  }

  @override
  String get qiblaHoldFlat =>
      'Hold your phone flat, away from metal and magnets.';

  @override
  String qiblaDeclinationNote(String degrees) {
    return 'Measured from true north. The compass reads magnetic north, so $degrees° is corrected for here.';
  }

  @override
  String get qiblaMagneticNote =>
      'Measured from magnetic north, which can differ from true north by a few degrees.';

  @override
  String get qiblaNeedsCalibration => 'The compass isn’t accurate right now.';

  @override
  String get qiblaCalibrate => 'How to calibrate';

  @override
  String get qiblaCalibrateTitle => 'Calibrate the compass';

  @override
  String get qiblaCalibrateBody =>
      'Move your phone in a slow figure-8 a few times, away from metal objects and magnets. The direction settles once the compass is accurate.';

  @override
  String get qiblaCalibrateDone => 'Done';

  @override
  String get qiblaNoCompassTitle => 'Compass unavailable';

  @override
  String qiblaNoCompassBody(String degrees, String place) {
    return 'The Qibla is $degrees° clockwise from true north for $place. Use any compass or map app and face that bearing.';
  }

  @override
  String get qiblaNeedsPlaceTitle => 'Set your location';

  @override
  String get qiblaNeedsPlaceBody =>
      'The direction of the Qibla is worked out on this device from where you are. Choose where you are to begin.';

  @override
  String qiblaDialLabel(String degrees) {
    return 'Compass. The Qibla is $degrees° from true north.';
  }

  @override
  String get locationSheetTitle => 'Where are you?';

  @override
  String get locationSheetBody =>
      'Jama’ah works out prayer times for the place you are in, on this device. There is no account and nothing is uploaded.';

  @override
  String get locationSheetCoarse =>
      'Prayer times need only approximate location — city level. Times across one city differ by only a few minutes. Finding mosques near you asks separately for precise location.';

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
      'Location is switched off for Jama’ah in your device settings. You can change that there, or choose your city now.';

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

  @override
  String get mosquesTitle => 'Mosques';

  @override
  String get mosquesSubtitle => 'Iqama times belong to each mosque.';

  @override
  String get findNearbyMosques => 'Find nearby mosques';

  @override
  String get addMosqueManually => 'Add a mosque manually';

  @override
  String get savedMosquesHeader => 'Saved';

  @override
  String get noSavedMosques =>
      'No saved mosques yet. Add your mosque, then enter its Iqama times.';

  @override
  String get tagActive => 'Active';

  @override
  String get iqamaStatusAll => 'Iqama set';

  @override
  String iqamaStatusPartial(int count, int total) {
    return '$count of $total Iqama set';
  }

  @override
  String get iqamaStatusNone => 'Iqama not configured';

  @override
  String get mosqueSourceManual => 'Added by you';

  @override
  String get mosqueSourceGoogle => 'From Google Maps';

  @override
  String get mosqueSourceOsm => 'From OpenStreetMap';

  @override
  String get addMosqueSheetTitle => 'Add a mosque';

  @override
  String get addMosqueSheetBody =>
      'Its Iqama schedule starts as “Not configured”. You enter the times.';

  @override
  String get mosqueNameLabel => 'Mosque name';

  @override
  String get mosqueAddressLabel => 'Address or area (optional)';

  @override
  String get add => 'Add';

  @override
  String get setAsActive => 'Set as active';

  @override
  String get activeMosqueNote => 'Today and Jama’ah reminders use this mosque.';

  @override
  String get editDetails => 'Edit details';

  @override
  String get editMosqueTitle => 'Edit mosque';

  @override
  String iqamaScheduleHeader(String mosque) {
    return 'Iqama schedule · $mosque';
  }

  @override
  String rowAdhanTime(String time) {
    return 'Adhan $time';
  }

  @override
  String rowReminderAt(String time) {
    return 'Reminder at $time';
  }

  @override
  String rowReminderBeforeMidnight(String time) {
    return 'Reminder at $time, before midnight';
  }

  @override
  String get rowReminderOff => 'Reminder off';

  @override
  String get rowReminderNeedsIqama => 'Set an Iqama time to add a reminder';

  @override
  String reminderSwitchLabel(String prayer) {
    return '$prayer Jama’ah reminder';
  }

  @override
  String scheduleSetByYou(String date) {
    return 'Set by you · last updated $date';
  }

  @override
  String get scheduleNothingEntered =>
      'No Iqama times entered yet. Tap a prayer to set one.';

  @override
  String get iqamaScheduleNote =>
      'Tap a prayer to edit. Iqama times are entered by you for this mosque and never taken from Adhan times. Sunrise has no Iqama.';

  @override
  String get removeMosque => 'Remove mosque';

  @override
  String removeMosqueTitle(String mosque) {
    return 'Remove $mosque?';
  }

  @override
  String get removeMosqueBody =>
      'Its Iqama times will be deleted from this device.';

  @override
  String get removeMosqueBodyActive =>
      'Its Iqama times will be deleted from this device. It is your active mosque, so Today will show no mosque until you choose another.';

  @override
  String iqamaEditorTitle(String prayer) {
    return '$prayer Iqama';
  }

  @override
  String iqamaEditorEditing(String mosque) {
    return 'Editing $mosque';
  }

  @override
  String get iqamaChooseTime => 'Choose a time';

  @override
  String iqamaStartsAtAdhan(String time) {
    return 'Adhan $time · tap to set';
  }

  @override
  String get iqamaTimeLabel => 'Iqama time';

  @override
  String get remindMeBefore => 'Remind me before Iqama';

  @override
  String get reminderNeedsTime => 'Choose an Iqama time first.';

  @override
  String reminderMinutesChip(int minutes) {
    return '$minutes min';
  }

  @override
  String get reminderCustom => 'Custom';

  @override
  String get reminderCustomLabel => 'Minutes before (1–120)';

  @override
  String get reminderCustomEmpty => 'Enter how many minutes before Iqama.';

  @override
  String get reminderCustomNotWhole => 'Use whole minutes, like 20.';

  @override
  String get reminderCustomOutOfRange => 'Choose between 1 and 120 minutes.';

  @override
  String get summaryNoTime =>
      'Choose an Iqama time to see the reminder summary.';

  @override
  String summaryReminderOff(String prayer, String time) {
    return '$prayer · $time Iqama · Reminder off';
  }

  @override
  String summaryReminderAt(String prayer, String time, String reminder) {
    return '$prayer · $time Iqama · Reminder at $reminder';
  }

  @override
  String summaryReminderBeforeMidnight(
    String prayer,
    String time,
    String reminder,
  ) {
    return '$prayer · $time Iqama · Reminder at $reminder, before midnight';
  }

  @override
  String get clearIqamaTime => 'Clear Iqama time';

  @override
  String get nearbyTitle => 'Nearby mosques';

  @override
  String get nearbyExplainTitle => 'Find mosques near you';

  @override
  String get nearbyExplainBody =>
      'We use your precise location once, to list the mosques around you. If you keep location approximate, the search still works, just less exactly.';

  @override
  String nearbyExplainSent(String provider) {
    return 'Your position is sent to $provider for this search only. Jama’ah does not store it.';
  }

  @override
  String get providerGoogle => 'Google Maps';

  @override
  String get providerOsm => 'OpenStreetMap';

  @override
  String get nearbyUseLocation => 'Use my location';

  @override
  String get nearbySearchCity => 'Search around a city';

  @override
  String get nearbyLocating => 'Finding where you are…';

  @override
  String get nearbySearching => 'Looking for mosques…';

  @override
  String nearbyHeaderHere(int km) {
    return 'Within $km km of you';
  }

  @override
  String nearbyHeaderCity(int km, String place) {
    return 'Within $km km of $place';
  }

  @override
  String get nearbyApproximateNote =>
      'Your phone shared approximate location, so this list may be a few kilometres off. You can allow precise location in settings.';

  @override
  String get nearbyFilterHint => 'Filter by name';

  @override
  String get nearbyUnnamed => 'Unnamed mosque';

  @override
  String get nearbyNoAddress => 'No address listed';

  @override
  String get distanceUnder50 => 'Under 50 m';

  @override
  String distanceMetres(int metres) {
    return '$metres m';
  }

  @override
  String distanceKilometres(String km) {
    return '$km km';
  }

  @override
  String get nearbyAttributionGoogle =>
      'Results from Google Maps. Not verified — check the name before saving.';

  @override
  String get nearbyAttributionOsm =>
      'Results © OpenStreetMap contributors. Not verified — check the name before saving.';

  @override
  String nearbyEmpty(int km) {
    return 'No mosques found within $km km. Try a city, or add your mosque by hand.';
  }

  @override
  String get nearbyNoMatches => 'No mosque in this list matches that name.';

  @override
  String get nearbyAddManually => 'Not listed? Add it by hand';

  @override
  String get nearbyTryOsm => 'Search OpenStreetMap instead';

  @override
  String get nearbyFailNoKey =>
      'Google Maps search isn\'t set up in this build. You can search OpenStreetMap, or add your mosque by hand.';

  @override
  String get nearbyFailKeyRejected =>
      'Google Maps refused the search. That\'s a setup problem with the app, not your phone. You can search OpenStreetMap instead.';

  @override
  String get nearbyFailNetwork =>
      'No connection right now. Your saved mosques and prayer times still work offline.';

  @override
  String nearbyFailRateLimited(String provider) {
    return '$provider is busy. Try again in a minute, or add your mosque by hand.';
  }

  @override
  String nearbyFailServer(String provider) {
    return '$provider didn\'t answer properly. Try again, or add your mosque by hand.';
  }

  @override
  String get nearbyFailLimit =>
      'That\'s all the searching for this session, to keep the app free to run. It resets when you reopen the app. You can still add a mosque by hand.';

  @override
  String get nearbyLocDenied =>
      'Location wasn\'t allowed. You can search around a city instead.';

  @override
  String get nearbyLocPermanent =>
      'Location is turned off for Jama’ah in your settings. Allow it there, or search around a city.';

  @override
  String get nearbyLocService =>
      'Location services are off on this phone. Turn them on, or search around a city.';

  @override
  String get nearbyLocTimeout =>
      'Your phone didn\'t find its position in time. Try again, or search around a city.';

  @override
  String get nearbyLocUnavailable =>
      'Your position couldn\'t be read right now. Search around a city instead.';

  @override
  String get tagSaved => 'Saved';

  @override
  String get saveMosqueTitle => 'Save this mosque';

  @override
  String saveMosqueBody(String provider) {
    return 'Check the name and address — they come from $provider, not from the mosque. Its Iqama times start as “Not configured”.';
  }

  @override
  String get soundModeFull => 'Full Adhan';

  @override
  String get soundModeShort => 'Short Adhan';

  @override
  String get soundModeStandard => 'Standard sound';

  @override
  String get soundModeSilent => 'Silent';

  @override
  String channelAdhan(String sound) {
    return 'Adhan · $sound';
  }

  @override
  String channelNoVibration(String name) {
    return '$name · no vibration';
  }

  @override
  String channelAlarmVolume(String name) {
    return '$name · alarm volume';
  }

  @override
  String get channelPreAdhan => 'Reminders before the Adhan';

  @override
  String channelIqama(String sound) {
    return 'Jama’ah reminders · $sound';
  }

  @override
  String notifAdhanTitle(String prayer) {
    return '$prayer';
  }

  @override
  String notifAdhanBody(String prayer) {
    return 'It\'s time for $prayer.';
  }

  @override
  String get notifSunriseBody =>
      'The sun is rising. The time for Fajr has ended.';

  @override
  String notifPreAdhanTitle(String prayer, int minutes) {
    return '$prayer in $minutes min';
  }

  @override
  String get notifPreAdhanBody => 'A reminder before the Adhan.';

  @override
  String get notifPreSunriseBody => 'The time for Fajr ends at sunrise.';

  @override
  String get notifIqamaCall => 'حيّ على الصلاة';

  @override
  String notifIqamaBody(String prayer, int minutes, String mosque) {
    return '$prayer Iqama in $minutes min, at $mosque.';
  }

  @override
  String notifIqamaBodyNoMosque(String prayer, int minutes) {
    return '$prayer Iqama in $minutes min.';
  }

  @override
  String get scheduledTitle => 'Scheduled notifications';

  @override
  String scheduledCount(int count) {
    return '$count scheduled for the next 14 days';
  }

  @override
  String get scheduledNothing =>
      'Nothing is scheduled. Turn on an Adhan alert, or a Jama’ah reminder on your mosque.';

  @override
  String get scheduledNotificationsOff =>
      'Notifications are turned off for Jama’ah, so nothing will show. You can allow them now.';

  @override
  String get scheduledExactOff =>
      'Exact alarms aren\'t allowed, so notifications may arrive a few minutes late. You can allow them in settings.';

  @override
  String get scheduledAllowNotifications => 'Allow notifications';

  @override
  String get scheduledAllowExact => 'Allow exact alarms';

  @override
  String get scheduledRescheduleNow => 'Reschedule now';

  @override
  String get scheduledBatteryHint =>
      'Some phones stop reminders to save battery. If one doesn\'t arrive, set Jama’ah\'s battery use to Unrestricted in the phone\'s app settings.';

  @override
  String get scheduledOpenAppSettings => 'Open app settings';

  @override
  String get kindAdhan => 'Adhan';

  @override
  String get kindPreAdhan => 'Reminder before Adhan';

  @override
  String get kindIqama => 'Jama’ah reminder';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAdhanSection => 'Adhan alerts';

  @override
  String get settingsDefaultSound => 'Default sound';

  @override
  String get settingsDefaultSoundHint =>
      'Used by every prayer that doesn\'t choose its own.';

  @override
  String get settingsAlertOff => 'Off';

  @override
  String settingsAlertOn(String sound) {
    return 'On · $sound';
  }

  @override
  String settingsAlertReminderOnly(int minutes) {
    return 'Reminder only · $minutes min before';
  }

  @override
  String settingsAlertOnWithReminder(String sound, int minutes) {
    return 'On · $sound · reminder $minutes min before';
  }

  @override
  String get settingsIqamaSection => 'Jama’ah reminders';

  @override
  String get settingsIqamaBody =>
      'A Jama’ah reminder comes before your mosque’s Iqama time. Iqama times and their reminders belong to each mosque, so you set them on the mosque.';

  @override
  String settingsIqamaOpenActive(String mosque) {
    return 'Open $mosque';
  }

  @override
  String get settingsIqamaNoMosque => 'Add a mosque to set Jama’ah reminders.';

  @override
  String get settingsTravelSection => 'Travel';

  @override
  String get settingsNotificationsSection => 'Notifications';

  @override
  String alertPageTitle(String prayer) {
    return '$prayer';
  }

  @override
  String get alertAdhanSwitch => 'Adhan alert';

  @override
  String get alertAdhanSwitchHint => 'A notification at the Adhan time.';

  @override
  String get alertSunriseHint =>
      'Sunrise is not a prayer. An alert marks the end of the time for Fajr.';

  @override
  String get alertSoundHeader => 'Sound';

  @override
  String alertUseDefault(String sound) {
    return 'Default ($sound)';
  }

  @override
  String get alertSilentHint =>
      'Shown in your notifications without any sound. Turning the alert off is different: then nothing shows.';

  @override
  String get alertFullHint =>
      'Plays the whole Adhan, in the recording chosen in Settings.';

  @override
  String get alertShortHint =>
      'Plays a short part of the Adhan, chosen in Settings.';

  @override
  String get alertStandardHint => 'Your phone\'s usual notification sound.';

  @override
  String get alertPreview => 'Preview';

  @override
  String get alertStopPreview => 'Stop';

  @override
  String get alertVibrate => 'Vibrate';

  @override
  String get alertRingInSilent => 'Ring when the phone is on silent';

  @override
  String get alertRingInSilentHint =>
      'Plays through the alarm volume, so you hear it on silent or vibrate. If Do Not Disturb blocks alarms, it stays quiet.';

  @override
  String get alertRingInSilentNeedsSound => 'Silent has no sound to ring.';

  @override
  String get alertReminderHeader => 'Reminder before the Adhan';

  @override
  String get alertReminderHint =>
      'A separate heads-up, even if the Adhan alert itself is off.';

  @override
  String get alertReminderNone => 'None';

  @override
  String get alertTryIt => 'Send a test notification';

  @override
  String get alertTrySent => 'Sent. Check your notifications.';

  @override
  String notifTestTitle(String prayer) {
    return '$prayer · test';
  }

  @override
  String get notifTestBody => 'This is how this alert will sound.';

  @override
  String get adhanStop => 'Stop';

  @override
  String get settingsFullScreen => 'Full-screen Adhan';

  @override
  String get settingsFullScreenHint =>
      'When the phone is idle, the Adhan fills the screen with a large Stop. The volume keys, or turning the phone face down, stop it too.';

  @override
  String get settingsFullScreenDenied =>
      'Your phone doesn\'t allow full-screen alerts for Jama’ah, so the Adhan shows as a regular notification.';

  @override
  String get settingsFullScreenAllow => 'Allow full-screen alerts';

  @override
  String get alertStopHint =>
      'Stop it with either volume key, from the notification, or by turning the phone face down.';

  @override
  String get settingsFollowLocation => 'Follow my location';

  @override
  String get settingsFollowLocationHint =>
      'While travel mode is on, your place updates to where you are when you open the app, so times follow you between cities and time zones.';

  @override
  String get settingsTravelMode => 'Travel mode';

  @override
  String get settingsTravelModeHint =>
      'Turns on the travel options below. The airplane at the top of the app switches it too.';

  @override
  String get travelModeTurnOn => 'Turn on travel mode';

  @override
  String get travelModeTurnOff => 'Turn off travel mode';

  @override
  String get travelModeOnSnack => 'Travel mode on';

  @override
  String get travelModeOffSnack => 'Travel mode off';

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsFullRecording => 'Full Adhan recording';

  @override
  String get recordingsTitle => 'Full Adhan recording';

  @override
  String get recordingsBody =>
      'Plays for every alert set to Full Adhan. Short Adhan is chosen separately in Settings.';

  @override
  String get recordingPlay => 'Play';

  @override
  String get recordingStop => 'Stop';

  @override
  String recordingPlayLabel(String name) {
    return 'Play $name';
  }

  @override
  String recordingStopLabel(String name) {
    return 'Stop $name';
  }

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String latitudeNorth(String degrees) {
    return '$degrees°N';
  }

  @override
  String latitudeSouth(String degrees) {
    return '$degrees°S';
  }

  @override
  String get compassNorth => 'N';

  @override
  String get compassSouth => 'S';

  @override
  String recordingLength(String minutes, String seconds) {
    return '$minutes:$seconds';
  }

  @override
  String get themeSystem => 'Same as the phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get followDenied =>
      'Location wasn\'t allowed, so the app can\'t follow you. You can still choose a city.';

  @override
  String get followUnavailable =>
      'Your location couldn\'t be read right now, so following stays off. Try again in a moment.';

  @override
  String followingUpdated(String ago) {
    return 'Following your location · updated $ago';
  }

  @override
  String followingStale(String ago) {
    return 'Couldn\'t update your location. Using the last one, from $ago.';
  }

  @override
  String get agoJustNow => 'just now';

  @override
  String agoMinutes(int count) {
    return '$count min ago';
  }

  @override
  String agoHours(int count) {
    return '$count h ago';
  }

  @override
  String agoDays(int count) {
    return '$count d ago';
  }

  @override
  String get previewCity => 'Preview another city';

  @override
  String previewTitle(String place) {
    return '$place';
  }

  @override
  String previewNote(String place, String current) {
    return 'Prayer times for $place. Your own place stays $current.';
  }

  @override
  String get methodAuto => 'Auto detect';

  @override
  String get methodCustom => 'Custom angles';

  @override
  String get methodEgyptian => 'Egyptian General Authority of Survey (EGAS)';

  @override
  String get methodRegionEgyptian => 'Africa, Syria, Lebanon';

  @override
  String get methodIsna => 'Islamic Society of North America (ISNA)';

  @override
  String get methodRegionIsna => 'North America (US and Canada)';

  @override
  String get methodMoonsightingCommittee =>
      'Moonsighting Committee Worldwide (MCW)';

  @override
  String get methodRegionMoonsightingCommittee =>
      'Parts of the US, parts of the UK';

  @override
  String get methodMuslimWorldLeague => 'Muslim World League (MWL)';

  @override
  String get methodRegionMuslimWorldLeague =>
      'Europe, Far East, parts of the US, and other countries';

  @override
  String get methodUmmAlQura => 'Umm al-Qura University, Makkah';

  @override
  String get methodRegionUmmAlQura => 'The Arabian Peninsula';

  @override
  String get methodKarachi => 'University of Islamic Sciences, Karachi';

  @override
  String get methodRegionKarachi =>
      'Pakistan, Afghanistan, Bangladesh, India, parts of Europe';

  @override
  String get methodJakim =>
      'Department of Islamic Advancement of Malaysia (JAKIM)';

  @override
  String get methodRegionJakim => 'Malaysia';

  @override
  String get methodSingapore => 'Islamic Religious Council of Singapore (MUIS)';

  @override
  String get methodRegionSingapore => 'Singapore';

  @override
  String get methodIndonesia =>
      'Ministry of Religious Affairs of Indonesia (KEMENAG)';

  @override
  String get methodRegionIndonesia => 'Indonesia';

  @override
  String get methodTurkiye =>
      'Presidency of Religious Affairs of Türkiye (Diyanet)';

  @override
  String get methodRegionTurkiye => 'Türkiye';

  @override
  String get methodFrance => 'Union of Islamic Organisations of France (UOIF)';

  @override
  String get methodRegionFrance => 'France';

  @override
  String get methodKuwait => 'Kuwait';

  @override
  String get methodRegionKuwait => 'Kuwait';

  @override
  String get methodQatar => 'Qatar';

  @override
  String get methodRegionQatar => 'Qatar';

  @override
  String get methodDubai => 'Dubai (UAE)';

  @override
  String get methodRegionDubai => 'United Arab Emirates';

  @override
  String get methodGulfRegion => 'Gulf region';

  @override
  String get methodRegionGulfRegion => 'Bahrain, Oman';

  @override
  String get methodJordan => 'Jordan';

  @override
  String get methodRegionJordan => 'Jordan';

  @override
  String get methodAlgeria => 'Algeria';

  @override
  String get methodRegionAlgeria => 'Algeria';

  @override
  String get methodMorocco => 'Morocco';

  @override
  String get methodRegionMorocco => 'Morocco';

  @override
  String get methodTunisia => 'Tunisia';

  @override
  String get methodRegionTunisia => 'Tunisia';

  @override
  String get methodRussia => 'Spiritual Administration of Muslims of Russia';

  @override
  String get methodRegionRussia => 'Russia';

  @override
  String get methodPortugal => 'Islamic Community of Lisbon';

  @override
  String get methodRegionPortugal => 'Portugal';

  @override
  String get methodTehran => 'Institute of Geophysics, University of Tehran';

  @override
  String get methodRegionTehran => 'Iran (Shia)';

  @override
  String get methodJafari => 'Shia Ithna-Ashari, Leva Institute, Qum';

  @override
  String get methodRegionJafari => 'Shia communities';

  @override
  String get settingsPrayerTimesSection => 'Prayer times';

  @override
  String get settingsMethod => 'Calculation method';

  @override
  String get settingsAsr => 'Asr method';

  @override
  String get settingsHighLatitude => 'Higher latitudes';

  @override
  String get settingsAdjustments => 'Manual adjustments';

  @override
  String get settingsHijri => 'Hijri date';

  @override
  String zoneNotePlace(String place, String placeOffset, String phoneOffset) {
    return 'Times are local time in $place ($placeOffset). Your phone\'s clock is on $phoneOffset.';
  }

  @override
  String get inFlightTitle => 'In flight';

  @override
  String onbStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onbContinue => 'Continue';

  @override
  String get onbBack => 'Back';

  @override
  String get onbNotNow => 'Not now';

  @override
  String get onbStart => 'Start';

  @override
  String get onbWelcomeTagline =>
      'Know when to pray. Know when your mosque starts. Get reminded on time.';

  @override
  String get onbWelcomeBody =>
      'Prayer times are worked out on this phone. No account, and nothing about you is uploaded.';

  @override
  String get onbLanguage => 'Language';

  @override
  String onbPlaceFound(String city) {
    return 'Found you near $city';
  }

  @override
  String placeNear(String place, String city) {
    return '$place, near $city';
  }

  @override
  String onbPlaceDone(String place) {
    return 'Prayer times for $place';
  }

  @override
  String get onbMosqueTitle => 'Your mosque';

  @override
  String get onbMosqueBody =>
      'Add the mosque you usually pray at. You then enter its Iqama times yourself: Jama’ah never guesses them. You can add more mosques later.';

  @override
  String onbMosqueDone(String mosque) {
    return 'Added: $mosque. Enter its Iqama times from the Mosques tab.';
  }

  @override
  String get onbAlertsTitle => 'Prayer alerts';

  @override
  String get onbAlertsBody =>
      'An Adhan alert at each prayer time, and a Jama’ah reminder before your mosque\'s Iqama. You can change every alert, its sound and its timing later in Settings.';

  @override
  String get onbAlertsSwitch => 'Adhan alert for the five prayers';

  @override
  String get onbAlertsSwitchHint =>
      'Your phone will ask to allow notifications.';

  @override
  String get onbAlertsBattery =>
      'Some phones stop alerts to save battery. If one doesn\'t arrive, set Jama’ah\'s battery use to Unrestricted in the phone\'s settings.';

  @override
  String get onbTravelTitle => 'Do you travel often?';

  @override
  String get onbTravelBody =>
      'Travel mode lets your prayer times follow you between cities and time zones, without changing your phone\'s clock. On a plane, it adds in-flight mode: prayer times and the Qibla aboard, from GPS, with no internet.';

  @override
  String get onbTravelSwitch => 'Turn on travel mode';

  @override
  String get onbTravelHint =>
      'You can switch it any time with the airplane at the top of the app.';

  @override
  String get settingsShowIntro => 'Show the introduction again';

  @override
  String get inFlightHelp => 'How it works';

  @override
  String get inFlightHelpTitle => 'In-flight mode';

  @override
  String get inFlightHelpIntro =>
      'Prayer times and the Qibla on a plane, with no internet and without changing your phone\'s clock.';

  @override
  String get inFlightHelpStartTitle => 'Starting it';

  @override
  String get inFlightHelpStartBody =>
      'Turn on travel mode with the airplane at the top of the app. On Today, tap “On a flight?”, then “Start GPS” and allow precise location. Sit by a window if you can: the phone\'s GPS works in airplane mode, but needs a view of the sky and can take a minute or two to find you.';

  @override
  String get inFlightHelpTimesTitle => 'The prayer times';

  @override
  String get inFlightHelpTimesBody =>
      '“Now” and “Next” are for where the aircraft is at this moment, shown on your phone\'s clock. Up high, the sun sets later and rises earlier than on the ground below, so Maghrib and sunrise follow the sun as you see it from the aircraft. Fajr and Isha follow your calculation method.';

  @override
  String get inFlightHelpRouteTitle => 'Along the route';

  @override
  String get inFlightHelpRouteBody =>
      'While the aircraft is moving, Jama’ah estimates when you will meet the next prayers if it keeps the same course and speed. The estimate updates with each GPS reading, so it gets better as the flight goes on. Flying east, prayers come sooner; flying west, the aircraft almost keeps pace with the sun, so sunset can stay hours away.';

  @override
  String get inFlightHelpQiblaTitle => 'The Qibla aboard';

  @override
  String get inFlightHelpQiblaBody =>
      'The phone\'s compass is not reliable inside an aircraft, so the arrow uses the direction the aircraft is flying, from GPS. It shows how far to the right or left of the nose the Qibla is. On the ground, or if you prefer, enter the heading shown on the seat-back map.';

  @override
  String get inFlightHelpAlertsTitle => 'Alerts in flight';

  @override
  String get inFlightHelpAlertsBody =>
      'While the aircraft is moving, your usual alerts for the place you left are paused, Jama’ah reminders too, and the next prayer along the route is alerted instead, marked as estimated. It uses that prayer\'s own Adhan settings. The pause ends by itself 90 minutes after the last GPS reading, or when you tap “End in-flight mode”. At home or at the gate nothing is paused.';

  @override
  String get inFlightHelpTipsTitle => 'Good to know';

  @override
  String get inFlightHelpTipsBody =>
      'Keep the in-flight screen open for the best updates; with the screen off for long, the phone may pause GPS. Nothing about where you are is sent anywhere. Questions about how to pray aboard, such as shortening or combining prayers, are for your scholar: Jama’ah gives the times and the direction only.';

  @override
  String notifInFlightBody(String prayer) {
    return 'It\'s time for $prayer, estimated for the aircraft\'s route.';
  }

  @override
  String inFlightAlongRoute(String prayer, String countdown) {
    return 'Along this route: $prayer, $countdown';
  }

  @override
  String inFlightAlongRouteThen(String prayer, String time) {
    return 'Then $prayer, about $time on your phone';
  }

  @override
  String inFlightAboutOnPhone(String time) {
    return 'About $time on your phone';
  }

  @override
  String get inFlightAssumesCourse =>
      'Assumes the aircraft keeps its course and speed; updated with each GPS fix.';

  @override
  String inFlightAlertsHeld(String place, String time) {
    return 'Alerts for $place are paused until $time. The next prayer along the route is alerted instead.';
  }

  @override
  String get inFlightEnd => 'End in-flight mode';

  @override
  String inFlightHeldNote(String time) {
    return 'In-flight mode: regular alerts are paused until $time.';
  }

  @override
  String get inFlightCardTitle => 'On a flight?';

  @override
  String get inFlightCardBody =>
      'Prayer times and the Qibla aboard, from GPS, with no network.';

  @override
  String get inFlightExplainBody =>
      'Jama’ah uses your phone\'s GPS, which works in airplane mode, to find where the aircraft is. It needs precise location, and works best by a window. Nothing is sent anywhere.';

  @override
  String get inFlightStart => 'Start GPS';

  @override
  String get inFlightWaiting => 'Waiting for GPS… A window seat helps.';

  @override
  String get inFlightServiceOff =>
      'Location is off on this phone. Turn it on to use GPS aboard.';

  @override
  String get inFlightNeedsPrecise =>
      'In-flight mode needs precise location. Try again and choose “Precise”.';

  @override
  String get inFlightPermanentlyDenied =>
      'Precise location is turned off for Jama’ah. You can allow it in the app\'s settings.';

  @override
  String get inFlightOpenSettings => 'Open app settings';

  @override
  String get inFlightTryAgain => 'Try again';

  @override
  String inFlightAltitudeSpeed(String altitude, String speed) {
    return '$altitude m · $speed km/h';
  }

  @override
  String inFlightFixAge(String ago) {
    return 'GPS fix $ago';
  }

  @override
  String inFlightFixLost(String ago) {
    return 'GPS lost. Showing the last fix, from $ago.';
  }

  @override
  String inFlightNow(String prayer) {
    return 'Now: $prayer';
  }

  @override
  String get inFlightNoneNow => 'No prayer is due now';

  @override
  String inFlightNext(String prayer, String countdown) {
    return 'Next: $prayer, $countdown';
  }

  @override
  String inFlightOnPhone(String time) {
    return '$time on your phone';
  }

  @override
  String inFlightSunsetLater(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'From up here the sun sets $minutes min later than on the ground below.',
      one: 'From up here the sun sets 1 min later than on the ground below.',
    );
    return '$_temp0';
  }

  @override
  String inFlightSunriseEarlier(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'From up here the sun rises $minutes min earlier than on the ground below.',
      one: 'From up here the sun rises 1 min earlier than on the ground below.',
    );
    return '$_temp0';
  }

  @override
  String get inFlightMovingNote =>
      'For where the aircraft is now. As it flies on, these times change; this screen keeps them up to date while it is open.';

  @override
  String get inFlightTimesHeader => 'Today aboard, on your phone\'s clock';

  @override
  String get inFlightQiblaHeader => 'Qibla aboard';

  @override
  String inFlightQiblaRight(String degrees) {
    return '$degrees° to the right of the nose';
  }

  @override
  String inFlightQiblaLeft(String degrees) {
    return '$degrees° to the left of the nose';
  }

  @override
  String get inFlightQiblaAhead => 'Straight ahead';

  @override
  String get inFlightQiblaBehind => 'Behind you, towards the tail';

  @override
  String inFlightHeadingGps(String degrees) {
    return 'Using the aircraft\'s GPS course, $degrees°';
  }

  @override
  String inFlightHeadingManual(String degrees) {
    return 'Using your heading, $degrees°';
  }

  @override
  String get inFlightNoCourse =>
      'The aircraft isn\'t moving yet, so there is no course. You can enter the heading from the seat-back map.';

  @override
  String get inFlightEnterHeading => 'Enter heading';

  @override
  String get inFlightUseGps => 'Use GPS course';

  @override
  String get inFlightHeadingLabel => 'Heading from the seat-back map (0–359°)';

  @override
  String get inFlightHeadingError => 'Between 0 and 359';

  @override
  String inFlightQiblaBearing(String degrees) {
    return 'Qibla bearing $degrees° from true north';
  }

  @override
  String get inFlightCompassNote =>
      'The phone\'s compass isn\'t reliable inside an aircraft, so this uses the aircraft\'s direction instead.';

  @override
  String get inFlightDiagramLabel =>
      'Aircraft seen from above, nose up. The arrow points to the Qibla.';

  @override
  String zoneNoteHere(String placeOffset, String phoneOffset) {
    return 'Times are local time where you are ($placeOffset). Your phone\'s clock is on $phoneOffset.';
  }

  @override
  String get hijriAsCalculated => 'As calculated (Umm al-Qura)';

  @override
  String hijriLater(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days later',
      one: '1 day later',
    );
    return '$_temp0';
  }

  @override
  String hijriEarlier(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days earlier',
      one: '1 day earlier',
    );
    return '$_temp0';
  }

  @override
  String get hijriAdjustNote =>
      'Match the date your country announces. Kuwait and others start each month by moon sighting, which can differ from the calculation by a day or two. Prayer times stay as they are, except that with Umm al-Qura, Ramadan\'s later Isha follows this date.';

  @override
  String methodAngles(String fajr, String isha) {
    return 'Fajr $fajr° · Isha $isha°';
  }

  @override
  String methodAnglesInterval(String fajr, int minutes) {
    return 'Fajr $fajr° · Isha $minutes min after Maghrib';
  }

  @override
  String get methodUmmAlQuraRamadan =>
      'Isha 120 min after Maghrib during Ramadan';

  @override
  String get methodMoonsightingNote => 'Also adjusts Fajr and Isha by season';

  @override
  String methodAutoResolved(String method, String place) {
    return 'Uses $method for $place';
  }

  @override
  String get methodAutoNoPlace => 'Chooses by your place once one is set';

  @override
  String get customTitle => 'Custom angles';

  @override
  String get customFajr => 'Fajr angle (°)';

  @override
  String get customIsha => 'Isha angle (°)';

  @override
  String get customIshaByMinutes => 'Isha by minutes after Maghrib';

  @override
  String get customIshaMinutes => 'Minutes after Maghrib';

  @override
  String get customAngleError => 'Between 10° and 22°';

  @override
  String get customMinutesError => 'Between 1 and 180 minutes';

  @override
  String get asrStandard => 'Standard';

  @override
  String get asrStandardHint =>
      'Shafi\'i, Maliki, Hanbali: the earlier Asr time';

  @override
  String get asrHanafi => 'Hanafi';

  @override
  String get asrHanafiHint => 'The later Asr time';

  @override
  String get ruleMiddleOfTheNightTitle => 'Middle of the night';

  @override
  String get ruleSeventhOfTheNightTitle => 'One seventh of the night';

  @override
  String get ruleTwilightAngleTitle => 'Twilight angle';

  @override
  String get ruleMiddleOfTheNightHint =>
      'Fajr and Isha no later than the middle of the night (default)';

  @override
  String get ruleSeventhOfTheNightHint =>
      'Fajr and Isha within the first and last seventh of the night';

  @override
  String get ruleTwilightAngleHint =>
      'A share of the night proportional to the method\'s angles';

  @override
  String get highLatitudeSettingsNote =>
      'Only used where the sun stays close to the horizon at night; elsewhere it changes nothing.';

  @override
  String get adjustmentsHint =>
      'Minutes added to or taken from the calculated time, for example to match your mosque\'s printed timetable.';

  @override
  String adjustmentsMinus(String prayer) {
    return '$prayer: one minute earlier';
  }

  @override
  String adjustmentsPlus(String prayer) {
    return '$prayer: one minute later';
  }

  @override
  String adjustmentsValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get adjustmentsNone => 'None';

  @override
  String get adjustmentsReset => 'Reset all to 0';

  @override
  String get reminderSoundChime => 'Chime';

  @override
  String get soundHayya => 'حيّ على الصلاة';

  @override
  String get reminderSoundHayyaHint =>
      'The call to prayer from the Adhan, about 10 seconds.';

  @override
  String get settingsShortAdhan => 'Short Adhan';

  @override
  String get shortAdhanNaghshbandi => 'Naghshbandi, opening';

  @override
  String get shortAdhanNaghshbandiHint =>
      'The first 8 seconds of Naghshbandi\'s Adhan.';

  @override
  String get shortAdhanHayyaHint =>
      '«حيّ على الصلاة» from the Adhan, 10 seconds.';

  @override
  String get settingsReminderSound => 'Reminder sound';

  @override
  String get reminderSoundChimeHint =>
      'A soft two-note chime, different from the Adhan and from other apps.';

  @override
  String get reminderSoundStandardHint =>
      'Your phone\'s usual notification sound.';

  @override
  String get reminderSoundSilentHint =>
      'Shown in your notifications without any sound.';

  @override
  String get settingsReminderVibrate => 'Vibrate';

  @override
  String get settingsReminderTest => 'Send a test reminder';

  @override
  String get settingsReminderTestSent => 'Test reminder sent.';

  @override
  String get settingsPauseAllIqama => 'Pause all Jama’ah reminders';

  @override
  String get settingsPauseAllIqamaHint =>
      'No Jama’ah reminders from any mosque until you turn this off. Your Iqama times are kept. Adhan alerts are not affected.';

  @override
  String get mosquePauseReminders => 'Pause this mosque\'s reminders';

  @override
  String get mosquePauseRemindersHint =>
      'Its Iqama times and reminder settings are kept. Applies while this is your active mosque.';

  @override
  String get mosquePauseAllOn =>
      'All Jama’ah reminders are paused in Settings.';

  @override
  String get pausedAllNote => 'All Jama’ah reminders are paused.';

  @override
  String pausedMosqueNote(String mosque) {
    return '$mosque\'s Jama’ah reminders are paused.';
  }

  @override
  String get tagRemindersPaused => 'Reminders paused';

  @override
  String get prayerJumuah => 'Jumu’ah';

  @override
  String get extraImsak => 'Imsak';

  @override
  String get extraDuha => 'Duha';

  @override
  String get extraQiyam => 'Last third of the night';

  @override
  String get notifImsakBody => 'Imsak: stop eating before Fajr.';

  @override
  String get notifDuhaBody => 'The time for Duha prayer has begun.';

  @override
  String get notifQiyamBody => 'The last third of the night has begun.';

  @override
  String channelExtra(String sound) {
    return 'Other times · $sound';
  }

  @override
  String get kindExtra => 'Extra time';

  @override
  String get settingsExtraTimes => 'Extra times';

  @override
  String get extraTimesIntro =>
      'Times beside the five prayers, worked out from your prayer times. They have no Iqama.';

  @override
  String get extraShowOnToday => 'Show on Today';

  @override
  String get extraAlert => 'Alert';

  @override
  String get extraAlertHint => 'Uses your Jama’ah reminder sound.';

  @override
  String extraImsakRule(int minutes) {
    return '$minutes min before Fajr';
  }

  @override
  String extraDuhaRule(int minutes) {
    return '$minutes min after sunrise';
  }

  @override
  String get extraQiyamRule =>
      'The last third of the time from Maghrib to Fajr.';

  @override
  String get extraNoneShown => 'None shown';

  @override
  String get listSeparator => ', ';

  @override
  String get jumuahNotSetNote => 'Jumu’ah time not set · showing Dhuhr Iqama';

  @override
  String get jumuahRowHint => 'Fridays, in place of Dhuhr';

  @override
  String get jumuahRowNotSet => 'Jumu’ah time not set';

  @override
  String get settingsAdhanRingInSilent => 'Adhan rings on silent';

  @override
  String get settingsPreAdhanRingInSilent =>
      'Reminders before the Adhan ring on silent';

  @override
  String get ringInSilentSome =>
      'On for some prayers. Each prayer’s page can change it.';

  @override
  String get alertPreAdhanRingInSilent => 'Reminder rings on silent';

  @override
  String get onbRingInSilent => 'Ring even when my phone is on silent';

  @override
  String get onbRingInSilentHint =>
      'For the Adhan, the reminder before it and Jama’ah reminders, through the alarm volume. You can change each one in Settings.';

  @override
  String get iqamaModeAfterAdhan => 'Minutes after Adhan';

  @override
  String get iqamaModeFixed => 'Fixed time';

  @override
  String get iqamaMinutesLabel => 'Minutes after the Adhan';

  @override
  String iqamaAfterAdhanPreview(String adhan, int minutes, String iqama) {
    return 'Adhan $adhan + $minutes min = Iqama $iqama today';
  }

  @override
  String get iqamaMinutesInvalid => 'Enter 1 to 90 minutes';

  @override
  String get iqamaNeedsAdhan => 'Set your location to see today’s time.';

  @override
  String rowAfterAdhan(int minutes) {
    return '$minutes min after Adhan';
  }

  @override
  String get enterAllFive => 'Enter minutes for all five';

  @override
  String get enterAllFiveTitle => 'Iqama: minutes after the Adhan';

  @override
  String get enterAllFiveHint =>
      'As your mosque publishes them, e.g. Fajr 22. Empty fields stay as they are.';

  @override
  String iqamaAfterAdhanPreviewTomorrow(
    String adhan,
    int minutes,
    String iqama,
  ) {
    return 'Adhan $adhan + $minutes min = Iqama $iqama tomorrow';
  }
}
