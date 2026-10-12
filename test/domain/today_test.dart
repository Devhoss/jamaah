import 'package:flutter_test/flutter_test.dart';

import 'package:awqaity/src/domain/mosque.dart';
import 'package:awqaity/src/domain/prayer.dart';
import 'package:awqaity/src/domain/prayer_times_calculator.dart';
import 'package:awqaity/src/domain/time_model.dart';
import 'package:awqaity/src/domain/today.dart';
import 'package:awqaity/src/domain/zone_offsets.dart';

/// The riskiest part of the app, tested with a clock we hand in rather than one
/// the device supplies (AGENTS.md quality bar).
///
/// "Today" is the day in the **saved place's** zone. Every expectation here is a
/// relationship between the day's own times and the moment, so these tests say
/// nothing about whether the astronomical times themselves are right —
/// prayer_times_test.dart pins those against the Aladhan oracle.
void main() {
  setUpAll(loadTimeZoneDatabase);

  LocalMoment momentAt(String zone, DateTime utc) =>
      LocalMoment.inZone(zone: zoneOffsetsFor(zone), utcInstant: utc);

  final cairo = PrayerTimesCalculator(
    latitude: 30.0444,
    longitude: 31.2357,
    zone: zoneOffsetsFor('Africa/Cairo'),
  );
  final cairoToday = cairo.forDay(const LocalDay(2026, 10, 12));

  /// Cairo at [minutesOfDay] on 2026-10-12, read through the place's own clock.
  TodayReading atCairo(int minutesOfDay) {
    final zone = zoneOffsetsFor('Africa/Cairo');
    return readToday(
      calculator: cairo,
      moment: LocalMoment.inZone(
        zone: zone,
        utcInstant: zone.utcInstantOf(
          day: const LocalDay(2026, 10, 12),
          time: LocalTime(minutesOfDay),
        ),
      ),
    );
  }

  group("the day belongs to the place, not to the device", () {
    test('a place ahead of the device is already on the next day', () {
      // 15:05 UTC on Monday 12 October 2026.
      final utc = DateTime.utc(2026, 10, 12, 15, 5);

      final tokyo = momentAt('Asia/Tokyo', utc);
      final berlin = momentAt('Europe/Berlin', utc);

      expect(tokyo.day, const LocalDay(2026, 10, 13));
      expect(berlin.day, const LocalDay(2026, 10, 12));
      expect(tokyo.minutesOfDay, 0 * 60 + 5, reason: '00:05 the next morning');
      expect(berlin.minutesOfDay, 17 * 60 + 5);
    });

    test('a place behind the device is still on the previous day', () {
      // 01:30 UTC on Tuesday 13 October 2026.
      final utc = DateTime.utc(2026, 10, 13, 1, 30);

      expect(momentAt('America/New_York', utc).day, const LocalDay(2026, 10, 12));
      expect(momentAt('America/New_York', utc).minutesOfDay, 21 * 60 + 30);
    });

    test('the same instant keeps its UTC identity on the moment', () {
      final utc = DateTime.utc(2026, 10, 12, 15, 5);
      expect(momentAt('Asia/Tokyo', utc).utcInstant, utc);
    });
  });

  group('wall clock and instant round-trip', () {
    test('a local time converts back to the instant it came from', () {
      for (final zone in const [
        'Africa/Cairo',
        'Europe/London',
        'America/New_York',
        'Asia/Karachi',
        'Asia/Kathmandu',
        'Australia/Lord_Howe',
      ]) {
        final offsets = zoneOffsetsFor(zone);
        for (final utc in [
          DateTime.utc(2026, 3, 28, 23, 15),
          DateTime.utc(2026, 3, 29, 1, 40),
          DateTime.utc(2026, 3, 29, 3, 5),
          DateTime.utc(2026, 10, 24, 23, 30),
          DateTime.utc(2026, 10, 25, 1, 0),
          DateTime.utc(2026, 10, 25, 1, 30),
          DateTime.utc(2026, 6, 21, 12, 0),
        ]) {
          final moment = LocalMoment.inZone(zone: offsets, utcInstant: utc);
          final back = offsets.utcInstantOf(
            day: moment.day,
            time: LocalTime(moment.minutesOfDay),
          );
          expect(
            back.difference(utc).inMinutes.abs(),
            lessThanOrEqualTo(1),
            reason: '$zone at $utc: wall clock ${moment.minutesOfDay} '
                'did not return to the instant',
          );
        }
      }
    });
  });

  group('what is in force and what comes next', () {
    test('mid-day: the prayer in force is the one that has started', () {
      final dhuhr = cairoToday.timeOf(Prayer.dhuhr)!;
      final asr = cairoToday.timeOf(Prayer.asr)!;
      final reading = atCairo(dhuhr + 5);

      expect(reading.inForce?.prayer, Prayer.dhuhr);
      expect(reading.inForce?.startedOn, const LocalDay(2026, 10, 12));
      expect(reading.next?.prayer, Prayer.asr);
      expect(reading.next?.minutesUntil, asr - dhuhr - 5);
      expect(reading.next?.isTomorrow, isFalse);
    });

    test('sunrise is a time on the list, never the next prayer', () {
      final fajr = cairoToday.timeOf(Prayer.fajr)!;
      final dhuhr = cairoToday.timeOf(Prayer.dhuhr)!;
      final reading = atCairo(fajr + 1);

      expect(reading.next?.prayer, Prayer.dhuhr);
      expect(reading.next?.minutesUntil, dhuhr - fajr - 1);
    });

    test('Fajr is in force right up to sunrise', () {
      final sunrise = cairoToday.timeOf(Prayer.sunrise)!;
      final reading = atCairo(sunrise - 1);

      expect(reading.inForce?.prayer, Prayer.fajr);
    });

    test('between sunrise and Dhuhr no prayer is in force', () {
      final sunrise = cairoToday.timeOf(Prayer.sunrise)!;
      final dhuhr = cairoToday.timeOf(Prayer.dhuhr)!;
      final reading = atCairo(sunrise + 1);

      expect(
        reading.inForce,
        isNull,
        reason: "Fajr's window ends at sunrise, so the gap before Dhuhr belongs "
            'to no prayer and the screen must not highlight one',
      );
      expect(reading.next?.prayer, Prayer.dhuhr);
      expect(reading.next?.minutesUntil, dhuhr - sunrise - 1);
    });

    test('Dhuhr takes over the moment it arrives', () {
      final dhuhr = cairoToday.timeOf(Prayer.dhuhr)!;
      final reading = atCairo(dhuhr);

      expect(reading.inForce?.prayer, Prayer.dhuhr);
    });

    test('after Isha the next prayer is tomorrow Fajr', () {
      final isha = cairoToday.timeOf(Prayer.isha)!;
      final reading = atCairo(isha + 30);
      final tomorrow = cairo.forDay(const LocalDay(2026, 10, 13));
      final tomorrowFajr = tomorrow.timeOf(Prayer.fajr)!;

      expect(reading.next?.prayer, Prayer.fajr);
      expect(reading.next?.isTomorrow, isTrue);
      expect(reading.next?.on, const LocalDay(2026, 10, 13));
      expect(reading.next?.at, LocalTime(tomorrowFajr));
      expect(
        reading.next?.minutesUntil,
        1440 - (isha + 30) + tomorrowFajr,
        reason: 'the countdown crosses midnight into tomorrow Fajr',
      );
      expect(reading.inForce?.prayer, Prayer.isha);
      expect(reading.inForce?.startedOn, const LocalDay(2026, 10, 12));
    });

    test('between midnight and Fajr the prayer in force is yesterday Isha', () {
      final yesterday = cairo.forDay(const LocalDay(2026, 10, 11));
      final reading = atCairo(30);

      expect(reading.inForce?.prayer, Prayer.isha);
      expect(
        reading.inForce?.startedOn,
        const LocalDay(2026, 10, 11),
        reason: 'it is the Isha that was yesterday evening',
      );
      expect(reading.inForce?.at, LocalTime(yesterday.timeOf(Prayer.isha)!));
      expect(reading.next?.prayer, Prayer.fajr);
      expect(reading.next?.isTomorrow, isFalse);
      expect(reading.next?.on, const LocalDay(2026, 10, 12));
    });

    test('the day rolls over at local midnight, not at the device midnight', () {
      // 21:00 UTC on 12 October is 00:00 on 13 October in Tokyo.
      final tokyo = PrayerTimesCalculator(
        latitude: 35.68,
        longitude: 139.69,
        zone: zoneOffsetsFor('Asia/Tokyo'),
      );
      final reading = readToday(
        calculator: tokyo,
        moment: momentAt('Asia/Tokyo', DateTime.utc(2026, 10, 12, 21)),
      );

      expect(reading.day.day, const LocalDay(2026, 10, 13));
      expect(reading.next?.isTomorrow, isFalse);
      expect(reading.next?.on, const LocalDay(2026, 10, 13));
    });
  });

  group('a day whose clocks change', () {
    final london = PrayerTimesCalculator(
      latitude: 51.5074,
      longitude: -0.1278,
      zone: zoneOffsetsFor('Europe/London'),
    );

    test('the repeated hour costs an extra real hour, not nothing', () {
      // England goes back from BST to GMT at 02:00 local, i.e. 01:00 UTC on
      // 25 October 2026. Both instants read 01:30 on the wall clock.
      final beforeFallBack = readToday(
        calculator: london,
        moment: momentAt('Europe/London', DateTime.utc(2026, 10, 25, 0, 30)),
      );
      final afterFallBack = readToday(
        calculator: london,
        moment: momentAt('Europe/London', DateTime.utc(2026, 10, 25, 1, 30)),
      );

      expect(beforeFallBack.day.day, const LocalDay(2026, 10, 25));
      expect(afterFallBack.day.day, const LocalDay(2026, 10, 25));
      expect(beforeFallBack.next?.prayer, afterFallBack.next?.prayer);
      expect(
        beforeFallBack.next!.minutesUntil - afterFallBack.next!.minutesUntil,
        60,
        reason: 'the countdown is measured in real minutes, so the extra '
            'hour of daylight is counted rather than skipped',
      );
    });

    test('the spring gap does not invent a prayer time', () {
      // England goes forward at 01:00 UTC on 29 March 2026.
      final reading = readToday(
        calculator: london,
        moment: momentAt('Europe/London', DateTime.utc(2026, 3, 29, 2, 30)),
      );

      expect(reading.day.day, const LocalDay(2026, 3, 29));
      expect(reading.next, isNotNull);
      expect(reading.next!.minutesUntil, greaterThan(0));
      expect(reading.next!.minutesUntil, lessThan(24 * 60));
    });
  });

  group('a day the sun does not cooperate', () {
    // The calculator resolves a polar day by moving toward the equator (see
    // prayer_times_test.dart), so a day with no times at all only happens when even
    // that fails. The shape is fabricated below to pin readToday's contract.
    test('a day with no times has no countdown and no prayer in force', () {
      final reading = readToday(
        calculator: _NoTimesCalculator(),
        moment: momentAt('Arctic/Longyearbyen', DateTime.utc(2026, 12, 21, 12)),
      );

      expect(reading.areTimesAvailable, isFalse);
      expect(reading.next, isNull);
      expect(reading.inForce, isNull);
    });

    test('Longyearbyen in polar night is an estimate, and says so', () {
      final longebyen = PrayerTimesCalculator(
        latitude: 78.22,
        longitude: 15.65,
        zone: zoneOffsetsFor('Arctic/Longyearbyen'),
      );
      final reading = readToday(
        calculator: longebyen,
        moment: momentAt('Arctic/Longyearbyen', DateTime.utc(2026, 12, 21, 12)),
      );

      expect(reading.estimatedFromLatitude, isNotNull);
      expect(
        reading.estimatedFromLatitude!.abs(),
        lessThanOrEqualTo(78.22),
        reason: 'the UI has to be able to say the times are not this '
            'place\'s own astronomy',
      );
    });

    test('the high-latitude note only appears when the rule moved a time', () {
      final cairo = PrayerTimesCalculator(
        latitude: 30.0444,
        longitude: 31.2357,
        zone: zoneOffsetsFor('Africa/Cairo'),
      );
      final london = PrayerTimesCalculator(
        latitude: 51.5074,
        longitude: -0.1278,
        zone: zoneOffsetsFor('Europe/London'),
      );

      final cairoReading = readToday(
        calculator: cairo,
        moment: momentAt('Africa/Cairo', DateTime.utc(2026, 10, 12, 9)),
      );
      final londonReading = readToday(
        calculator: london,
        moment: momentAt('Europe/London', DateTime.utc(2026, 6, 21, 9)),
      );

      expect(cairoReading.prayersMovedByRule, isEmpty);
      expect(londonReading.prayersMovedByRule, isNotEmpty);
    });
  });

  group("the active mosque's Iqama on the card", () {
    Mosque mosque(
      Map<Prayer, LocalTime> times, {
      Set<Prayer> reminders = const {},
      LocalDay? effectiveFrom,
      int? before,
    }) {
      final schedule = Schedule.empty(mosqueId: 'm1').copyWith(
        effectiveFrom: effectiveFrom,
        prayers: {
          for (final prayer in Prayer.iqamaPrayers)
            prayer: PrayerIqama(
              prayer: prayer,
              iqama: times[prayer],
              reminderEnabled: reminders.contains(prayer),
              reminderMinutesBefore: before ?? 10,
            ),
        },
      );
      return Mosque(
        id: 'm1',
        name: 'Masjid al-Nour',
        address: '12 Garden Road',
        source: MosqueSource.manual,
        schedules: [schedule],
      );
    }

    test('the next prayer shows its Iqama and counts down to it', () {
      final dhuhrIqama = cairoToday.timeOf(Prayer.dhuhr)! + 12;
      final reading = atCairo(cairoToday.timeOf(Prayer.fajr)! + 60);
      final next = readNextIqama(
        mosque: mosque({Prayer.dhuhr: LocalTime(dhuhrIqama)}),
        today: reading,
      );

      expect(next?.prayer, Prayer.dhuhr);
      expect(next?.at, LocalTime(dhuhrIqama));
      expect(next?.on, const LocalDay(2026, 10, 12));
      expect(next?.minutesUntil, dhuhrIqama - (cairoToday.timeOf(Prayer.fajr)! + 60));
    });

    test('an unconfigured Iqama shows nothing, never a guessed time', () {
      final reading = atCairo(cairoToday.timeOf(Prayer.fajr)! + 60);
      final next = readNextIqama(mosque: mosque({}), today: reading);

      expect(next, isNull);
    });

    test('a prayer with no Iqama of its own does not borrow the next one', () {
      // Only Isha is configured; at mid-morning the prayer in front of the user is
      // Dhuhr, whose Iqama they have not entered.
      final reading = atCairo(cairoToday.timeOf(Prayer.fajr)! + 60);
      final next = readNextIqama(
        mosque: mosque({Prayer.isha: const LocalTime(20 * 60)}),
        today: reading,
      );

      expect(next, isNull);
    });

    test('reminder settings travel with it, as settings only', () {
      final reading = atCairo(cairoToday.timeOf(Prayer.fajr)! + 60);
      final next = readNextIqama(
        mosque: mosque(
          {Prayer.dhuhr: LocalTime(cairoToday.timeOf(Prayer.dhuhr)! + 12)},
          reminders: {Prayer.dhuhr},
          before: 20,
        ),
        today: reading,
      );

      expect(next?.reminderEnabled, isTrue);
      expect(next?.reminderMinutesBefore, 20);
    });

    test('after Isha the card uses tomorrow schedule and crosses midnight', () {
      final isha = cairoToday.timeOf(Prayer.isha)!;
      final reading = atCairo(isha + 30);
      final tomorrow = cairo.forDay(const LocalDay(2026, 10, 13));
      final tomorrowFajr = tomorrow.timeOf(Prayer.fajr)!;

      final next = readNextIqama(
        mosque: mosque({Prayer.fajr: LocalTime(tomorrowFajr + 15)}),
        today: reading,
      );

      expect(next?.prayer, Prayer.fajr);
      expect(next?.on, const LocalDay(2026, 10, 13));
      expect(next?.minutesUntil, 1440 - (isha + 30) + tomorrowFajr + 15);
    });

    test('a schedule that starts tomorrow is the one used for tomorrow', () {
      final reading = atCairo(cairoToday.timeOf(Prayer.isha)! + 30);
      final next = readNextIqama(
        mosque: mosque(
          {Prayer.fajr: const LocalTime(5 * 60)},
          effectiveFrom: const LocalDay(2026, 10, 13),
        ),
        today: reading,
      );

      expect(next?.at, const LocalTime(5 * 60));
    });

    test('an Iqama that has already passed is not the next one', () {
      // The user entered a Dhuhr Iqama earlier than the calculated Adhan, and now
      // sits between them: a countdown to it would read backwards.
      final dhuhr = cairoToday.timeOf(Prayer.dhuhr)!;
      final reading = atCairo(dhuhr + 5);
      final next = readNextIqama(
        mosque: mosque({Prayer.dhuhr: LocalTime(dhuhr - 10)}),
        today: reading,
      );

      expect(next, isNull);
    });

    test('no mosque means no Iqama on the card', () {
      final reading = atCairo(cairoToday.timeOf(Prayer.fajr)! + 60);
      expect(readNextIqama(mosque: null, today: reading), isNull);
    });

    test('a day with no times has no Iqama countdown either', () {
      final reading = readToday(
        calculator: _NoTimesCalculator(),
        moment: momentAt('Arctic/Longyearbyen', DateTime.utc(2026, 12, 21, 12)),
      );
      expect(
        readNextIqama(mosque: mosque({Prayer.fajr: const LocalTime(5 * 60)}), today: reading),
        isNull,
      );
    });
  });
}

/// A place whose day has no computable times at all — the case the calculator
/// reports when it cannot reach a consistent day. Built here because no real
/// latitude on a real date produces it: the fallback loop finds one.
class _NoTimesCalculator extends PrayerTimesCalculator {
  _NoTimesCalculator()
    : super(
        latitude: 85,
        longitude: 15.65,
        zone: zoneOffsetsFor('Arctic/Longyearbyen'),
      );

  @override
  PrayerDay forDay(LocalDay day) => PrayerDay(
    day: day,
    times: const {},
    unavailable: Prayer.values.toSet(),
  );
}
