import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/prayer_times_calculator.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/today.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

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

    /// The card's answer at [minutesOfDay] on Cairo's 12 October, for [times].
    NextIqama at(
      int minutesOfDay,
      Map<Prayer, LocalTime> times, {
      Set<Prayer> reminders = const {},
      int? before,
      LocalDay? effectiveFrom,
    }) => readNextIqama(
      mosque: mosque(
        times,
        reminders: reminders,
        before: before,
        effectiveFrom: effectiveFrom,
      ),
      today: atCairo(minutesOfDay),
    );

    /// The one answer that carries a time, or the test fails on what it got.
    IqamaUpcoming upcoming(NextIqama result) => result is IqamaUpcoming
        ? result
        : (fail('expected an upcoming Iqama, got $result'));

    test('before the first Iqama of the day, that one is the next', () {
      final fajr = cairoToday.timeOf(Prayer.fajr)!;
      final next = upcoming(
        at(fajr + 5, {
          Prayer.fajr: LocalTime(fajr + 12),
          Prayer.dhuhr: LocalTime(cairoToday.timeOf(Prayer.dhuhr)!),
        }),
      );

      expect(next.prayer, Prayer.fajr);
      expect(next.at, LocalTime(fajr + 12));
      expect(next.on, const LocalDay(2026, 10, 12));
      expect(next.isTomorrow, isFalse);
      expect(next.minutesUntil, 12 - 5);
      expect(next.mosqueName, 'Masjid al-Nour');
    });

    test('between two Iqamas, the earliest one still ahead wins', () {
      final fajr = cairoToday.timeOf(Prayer.fajr)!;
      final dhuhr = cairoToday.timeOf(Prayer.dhuhr)!;
      final asr = cairoToday.timeOf(Prayer.asr)!;

      // An hour after Fajr's Iqama, with three entered: the answer is the sooner
      // of the two that remain, not the prayer the Adhan countdown is on.
      final next = upcoming(
        at(fajr + 60, {
          Prayer.fajr: LocalTime(fajr + 12),
          Prayer.dhuhr: LocalTime(dhuhr + 20),
          Prayer.asr: LocalTime(asr + 5),
        }),
      );

      expect(next.prayer, Prayer.dhuhr);
      expect(next.at, LocalTime(dhuhr + 20));
      expect(next.minutesUntil, dhuhr + 20 - (fajr + 60));
    });

    test('a prayer whose Adhan has passed can still have its Iqama ahead', () {
      final maghrib = cairoToday.timeOf(Prayer.maghrib)!;
      final isha = cairoToday.timeOf(Prayer.isha)!;
      final now = maghrib + 2;

      expect(
        atCairo(now).next?.prayer,
        Prayer.isha,
        reason: 'the Adhan in front of the user is Isha',
      );

      // Maghrib's jama'ah is still ten minutes away, so it is the next Iqama even
      // though its own Adhan is behind the clock (the prototype counts it this way).
      final next = upcoming(
        at(now, {
          Prayer.maghrib: LocalTime(now + 10),
          Prayer.isha: LocalTime(isha + 25),
        }),
      );

      expect(next.prayer, Prayer.maghrib);
      expect(next.minutesUntil, 10);
    });

    test('an entered Iqama belongs to its own prayer, never to another', () {
      // Only Isha is entered; mid-morning therefore has exactly one Iqama left.
      final next = upcoming(
        at(cairoToday.timeOf(Prayer.fajr)! + 60, {
          Prayer.isha: const LocalTime(20 * 60),
        }),
      );

      expect(next.prayer, Prayer.isha);
      expect(next.at, const LocalTime(20 * 60));
      expect(next.isTomorrow, isFalse);
    });

    test('reminder settings travel with it, as settings only', () {
      final next = upcoming(
        at(
          cairoToday.timeOf(Prayer.fajr)! + 60,
          {Prayer.dhuhr: LocalTime(cairoToday.timeOf(Prayer.dhuhr)! + 12)},
          reminders: {Prayer.dhuhr},
          before: 20,
        ),
      );

      expect(next.reminderEnabled, isTrue);
      expect(next.reminderMinutesBefore, 20);
    });

    test('after the last Iqama today, tomorrow\'s Fajr is labelled tomorrow', () {
      final isha = cairoToday.timeOf(Prayer.isha)!;
      final next = upcoming(
        at(isha + 30, {
          Prayer.isha: LocalTime(isha + 12),
          Prayer.fajr: const LocalTime(5 * 60 + 40),
        }),
      );

      expect(next.prayer, Prayer.fajr);
      expect(next.on, const LocalDay(2026, 10, 13));
      expect(next.isTomorrow, isTrue);
      expect(next.at, const LocalTime(5 * 60 + 40));
      expect(next.minutesUntil, 1440 - (isha + 30) + 5 * 60 + 40);
    });

    test('after the last Iqama today with no Fajr entered, none are left', () {
      final isha = cairoToday.timeOf(Prayer.isha)!;
      expect(
        at(isha + 30, {
          Prayer.isha: LocalTime(isha + 12),
          Prayer.maghrib: LocalTime(cairoToday.timeOf(Prayer.maghrib)! + 8),
        }),
        isA<IqamaNoneLeftToday>(),
      );
    });

    test('an Iqama already reached is not offered as the next one', () {
      // The user entered a Dhuhr Iqama earlier than the calculated Adhan, and now
      // sits between them: a countdown to it would read backwards.
      final dhuhr = cairoToday.timeOf(Prayer.dhuhr)!;
      expect(
        at(dhuhr + 5, {Prayer.dhuhr: LocalTime(dhuhr - 10)}),
        isA<IqamaNoneLeftToday>(),
      );
    });

    test('a mosque with nothing entered is not the same as a finished day', () {
      final reading = atCairo(cairoToday.timeOf(Prayer.fajr)! + 60);

      expect(at(cairoToday.timeOf(Prayer.fajr)! + 60, {}), isA<IqamaNotConfigured>());
      expect(
        readNextIqama(mosque: null, today: reading),
        isA<IqamaNotConfigured>(),
        reason: 'no active mosque is the same honest answer as no entered times',
      );
    });

    test('a schedule that starts tomorrow is the one used for tomorrow', () {
      final next = upcoming(
        at(
          cairoToday.timeOf(Prayer.isha)! + 30,
          {Prayer.fajr: const LocalTime(5 * 60)},
          effectiveFrom: const LocalDay(2026, 10, 13),
        ),
      );

      expect(next.at, const LocalTime(5 * 60));
      expect(next.isTomorrow, isTrue);
    });

    test('the Iqama reading comes from the mosque, not from the day\'s times', () {
      // A polar day with no computable Adhan times: the mosque's own entered times
      // are still the user's data, and the screen has its own notice for the day.
      final reading = readToday(
        calculator: _NoTimesCalculator(),
        moment: momentAt('Arctic/Longyearbyen', DateTime.utc(2026, 12, 21, 12)),
      );
      final next = upcoming(
        readNextIqama(
          mosque: mosque({Prayer.isha: const LocalTime(20 * 60)}),
          today: reading,
        ),
      );

      expect(next.prayer, Prayer.isha);
      expect(
        next.minutesUntil,
        20 * 60 - reading.moment.minutesOfDay,
        reason: 'counted on the place\'s own clock, which is 15:00 here',
      );
    });

    test('a day that changes its clocks costs the hour it really costs', () {
      // Europe/London on Saturday 24 October 2026, 22:30 on its own wall clock:
      // every Iqama of the day is behind it, so the card hands over to tomorrow's
      // Fajr — and tomorrow is the Sunday the clocks go back an hour.
      final london = zoneOffsetsFor('Europe/London');
      final reading = TodayReading(
        day: const PrayerDay(day: LocalDay(2026, 10, 24), times: {}),
        moment: LocalMoment.inZone(
          zone: london,
          utcInstant: london.utcInstantOf(
            day: const LocalDay(2026, 10, 24),
            time: const LocalTime(22 * 60 + 30),
          ),
        ),
      );

      final next = upcoming(
        readNextIqama(
          mosque: mosque({
            Prayer.fajr: const LocalTime(5 * 60 + 40),
            Prayer.isha: const LocalTime(20 * 60),
          }),
          today: reading,
        ),
      );

      expect(next.prayer, Prayer.fajr);
      expect(next.isTomorrow, isTrue);
      expect(
        next.minutesUntil,
        8 * 60 + 10,
        reason: '22:30 BST to 05:40 GMT is eight hours and ten minutes, though '
            'the two wall clocks alone would say seven and ten',
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
