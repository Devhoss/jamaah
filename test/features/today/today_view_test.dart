import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/prayer_times_calculator.dart';
import 'package:jamaah/src/domain/prayer_times_parameters.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/today.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/today/today_view.dart';

void main() {
  const times = {
    Prayer.fajr: 261,
    Prayer.sunrise: 342,
    Prayer.dhuhr: 689,
    Prayer.asr: 889,
    Prayer.maghrib: 1035,
    Prayer.isha: 1111,
  };
  NextPrayer next(Prayer p, {bool tomorrow = false}) => NextPrayer(
    prayer: p,
    on: const LocalDay(2026, 10, 15),
    at: LocalTime(times[p]!),
    minutesUntil: 10,
    isTomorrow: tomorrow,
  );

  group('at rest', () {
    test('the hero is the next Adhan', () {
      expect(
        TodayView.atRest.select(times: times, next: next(Prayer.asr)),
        const TodaySelection(Prayer.asr, HeroKicker.nextPrayer),
      );
    });

    test('after Isha it is tomorrow\'s Fajr', () {
      expect(
        TodayView.atRest.select(
          times: times,
          next: next(Prayer.fajr, tomorrow: true),
        ),
        const TodaySelection(Prayer.fajr, HeroKicker.nextPrayerTomorrow),
      );
    });

    test('a held prayer wins over the next Adhan', () {
      expect(
        TodayView.atRest.select(
          times: times,
          next: next(Prayer.maghrib),
          held: Prayer.asr,
        ),
        const TodaySelection(Prayer.asr, HeroKicker.heldForIqama),
      );
    });

    test('no times, no selection', () {
      expect(TodayView.atRest.select(times: const {}), isNull);
    });
  });

  group('moved', () {
    test('a drag selects whatever is in force at that minute', () {
      final v = TodayView.atRest.scrubTo(900);
      expect(v.moved, isTrue);
      expect(
        v.select(times: times, next: next(Prayer.maghrib)),
        const TodaySelection(Prayer.asr, HeroKicker.inForceAt),
      );
    });

    test('mid-morning is Sunrise, introduced as not a prayer', () {
      expect(
        TodayView.atRest.scrubTo(500).select(times: times),
        const TodaySelection(Prayer.sunrise, HeroKicker.sunrise),
      );
    });

    test('before Fajr it is still last night\'s Isha', () {
      expect(
        TodayView.atRest.scrubTo(120).select(times: times),
        const TodaySelection(Prayer.isha, HeroKicker.inForceAt),
      );
    });

    test('a row tap pins its prayer even after the drag moves on', () {
      final v = TodayView.atRest.pinTo(Prayer.dhuhr, 689);
      expect(v.minuteShown(100), 689);
      expect(
        v.select(times: times),
        const TodaySelection(Prayer.dhuhr, HeroKicker.adhan),
      );
      expect(v.scrubTo(1000).pinned, isNull);
    });

    test('the viewed minute wraps around the day', () {
      expect(TodayView.atRest.scrubTo(1500).viewMinute, 60);
      expect(TodayView.atRest.scrubTo(-30).viewMinute, 1410);
    });
  });

  group('hold until the Iqama', () {
    late PrayerTimesCalculator calc;
    setUpAll(() {
      loadTimeZoneDatabase();
      calc = PrayerTimesCalculator(
        latitude: 29.3759,
        longitude: 47.9774,
        zone: zoneOffsetsFor('Asia/Kuwait'),
        method: CalculationMethod.kuwait,
      );
    });

    TodayReading readAt(int hour, int minute) => readToday(
      calculator: calc,
      moment: LocalMoment.inZone(
        zone: zoneOffsetsFor('Asia/Kuwait'),
        // Kuwait is UTC+3 all year.
        utcInstant: DateTime.utc(2026, 10, 15, hour - 3, minute),
      ),
    );

    Mosque mosque({int asrAfter = 20}) => Mosque(
      id: 'm',
      name: 'Test',
      address: '',
      source: MosqueSource.manual,
      schedules: [
        Schedule.empty(mosqueId: 'm').copyWith(
          prayers: {
            for (final p in Prayer.iqamaPrayers)
              p: p == Prayer.asr
                  ? PrayerIqama(prayer: p, afterAdhanMinutes: asrAfter)
                  : PrayerIqama(prayer: p),
          },
        ),
      ],
    );

    test('holds Asr between its Adhan and its Iqama', () {
      final today = readAt(15, 0);
      final asr = today.day.timeOf(Prayer.asr)!;
      final reading = readAt(asr ~/ 60, asr % 60 + 5);
      final iqama = readNextIqama(mosque: mosque(), today: reading);
      expect(
        TodayView.heldPrayer(
          today: reading,
          iqama: iqama,
          awayFromMosque: false,
        ),
        Prayer.asr,
      );
    });

    test('lets go once the Iqama has passed', () {
      final asr = readAt(15, 0).day.timeOf(Prayer.asr)!;
      final reading = readAt(asr ~/ 60, asr % 60 + 25);
      final iqama = readNextIqama(mosque: mosque(), today: reading);
      expect(
        TodayView.heldPrayer(
          today: reading,
          iqama: iqama,
          awayFromMosque: false,
        ),
        isNull,
      );
    });

    test('no hold while away from the mosque, or with no Iqama', () {
      final asr = readAt(15, 0).day.timeOf(Prayer.asr)!;
      final reading = readAt(asr ~/ 60, asr % 60 + 5);
      expect(
        TodayView.heldPrayer(
          today: reading,
          iqama: readNextIqama(mosque: mosque(), today: reading),
          awayFromMosque: true,
        ),
        isNull,
      );
      expect(
        TodayView.heldPrayer(
          today: reading,
          iqama: const IqamaNotConfigured(),
          awayFromMosque: false,
        ),
        isNull,
      );
    });
  });

  group('glide', () {
    test('goes the short way round and lands exactly', () {
      final g = SkyGlide(from: 1400, to: 20);
      expect(g.delta, 60);
      expect(g.at(0), 1400);
      expect(g.at(1), 20);
      expect(g.at(0.5), 1430);
      expect(g.duration.inMilliseconds, 434);
    });
  });
}
