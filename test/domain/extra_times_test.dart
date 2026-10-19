import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/extra_times.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/prayer_times_calculator.dart';
import 'package:jamaah/src/domain/prayer_times_parameters.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/today.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

/// A calculator whose days have no Fajr, as on a polar day.
class _NoFajr extends PrayerTimesCalculator {
  _NoFajr(PrayerTimesCalculator base)
    : super(
        latitude: base.latitude,
        longitude: base.longitude,
        zone: base.zone,
        method: base.method,
      );

  @override
  PrayerDay forDay(LocalDay day) {
    final real = super.forDay(day);
    return PrayerDay(
      day: day,
      times: {...real.times}..remove(Prayer.fajr),
      unavailable: {Prayer.fajr},
    );
  }
}

/// Imsak, Duha and the last third of the night (2026-10-14). Every
/// expectation is a relationship to the calculator's own times, measured
/// between instants; prayer_times_test.dart pins the times themselves.
void main() {
  setUpAll(loadTimeZoneDatabase);

  late PrayerTimesCalculator kuwait;
  setUp(() {
    kuwait = PrayerTimesCalculator(
      latitude: 29.3759,
      longitude: 47.9774,
      zone: zoneOffsetsFor('Asia/Kuwait'),
      method: CalculationMethod.kuwait,
    );
  });

  const day = LocalDay(2026, 10, 14);

  DateTime instant(PrayerTimesCalculator c, LocalDay d, Prayer p) =>
      c.zone.utcInstantOf(day: d, time: LocalTime(c.forDay(d).times[p]!));

  ExtraTimeAt only(List<ExtraTimeAt> all, ExtraTime t) =>
      all.singleWhere((e) => e.time == t);

  test('Imsak is N minutes before Fajr, Duha M after sunrise', () {
    final times = kuwait.forDay(day).times;
    final out = extraTimesFor(
      calculator: kuwait,
      day: day,
      settings: const ExtraTimesSettings(imsakMinutes: 10, duhaMinutes: 15),
    );
    expect(only(out, ExtraTime.imsak).at.minutes, times[Prayer.fajr]! - 10);
    expect(only(out, ExtraTime.imsak).day, day);
    expect(only(out, ExtraTime.duha).at.minutes, times[Prayer.sunrise]! + 15);
  });

  test('Qiyam starts the last third of Maghrib to the next Fajr', () {
    final maghrib = instant(kuwait, day, Prayer.maghrib);
    final fajr = instant(kuwait, day.addDays(1), Prayer.fajr);
    final expected = maghrib.add(fajr.difference(maghrib) * 2 ~/ 3);
    final q = only(
      extraTimesFor(
        calculator: kuwait,
        day: day,
        settings: const ExtraTimesSettings(),
      ),
      ExtraTime.qiyam,
    );
    expect(q.day, day.addDays(1), reason: 'after midnight in Kuwait');
    expect(q.utc.difference(expected).inSeconds.abs(), lessThan(60));
    expect(q.utc.second, 0, reason: 'whole minutes, like every other time');
  });

  test('a night with a clock change is measured at its real length', () {
    // London, 24 → 25 October 2026: the clocks go back an hour at 02:00.
    final london = PrayerTimesCalculator(
      latitude: 51.5072,
      longitude: -0.1276,
      zone: zoneOffsetsFor('Europe/London'),
    );
    const night = LocalDay(2026, 10, 24);
    final maghrib = instant(london, night, Prayer.maghrib);
    final fajr = instant(london, night.addDays(1), Prayer.fajr);
    final expected = maghrib.add(fajr.difference(maghrib) * 2 ~/ 3);
    final q = only(
      extraTimesFor(
        calculator: london,
        day: night,
        settings: const ExtraTimesSettings(),
      ),
      ExtraTime.qiyam,
    );
    expect(q.utc.difference(expected).inSeconds.abs(), lessThan(60));

    // Counting wall-clock minutes instead would land 20 minutes off.
    final times = london.forDay(night).times;
    final wallNight =
        london.forDay(night.addDays(1)).times[Prayer.fajr]! +
        1440 -
        times[Prayer.maghrib]!;
    final wallQiyam = (times[Prayer.maghrib]! + wallNight * 2 ~/ 3) % 1440;
    expect(q.at.minutes, isNot(wallQiyam));
  });

  test('no Fajr: no Imsak, and no Qiyam the evening before', () {
    final out = extraTimesFor(
      calculator: _NoFajr(kuwait),
      day: day,
      settings: const ExtraTimesSettings(),
    );
    expect(out.map((e) => e.time), [ExtraTime.duha]);
  });

  LocalMoment kuwaitAt(LocalDay d, int minutes) => LocalMoment.inZone(
    zone: kuwait.zone,
    utcInstant: kuwait.zone.utcInstantOf(day: d, time: LocalTime(minutes)),
  );

  const all = ExtraTimesSettings(shown: {...ExtraTime.values});

  test('before Fajr, Today shows the night in progress', () {
    final shown = extraTimesForToday(
      calculator: kuwait,
      moment: kuwaitAt(day.addDays(1), 2 * 60),
      settings: all,
    );
    final lastNight = only(
      extraTimesFor(calculator: kuwait, day: day, settings: all),
      ExtraTime.qiyam,
    );
    expect(only(shown, ExtraTime.qiyam).utc, lastNight.utc);
  });

  test('after Fajr, Today shows tonight', () {
    final shown = extraTimesForToday(
      calculator: kuwait,
      moment: kuwaitAt(day, 12 * 60),
      settings: all,
    );
    final tonight = only(
      extraTimesFor(calculator: kuwait, day: day, settings: all),
      ExtraTime.qiyam,
    );
    expect(only(shown, ExtraTime.qiyam).utc, tonight.utc);
  });

  test('Today lists only the shown times, in time order', () {
    final shown = extraTimesForToday(
      calculator: kuwait,
      moment: kuwaitAt(day, 12 * 60),
      settings: const ExtraTimesSettings(
        shown: {ExtraTime.qiyam, ExtraTime.imsak},
      ),
    );
    expect(shown.map((e) => e.time), [ExtraTime.imsak, ExtraTime.qiyam]);
  });

  test('the minutes are kept in range', () {
    expect(clampImsakMinutes(-3), 0);
    expect(clampImsakMinutes(99), 20);
    expect(clampDuhaMinutes(1), 10);
    expect(clampDuhaMinutes(99), 30);
  });

  test('defaults: Imsak hidden, Duha 15, no alerts', () {
    const d = ExtraTimesSettings();
    expect(d.imsakMinutes, 10);
    expect(d.duhaMinutes, 15);
    expect(d.shown, isEmpty);
    expect(d.alerts, isEmpty);
  });
}
