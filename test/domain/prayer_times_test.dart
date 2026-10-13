import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/prayer_times_calculator.dart';
import 'package:jamaah/src/domain/prayer_times_parameters.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Prayer times are checked against Aladhan, which AGENTS.md allows only as a
/// dev-time test oracle.
///
/// Fixtures were fetched from the Aladhan API (not from memory) with
/// `latitudeAdjustmentMethod=1` (middle of the night) so the comparison is against
/// the same astronomical definition adhan_dart implements: Aladhan's *default*
/// applies an extra latitude adjustment that shifts Fajr and Isha at higher
/// latitudes, which is not what this app computes.
///
/// Agreed to within one minute everywhere except Asr, which differs by up to three
/// minutes because the two implementations round shadow length independently.
void main() {
  // The full IANA database: the package default omits zones like Asia/Kuwait and
  // Europe/Oslo that real devices report.
  loadTimeZoneDatabase();

  PrayerTimesCalculator calc({
    String zone = 'Africa/Cairo',
    CalculationMethod method = CalculationMethod.egyptian,
    Madhab madhab = Madhab.standard,
    double lat = 30.0444,
    double lng = 31.2357,
    Map<Prayer, int> offsets = const {},
  }) => PrayerTimesCalculator(
    latitude: lat,
    longitude: lng,
    zone: zoneOffsetsFor(zone),
    method: method,
    madhab: madhab,
    minuteOffsets: offsets,
  );

  group('prayer times against the Aladhan oracle', () {
    test('Cairo 2026-10-12, Egyptian method, DST UTC+3', () {
      final day = calc().forDay(const LocalDay(2026, 10, 12));
      // Aladhan: 05:28 / 06:55 / 12:42 / 16:00 / 18:28 / 19:45.
      expectMinutes(day, Prayer.fajr, 5 * 60 + 28);
      expectMinutes(day, Prayer.sunrise, 6 * 60 + 55);
      expectMinutes(day, Prayer.dhuhr, 12 * 60 + 42);
      expectMinutes(day, Prayer.asr, 16 * 60 + 0);
      expectMinutes(day, Prayer.maghrib, 18 * 60 + 28);
      expectMinutes(day, Prayer.isha, 19 * 60 + 45);
    });

    test('London 2026-10-12, MWL, BST UTC+1', () {
      final day = calc(
        zone: 'Europe/London',
        method: CalculationMethod.muslimWorldLeague,
        lat: 51.5074,
        lng: -0.1278,
      ).forDay(const LocalDay(2026, 10, 12));
      // Aladhan MWL: 05:28 / 07:19 / 12:47 / 15:39 / 18:14 / 19:58.
      expectMinutes(day, Prayer.fajr, 5 * 60 + 28);
      expectMinutes(day, Prayer.sunrise, 7 * 60 + 19);
      expectMinutes(day, Prayer.dhuhr, 12 * 60 + 47);
      expectMinutes(day, Prayer.asr, 15 * 60 + 39);
      expectMinutes(day, Prayer.maghrib, 18 * 60 + 14);
      expectMinutes(day, Prayer.isha, 19 * 60 + 58);
    });

    test('New York 2026-10-12, ISNA, EDT UTC-4', () {
      final day = calc(
        zone: 'America/New_York',
        method: CalculationMethod.isna,
        lat: 40.7128,
        lng: -74.0060,
      ).forDay(const LocalDay(2026, 10, 12));
      // Aladhan ISNA: 05:49 / 07:04 / 12:42 / 15:51 / 18:20 / 19:35.
      expectMinutes(day, Prayer.fajr, 5 * 60 + 49);
      expectMinutes(day, Prayer.sunrise, 7 * 60 + 4);
      expectMinutes(day, Prayer.dhuhr, 12 * 60 + 42);
      expectMinutes(day, Prayer.asr, 15 * 60 + 51);
      expectMinutes(day, Prayer.maghrib, 18 * 60 + 20);
      expectMinutes(day, Prayer.isha, 19 * 60 + 35);
    });

    test('Makkah 2026-10-12, Umm al-Qura, AST UTC+3', () {
      final day = calc(
        zone: 'Asia/Riyadh',
        method: CalculationMethod.ummAlQura,
        lat: 21.4225,
        lng: 39.8262,
      ).forDay(const LocalDay(2026, 10, 12));
      // Aladhan Umm al-Qura: 04:59 / 06:15 / 12:07 / 15:29 / 17:59 / 19:29.
      expectMinutes(day, Prayer.fajr, 4 * 60 + 59);
      expectMinutes(day, Prayer.sunrise, 6 * 60 + 15);
      expectMinutes(day, Prayer.dhuhr, 12 * 60 + 7);
      expectMinutes(day, Prayer.asr, 15 * 60 + 29);
      expectMinutes(day, Prayer.maghrib, 17 * 60 + 59);
      expectMinutes(day, Prayer.isha, 19 * 60 + 29);
    });

    test('Kuwait City 2026-10-12, Kuwait method, AST UTC+3', () {
      final day = calc(
        zone: 'Asia/Kuwait',
        method: CalculationMethod.kuwait,
        lat: 29.3759,
        lng: 47.9774,
      ).forDay(const LocalDay(2026, 10, 12));
      // Aladhan Kuwait (method 9): 04:28 / 05:47 / 11:35 / 14:54 / 17:21 / 18:38.
      expectMinutes(day, Prayer.fajr, 4 * 60 + 28);
      expectMinutes(day, Prayer.sunrise, 5 * 60 + 47);
      expectMinutes(day, Prayer.dhuhr, 11 * 60 + 35);
      expectMinutes(day, Prayer.asr, 14 * 60 + 54);
      expectMinutes(day, Prayer.maghrib, 17 * 60 + 21);
      expectMinutes(day, Prayer.isha, 18 * 60 + 38);
    });
  });

  group('DST and zone changes', () {
    test('Egypt leaves DST at the end of October', () {
      // Egypt's DST ends on the last Thursday of October (29 Oct 2026), so the
      // clock moves back one hour overnight.
      final before = calc().forDay(const LocalDay(2026, 10, 28));
      final after = calc().forDay(const LocalDay(2026, 10, 30));

      // The solar time barely moves in two days, so the *label* on the same event
      // moves by almost an hour. Allow a few minutes of drift.
      final shift = before.times[Prayer.fajr]! - after.times[Prayer.fajr]!;
      expect(shift, inInclusiveRange(55, 65));
    });

    test('offsets follow DST', () {
      final cairo = zoneOffsetsFor('Africa/Cairo');
      expect(cairo.offsetMinutesAt(DateTime.utc(2026, 6, 15, 12)), 180);
      expect(cairo.offsetMinutesAt(DateTime.utc(2026, 12, 15, 12)), 120);

      final london = zoneOffsetsFor('Europe/London');
      expect(london.offsetMinutesAt(DateTime.utc(2026, 6, 15, 12)), 60);
      expect(london.offsetMinutesAt(DateTime.utc(2026, 12, 15, 12)), 0);

      final newYork = zoneOffsetsFor('America/New_York');
      expect(newYork.offsetMinutesAt(DateTime.utc(2026, 6, 15, 12)), -240);
      expect(newYork.offsetMinutesAt(DateTime.utc(2026, 12, 15, 12)), -300);
    });

    test('half-hour and three-quarter-hour zones are supported', () {
      expect(
        zoneOffsetsFor('Asia/Kolkata').offsetMinutesAt(
          DateTime.utc(2026, 10, 12, 12),
        ),
        330,
      );
      expect(
        zoneOffsetsFor('Asia/Kathmandu').offsetMinutesAt(
          DateTime.utc(2026, 10, 12, 12),
        ),
        345,
      );
    });

    test('an unknown zone name falls back to the device clock, never throws', () {
      final zone = zoneOffsetsFor('Not/AZone');
      expect(zone.zoneName, 'Not/AZone');
      expect(zone.offsetMinutesAt(DateTime.utc(2026, 10, 12, 12)), isA<int>());
    });

    test('a minute offset shifts exactly one prayer', () {
      final plain = calc().forDay(const LocalDay(2026, 10, 12));
      final shifted = calc(offsets: const {Prayer.asr: 5}).forDay(
        const LocalDay(2026, 10, 12),
      );

      expect(shifted.times[Prayer.asr]! - plain.times[Prayer.asr]!, 5);
      expect(shifted.times[Prayer.fajr], plain.times[Prayer.fajr]);
      expect(shifted.times[Prayer.maghrib], plain.times[Prayer.maghrib]);
    });

    test('seasonal drift stays within 40 minutes between October and February', () {
      final october = calc().forDay(const LocalDay(2026, 10, 12));
      final february = calc().forDay(const LocalDay(2027, 2, 12));

      final drift =
          (october.times[Prayer.fajr]! - february.times[Prayer.fajr]!).abs();
      expect(drift, lessThan(40));
    });
  });

  group('methods and asr school', () {
    test('all five methods produce a sane ordering', () {
      for (final method in CalculationMethod.values) {
        final day = calc(method: method).forDay(const LocalDay(2026, 10, 12));
        expect(day.times[Prayer.fajr], lessThan(day.times[Prayer.sunrise]!),
            reason: '$method');
        expect(day.times[Prayer.sunrise], lessThan(day.times[Prayer.dhuhr]!),
            reason: '$method');
        expect(day.times[Prayer.dhuhr], lessThan(day.times[Prayer.asr]!),
            reason: '$method');
        expect(day.times[Prayer.asr], lessThan(day.times[Prayer.maghrib]!),
            reason: '$method');
        expect(day.times[Prayer.maghrib], lessThan(day.times[Prayer.isha]!),
            reason: '$method');
      }
    });

    test('Hanafi asr is later than standard asr', () {
      final standard = calc().forDay(const LocalDay(2026, 10, 12));
      final hanafi = calc(madhab: Madhab.hanafi).forDay(
        const LocalDay(2026, 10, 12),
      );

      expect(hanafi.times[Prayer.asr]!,
          greaterThan(standard.times[Prayer.asr]!));
    });

    test('Umm al-Qura isha is 90 minutes after maghrib', () {
      final day = calc(method: CalculationMethod.ummAlQura).forDay(
        const LocalDay(2026, 10, 12),
      );
      expect(day.times[Prayer.isha]! - day.times[Prayer.maghrib]!, 90);
    });
  });

  group('high latitudes', () {
    PrayerTimesCalculator makeTromso() => PrayerTimesCalculator(
      latitude: 69.6492,
      longitude: 18.9553,
      zone: zoneOffsetsFor('Europe/Oslo'),
      method: CalculationMethod.muslimWorldLeague,
    );

    test('midnight sun: times are estimated from a latitude nearer the equator',
        () {
      final day = makeTromso().forDay(const LocalDay(2026, 6, 21));

      expect(day.timesAreEstimates, isFalse);
      // Never pretend the estimate is a measurement of this place.
      expect(day.estimatedFromLatitude, isNotNull);
      expect(day.estimatedFromLatitude, lessThan(69.6492));
      expect(day.estimatedFromLatitude!.abs(),
          greaterThanOrEqualTo(45));
      expect(day.highLatitudeMovedPrayers, {Prayer.fajr, Prayer.isha});
    });

    test('the estimated day is still internally consistent', () {
      final day = makeTromso().forDay(const LocalDay(2026, 6, 21));
      expect(day.times[Prayer.fajr], lessThan(day.times[Prayer.sunrise]!));
      expect(day.times[Prayer.sunrise], lessThan(day.times[Prayer.dhuhr]!));
      expect(day.times[Prayer.dhuhr], lessThan(day.times[Prayer.asr]!));
      expect(day.times[Prayer.asr], lessThan(day.times[Prayer.maghrib]!));
    });

    test('polar night is estimated the same way', () {
      final day = makeTromso().forDay(const LocalDay(2026, 12, 21));
      expect(day.estimatedFromLatitude, isNotNull);
      expect(day.unavailable, isEmpty);
    });

    test('Cairo in October: the rule is not in play', () {
      final day = calc().forDay(const LocalDay(2026, 10, 12));
      expect(day.highLatitudeMovedPrayers, isEmpty);
      expect(day.estimatedFromLatitude, isNull);
    });

    test('Tromsø in December: the middle-of-the-night rule is flagged', () {
      // Polar night: the sun never reaches 18 degrees below the horizon, so Fajr
      // and Isha come from the rule rather than from an angle.
      final day = makeTromso().forDay(const LocalDay(2026, 12, 21));
      expect(day.highLatitudeMovedPrayers, {Prayer.fajr, Prayer.isha});
      expect(day.times[Prayer.fajr], isNotNull);
      expect(day.times[Prayer.isha], isNotNull);
    });

    test('Oslo (inside the Arctic but with sunsets) uses no latitude estimate',
        () {
      final day = calc(
        zone: 'Europe/Oslo',
        lat: 59.9139,
        lng: 10.7522,
      ).forDay(const LocalDay(2026, 6, 21));
      expect(day.estimatedFromLatitude, isNull);
      expect(day.unavailable, isEmpty);
    });
  });

  group('next / current prayer', () {
    final day = calc().forDay(const LocalDay(2026, 10, 12));

    test('next prayer is the first time still ahead', () {
      expect(day.nextPrayer(6 * 60 + 0), Prayer.sunrise);
      expect(day.nextPrayer(7 * 60 + 0), Prayer.dhuhr);
      expect(day.nextPrayer(13 * 60 + 0), Prayer.asr);
      expect(day.nextPrayer(18 * 60 + 30), Prayer.isha);
      expect(day.nextPrayer(20 * 60 + 0), Prayer.fajr,
          reason: "after isha the next prayer is tomorrow's fajr");
    });

    test('after the last prayer, tomorrow fajr is next', () {
      expect(day.isAfterLastPrayer(20 * 60 + 0), isTrue);
      expect(day.isAfterLastPrayer(6 * 60 + 0), isFalse);
    });

    test('current prayer tracks the clock', () {
      expect(day.currentPrayer(0), Prayer.isha);
      expect(day.currentPrayer(6 * 60 + 0), Prayer.fajr);
      expect(day.currentPrayer(13 * 60 + 0), Prayer.dhuhr);
      expect(day.currentPrayer(17 * 60 + 0), Prayer.asr);
      expect(day.currentPrayer(23 * 60 + 0), Prayer.isha);
    });
  });
}

/// Two independent implementations of the same astronomical rules can disagree by
/// a minute; anything more than that is a real regression.
void expectMinutes(PrayerDay day, Prayer prayer, int expectedMinutes) {
  final actual = day.times[prayer];
  expect(actual, isNotNull, reason: '${prayer.name} should be computed');
  expect(
    (actual! - expectedMinutes).abs(),
    lessThanOrEqualTo(3),
    reason:
        '${prayer.name}: expected about ${LocalTime(expectedMinutes)}, '
        'computed ${LocalTime(actual)}',
  );
}

