import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/in_flight.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/prayer_times_calculator.dart';
import 'package:jamaah/src/domain/prayer_times_parameters.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

/// In-flight mode, phase 1: the sun seen from the aircraft, and the Qibla
/// relative to its nose.
void main() {
  setUpAll(loadTimeZoneDatabase);

  const cairoLat = 30.0444, cairoLng = 31.2357;
  final cairoZone = zoneOffsetsFor('Africa/Cairo');
  PrayerTimesCalculator calc({
    CalculationMethod method = CalculationMethod.muslimWorldLeague,
  }) => PrayerTimesCalculator(
    latitude: cairoLat,
    longitude: cairoLng,
    zone: cairoZone,
    method: method,
  );
  DateTime instantOf(Prayer p, LocalDay day) => cairoZone.utcInstantOf(
    day: day,
    time: LocalTime(calc().forDay(day).timeOf(p)!),
  );
  const day = LocalDay(2026, 10, 14);

  test('the horizon drops about 3° at a cruising altitude of 11 km', () {
    expect(horizonDipDegrees(0), 0);
    expect(horizonDipDegrees(11000), closeTo(3.08, 0.02));
  });

  test('the sun model agrees with the prayer library at ground level', () {
    // At the library's sunset and sunrise the sun is at -0.833° (to within
    // the minute the library rounds to).
    for (final p in [Prayer.sunrise, Prayer.maghrib]) {
      expect(
        solarAltitude(
          latitude: cairoLat,
          longitude: cairoLng,
          utc: instantOf(p, day),
        ),
        closeTo(-0.833, 0.25),
        reason: p.name,
      );
    }
  });

  test('on the ground nothing moves; at cruise sunset is later, sunrise '
      'earlier', () {
    Duration? shift(Prayer p, double alt, {required bool setting}) =>
        altitudeShift(
          latitude: cairoLat,
          longitude: cairoLng,
          groundEvent: instantOf(p, day),
          altitudeMeters: alt,
          setting: setting,
        );
    expect(shift(Prayer.maghrib, 0, setting: true), Duration.zero);
    final later = shift(Prayer.maghrib, 11000, setting: true)!;
    // About 3.1° of extra dip at ~13.5° of sun motion per hour at 30°N.
    expect(later.inMinutes, inInclusiveRange(12, 18));
    final earlier = shift(Prayer.sunrise, 11000, setting: false)!;
    expect(earlier.inMinutes, inInclusiveRange(-18, -12));
  });

  group('the times aboard', () {
    InFlightTimes at(DateTime now, {double altitude = 11000}) => inFlightTimes(
      calculator: calc(),
      zone: cairoZone,
      fix: InFlightFix(
        latitude: cairoLat,
        longitude: cairoLng,
        at: now,
        altitudeMeters: altitude,
      ),
      now: now,
    );

    test('Maghrib is moved by the sunset shift; Dhuhr and Asr are not', () {
      final noon = DateTime.utc(2026, 10, 14, 10, 0);
      final aloft = at(noon);
      final ground = at(noon, altitude: 0);
      expect(
        aloft.times[Prayer.maghrib]!.difference(ground.times[Prayer.maghrib]!),
        aloft.sunsetShift,
      );
      expect(aloft.times[Prayer.dhuhr], ground.times[Prayer.dhuhr]);
      expect(aloft.times[Prayer.asr], ground.times[Prayer.asr]);
      expect(
        aloft.times[Prayer.isha],
        ground.times[Prayer.isha],
        reason: 'MWL sets Isha by angle, not by minutes after Maghrib',
      );
    });

    test('an Isha set as minutes after Maghrib moves with Maghrib', () {
      final noon = DateTime.utc(2026, 10, 14, 10, 0);
      InFlightTimes um(double alt) => inFlightTimes(
        calculator: calc(method: CalculationMethod.ummAlQura),
        zone: cairoZone,
        fix: InFlightFix(
          latitude: cairoLat,
          longitude: cairoLng,
          at: noon,
          altitudeMeters: alt,
        ),
        now: noon,
      );
      final aloft = um(11000), ground = um(0);
      expect(
        aloft.times[Prayer.isha]!.difference(ground.times[Prayer.isha]!),
        aloft.sunsetShift,
      );
    });

    test('says which prayer it is and which comes next', () {
      // 13:00 Cairo (UTC+3): after Dhuhr, before Asr.
      final t = at(DateTime.utc(2026, 10, 14, 10, 0));
      expect(t.current, Prayer.dhuhr);
      expect(t.next, Prayer.asr);
    });

    test('between sunrise and Dhuhr no prayer is current', () {
      final t = at(DateTime.utc(2026, 10, 14, 6, 0)); // 09:00 Cairo
      expect(t.current, isNull);
      expect(t.next, Prayer.dhuhr);
    });

    test('after midnight, before Fajr, it is still Isha', () {
      final t = at(DateTime.utc(2026, 10, 13, 23, 28)); // 02:28 Cairo
      expect(t.current, Prayer.isha);
      expect(t.next, Prayer.fajr);
    });

    test('after Isha the next is tomorrow’s Fajr', () {
      final t = at(DateTime.utc(2026, 10, 14, 20, 0)); // 23:00 Cairo
      expect(t.current, Prayer.isha);
      expect(t.next, Prayer.fajr);
      expect(t.nextAt!.isAfter(DateTime.utc(2026, 10, 14, 20, 0)), isTrue);
    });
  });

  group('the Qibla from the aircraft', () {
    test('to the right or left of the nose, the short way', () {
      // Cairo's Qibla is about 136°.
      expect(
        qiblaFromNose(latitude: cairoLat, longitude: cairoLng, heading: 90),
        closeTo(46.1, 0.2),
      );
      expect(
        qiblaFromNose(latitude: cairoLat, longitude: cairoLng, heading: 300),
        closeTo(-163.9, 0.2),
      );
      expect(
        qiblaFromNose(latitude: cairoLat, longitude: cairoLng, heading: 136.1),
        closeTo(0, 0.2),
      );
    });

    test('a course only counts while the aircraft is moving', () {
      final t = DateTime.utc(2026);
      expect(
        InFlightFix(
          latitude: 0,
          longitude: 0,
          at: t,
          courseDegrees: 90,
          speedMetersPerSecond: 240,
        ).hasCourse,
        isTrue,
      );
      expect(
        InFlightFix(
          latitude: 0,
          longitude: 0,
          at: t,
          courseDegrees: 90,
          speedMetersPerSecond: 2,
        ).hasCourse,
        isFalse,
      );
    });
  });

  group('along the route', () {
    test('a great-circle step lands where it should', () {
      final p = destinationPoint(
        latitude: 0,
        longitude: 0,
        bearing: 90,
        distanceMeters: 111195,
      );
      expect(p.latitude, closeTo(0, 1e-6));
      expect(p.longitude, closeTo(1, 1e-3));
    });

    InFlightFix flying(double course, {double speed = 250, DateTime? at}) =>
        InFlightFix(
          latitude: cairoLat,
          longitude: cairoLng,
          at: at ?? DateTime.utc(2026, 10, 14, 10, 0),
          altitudeMeters: 11000,
          speedMetersPerSecond: speed,
          courseDegrees: course,
        );

    test('standing still, there is nothing to project', () {
      final still = InFlightFix(
        latitude: cairoLat,
        longitude: cairoLng,
        at: DateTime.utc(2026, 10, 14, 10, 0),
      );
      expect(
        projectAlongRoute(calculator: calc(), fix: still, now: still.at),
        isEmpty,
      );
    });

    test('barely moving, the projection agrees with here and now', () {
      // 15:50 in Cairo, minutes before Asr, so the aircraft has not gone far.
      final fix = flying(
        270,
        speed: 10,
        at: DateTime.utc(2026, 10, 14, 12, 50),
      );
      final here = inFlightTimes(
        calculator: calc(),
        zone: cairoZone,
        fix: fix,
        now: fix.at,
      );
      final route = projectAlongRoute(
        calculator: calc(),
        fix: fix,
        now: fix.at,
      );
      expect(here.next, Prayer.asr);
      expect(route.first.prayer, Prayer.asr);
      expect(
        route.first.at.difference(here.nextAt!).inSeconds.abs(),
        lessThanOrEqualTo(90),
        reason: 'both round to whole minutes',
      );
    });

    test('flying west chases the sun; flying east meets the night', () {
      final noon = DateTime.utc(2026, 10, 14, 10, 0);
      ProjectedPrayer first(double course, {double speed = 250}) =>
          projectAlongRoute(
            calculator: calc(),
            fix: flying(course, speed: speed),
            now: noon,
          ).first;
      final still = first(270, speed: 10);
      expect(still.prayer, Prayer.asr);
      expect(first(270).prayer, Prayer.asr);
      expect(
        first(270).at.isAfter(still.at.add(const Duration(hours: 1))),
        isTrue,
        reason: 'at 900 km/h west the aircraft nearly keeps pace with the sun',
      );
      expect(
        first(90).at.isBefore(still.at.subtract(const Duration(minutes: 30))),
        isTrue,
      );
    });

    test('the times come in order, and quickly enough to redo every fix', () {
      final sw = Stopwatch()..start();
      final route = projectAlongRoute(
        calculator: calc(),
        fix: flying(90),
        now: DateTime.utc(2026, 10, 14, 10, 0),
        maxEvents: 3,
      );
      sw.stop();
      expect(route, hasLength(3));
      for (var i = 1; i < route.length; i++) {
        expect(route[i].at.isAfter(route[i - 1].at), isTrue);
      }
      expect(route.map((e) => e.prayer), [
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      ]);
      expect(sw.elapsedMilliseconds, lessThan(3000));
    });
  });
}
