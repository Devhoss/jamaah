import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/place_follow.dart';

/// Whether a follow check moves the saved place (2026-11-02): a device place
/// moves with the phone, a place picked by hand is pinned and offered.
void main() {
  Place device(double lat, double lng, String zone) => Place(
    displayName: zone,
    latitude: lat,
    longitude: lng,
    ianaZone: zone,
    fromDevice: true,
  );

  Place picked(double lat, double lng, String zone) => Place(
    displayName: 'Cairo, Egypt',
    latitude: lat,
    longitude: lng,
    ianaZone: zone,
    fromDevice: false,
  );

  final cairo = device(30.0444, 31.2357, 'Africa/Cairo');
  final pickedCairo = picked(30.0444, 31.2357, 'Africa/Cairo');

  test('a few kilometres around town keeps a device place', () {
    expect(
      decideFollow(saved: cairo, fix: device(30.0800, 31.2800, 'Africa/Cairo')),
      FollowDecision.keep,
    );
  });

  test('a few kilometres around town keeps a picked place', () {
    expect(
      decideFollow(
        saved: pickedCairo,
        fix: device(30.0800, 31.2800, 'Africa/Cairo'),
      ),
      FollowDecision.keep,
    );
  });

  test('another city replaces a device place', () {
    // Alexandria, about 180 km away.
    expect(
      decideFollow(saved: cairo, fix: device(31.2001, 29.9187, 'Africa/Cairo')),
      FollowDecision.replace,
    );
  });

  test('a device place in another zone is replaced, however short', () {
    final nearbyOtherZone = device(30.05, 31.24, 'Asia/Jerusalem');
    expect(
      decideFollow(saved: cairo, fix: nearbyOtherZone),
      FollowDecision.replace,
    );
  });

  test('another city never moves a picked place silently', () {
    expect(
      decideFollow(
        saved: pickedCairo,
        fix: device(31.2001, 29.9187, 'Africa/Cairo'),
      ),
      FollowDecision.offer,
    );
  });

  test('a picked place in another zone is offered too', () {
    expect(
      decideFollow(
        saved: pickedCairo,
        fix: device(30.05, 31.24, 'Asia/Jerusalem'),
      ),
      FollowDecision.offer,
    );
  });

  test('no saved place takes the fix', () {
    expect(decideFollow(saved: null, fix: cairo), FollowDecision.replace);
  });
}
