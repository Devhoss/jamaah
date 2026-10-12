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
  String get wordmark => 'Prayer companion';

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
  String get aboutBody =>
      'Early build. Prayer times are calculated on this device. Iqama times are entered by you, per mosque.';

  @override
  String get nextStepPlaceholder => 'Screens arrive step by step.';

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
  String get locationThisDevice => 'This device';

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
