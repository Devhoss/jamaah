import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/place_near.dart';

/// "Found you near Cairo": a name for a point the phone found, with no network.
void main() {
  test('the nearest bundled city, when one is close', () {
    expect(
      nearName(latitude: 30.06, longitude: 31.25, ianaZone: 'Africa/Cairo'),
      'Cairo',
    );
    expect(
      nearName(latitude: 29.37, longitude: 47.98, ianaZone: 'Asia/Kuwait'),
      'Kuwait City',
    );
  });

  test('otherwise the city in the time zone name', () {
    // The middle of the Empty Quarter: no bundled city within 75 km.
    expect(
      nearName(latitude: 20.0, longitude: 50.0, ianaZone: 'Asia/Riyadh'),
      'Riyadh',
    );
    expect(
      nearName(
        latitude: 40.0,
        longitude: -100.0,
        ianaZone: 'America/Los_Angeles',
      ),
      'Los Angeles',
    );
  });

  test('no name rather than a made-up one', () {
    expect(
      nearName(latitude: 0, longitude: -140, ianaZone: 'device/GMT'),
      isNull,
    );
    expect(nearName(latitude: 0, longitude: -140, ianaZone: 'UTC'), isNull);
  });
}
