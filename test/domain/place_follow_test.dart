import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/place_follow.dart';

/// When "Follow my location" replaces the saved place (cabin crew, 2026-10-13).
void main() {
  Place device(double lat, double lng, String zone) => Place(
    displayName: zone,
    latitude: lat,
    longitude: lng,
    ianaZone: zone,
    fromDevice: true,
  );

  final cairo = device(30.0444, 31.2357, 'Africa/Cairo');

  test('a few kilometres around town keeps the place', () {
    expect(
      decideFollow(saved: cairo, fix: device(30.0800, 31.2800, 'Africa/Cairo')),
      FollowDecision.keep,
    );
  });

  test('another city replaces it', () {
    // Alexandria, about 180 km away.
    expect(
      decideFollow(saved: cairo, fix: device(31.2001, 29.9187, 'Africa/Cairo')),
      FollowDecision.replace,
    );
  });

  test('a flight to another zone replaces it, however short', () {
    final nearbyOtherZone = device(30.05, 31.24, 'Asia/Jerusalem');
    expect(
      decideFollow(saved: cairo, fix: nearbyOtherZone),
      FollowDecision.replace,
    );
  });

  test('a city picked from the list gives way to the first fix', () {
    const picked = Place(
      displayName: 'Cairo, Egypt',
      latitude: 30.0444,
      longitude: 31.2357,
      ianaZone: 'Africa/Cairo',
      fromDevice: false,
    );
    expect(decideFollow(saved: picked, fix: cairo), FollowDecision.replace);
  });

  test('no saved place takes the fix', () {
    expect(decideFollow(saved: null, fix: cairo), FollowDecision.replace);
  });
}
