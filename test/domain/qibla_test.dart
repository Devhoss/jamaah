import 'package:jamaah/src/domain/qibla.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Qibla bearing is a great-circle initial bearing to the Kaaba
/// (21.4225°N, 39.8262°E). Expected values below are real computed bearings,
/// cross-checked against the bearings shown in the design prototype.
void main() {
  group('qibla bearing against known cities', () {
    test('values match known cities', () {
      expect(
        qiblaBearingFor(latitude: 51.5074, longitude: -0.1278),
        closeTo(118.99, 0.05),
      );
      expect(
        qiblaBearingFor(latitude: 40.7128, longitude: -74.0060),
        closeTo(58.48, 0.05),
      );
      expect(
        qiblaBearingFor(latitude: 43.6532, longitude: -79.3832),
        closeTo(54.58, 0.05),
      );
      expect(
        qiblaBearingFor(latitude: 30.0444, longitude: 31.2357),
        closeTo(136.14, 0.05),
      );
      expect(
        qiblaBearingFor(latitude: -6.2088, longitude: 106.8456),
        closeTo(295.15, 0.05),
      );
    });

    test('the prototype bearings are real, not decorative', () {
      // docs/prayer-prototype.html shows these rounded degrees; they must agree
      // with the calculation, or the prototype would be shipping wrong numbers.
      expect(
        qiblaBearingFor(latitude: 51.5074, longitude: -0.1278),
        closeTo(119, 0.5),
      );
      expect(
        qiblaBearingFor(latitude: 40.7128, longitude: -74.0060),
        closeTo(58, 0.5),
      );
      expect(
        qiblaBearingFor(latitude: 43.6532, longitude: -79.3832),
        closeTo(55, 0.5),
      );
      expect(
        qiblaBearingFor(latitude: 30.0444, longitude: 31.2357),
        closeTo(136, 0.5),
      );
      expect(
        qiblaBearingFor(latitude: -6.2088, longitude: 106.8456),
        closeTo(295, 0.5),
      );
    });

    test('cardinal directions around the Kaaba', () {
      expect(
        qiblaBearingFor(latitude: 30.0, longitude: 39.8261818),
        closeTo(180, 0.01),
        reason: 'due north of the Kaaba faces due south',
      );
      // A point on the same parallel does NOT face due east: the great circle
      // bends toward the pole, so the initial bearing is slightly north of east.
      expect(
        qiblaBearingFor(latitude: 21.4225241, longitude: 30.0),
        closeTo(88.2, 0.5),
      );
      expect(
        qiblaBearingFor(latitude: 21.4225241, longitude: 50.0),
        closeTo(271.8, 0.5),
      );
    });

    test('bearings always land in [0, 360)', () {
      for (var lat = -80.0; lat <= 80.0; lat += 20) {
        for (var lng = -180.0; lng <= 180.0; lng += 30) {
          final b = qiblaBearingFor(latitude: lat, longitude: lng);
          expect(b, greaterThanOrEqualTo(0));
          expect(b, lessThan(360));
        }
      }
    });

    test('the rounded bearing is what the UI shows', () {
      expect(
        qiblaBearingRounded(latitude: 51.5074, longitude: -0.1278),
        119,
      );
      expect(
        qiblaBearingRounded(latitude: 30.0444, longitude: 31.2357),
        136,
      );
    });
  });

  group('turning toward the qibla', () {
    test('difference is the shortest way round', () {
      expect(angleDifference(350, 10), 20);
      expect(angleDifference(10, 350), -20);
      expect(angleDifference(90, 270), 180, reason: 'exactly opposite turns right');
      expect(angleDifference(270, 90), 180);
      expect(angleDifference(0, 0), 0);
    });

    test('aligned means within the tolerance', () {
      expect(isAligned(100, 100, toleranceDegrees: 3), isTrue);
      expect(isAligned(100, 103, toleranceDegrees: 3), isTrue);
      expect(isAligned(100, 97, toleranceDegrees: 3), isTrue);
      expect(isAligned(100, 104, toleranceDegrees: 3), isFalse);
      expect(isAligned(100, 96, toleranceDegrees: 3), isFalse);
    });

    test('the app never asks the user to turn more than 180 degrees', () {
      for (var heading = 0; heading < 360; heading += 7) {
        expect(angleDifference(heading, 118).abs(), lessThanOrEqualTo(180));
      }
    });
  });

  group('distance to the kaaba', () {
    test('known great-circle distances', () {
      // London ~4,800 km, New York ~10,300 km, Jakarta ~7,900 km.
      expect(
        distanceKm(latitude: 51.5074, longitude: -0.1278),
        inInclusiveRange(4700, 4900),
      );
      expect(
        distanceKm(latitude: 40.7128, longitude: -74.0060),
        inInclusiveRange(10100, 10600),
      );
      expect(
        distanceKm(latitude: -6.2088, longitude: 106.8456),
        inInclusiveRange(7700, 8100),
      );
    });

    test('a location on the kaaba has no distance', () {
      expect(
        distanceKm(latitude: 21.4225241, longitude: 39.8261818),
        closeTo(0, 0.001),
      );
    });
  });

  group('true heading', () {
    test('an east declination is added to the magnetic heading', () {
      expect(trueHeading(100, 5), 105);
    });

    test('a west declination is subtracted, and wraps past north', () {
      expect(trueHeading(2, -5), 357);
      expect(trueHeading(358, 5), 3);
    });
  });
}
