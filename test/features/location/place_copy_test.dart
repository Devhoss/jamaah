import 'package:flutter_test/flutter_test.dart';

import 'package:awqaity/src/app/l10n/generated/app_localizations_en.dart';
import 'package:awqaity/src/domain/place.dart';
import 'package:awqaity/src/features/location/place_copy.dart';

/// What a saved place is called. The chip on Today and the line in the sheet read
/// from here, so they cannot disagree about whose name is showing.
void main() {
  final t = AppLocalizationsEn();

  Place device({String? userName}) => Place(
    displayName: 'Africa/Cairo',
    latitude: 30.0444,
    longitude: 31.2357,
    ianaZone: 'Africa/Cairo',
    fromDevice: true,
    userName: userName,
  );

  const listPlace = Place(
    displayName: 'Cairo, Egypt',
    latitude: 30.0444,
    longitude: 31.2357,
    ianaZone: 'Africa/Cairo',
    fromDevice: false,
  );

  test('a device place is called the current location, never a zone name', () {
    expect(placeLabel(t, device()), t.locationCurrentPlace);
    expect(
      placeLabel(t, device()),
      'Current location',
      reason: 'the owner asked for these words, so they are pinned here once',
    );
  });

  test('a place the user named is called what they called it', () {
    expect(placeLabel(t, device(userName: 'Home')), 'Home');
    expect(placeLabel(t, const Place(
      displayName: 'Cairo, Egypt',
      latitude: 30.0444,
      longitude: 31.2357,
      ianaZone: 'Africa/Cairo',
      fromDevice: false,
      userName: 'Where we stay in summer',
    )), 'Where we stay in summer');
  });

  test('a city from the list keeps the list’s own name', () {
    expect(placeLabel(t, listPlace), 'Cairo, Egypt');
  });
}
