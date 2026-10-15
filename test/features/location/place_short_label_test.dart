import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/features/location/place_copy.dart';

/// Today's top bar names a place the phone found by the nearest bundled city,
/// offline (owner, 2026-10-16), always as "near …", never as an address.
void main() {
  final t = AppLocalizationsEn();

  Place device({
    double lat = 29.3759,
    double lng = 47.9774,
    String zone = 'Asia/Kuwait',
    String? userName,
  }) => Place(
    displayName: zone,
    latitude: lat,
    longitude: lng,
    ianaZone: zone,
    fromDevice: true,
    userName: userName,
  );

  test('a found place is named by the nearest city in the list', () {
    final label = placeShortLabel(t, device());
    expect(label, startsWith('Near '));
    expect(label, contains('Kuwait'));
  });

  test('far from every city, the zone still names the region', () {
    // Mid-desert, far from the list, in a zone named after a city.
    final label = placeShortLabel(
      t,
      device(lat: 23.0, lng: 52.0, zone: 'Asia/Dubai'),
    );
    expect(label, t.placeNearCity('Dubai'));
  });

  test('with nothing to name it by, it stays the current location', () {
    expect(
      placeShortLabel(t, device(lat: -60, lng: -120, zone: 'Etc/GMT+8')),
      t.locationCurrentPlace,
    );
  });

  test('a name the user gave, or a chosen city, is shown as it is', () {
    expect(placeShortLabel(t, device(userName: 'Home')), 'Home');
    const city = Place(
      displayName: 'Cairo, Egypt',
      latitude: 30.0444,
      longitude: 31.2357,
      ianaZone: 'Africa/Cairo',
      fromDevice: false,
    );
    expect(placeShortLabel(t, city), 'Cairo, Egypt');
  });
}
