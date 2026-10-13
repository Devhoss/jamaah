import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/hijri.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/prayer_times_calculator.dart';
import 'package:jamaah/src/domain/prayer_times_parameters.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

/// The Hijri date adjustment (2026-10-14): Kuwait and others start months by
/// moon sighting, so the user can move the Hijri date by up to two days.
void main() {
  setUpAll(loadTimeZoneDatabase);

  test('the adjustment moves the Hijri date by exactly that many days', () {
    final date = DateTime(2026, 10, 14);
    final base = hijriFor(date);
    for (final d in [-2, -1, 1, 2]) {
      final moved = hijriFor(date, adjustDays: d);
      final expected = hijriFor(date.add(Duration(days: d)));
      expect(
        (moved.hYear, moved.hMonth, moved.hDay),
        (expected.hYear, expected.hMonth, expected.hDay),
      );
    }
    expect(hijriFor(date, adjustDays: 0).hDay, base.hDay);
  });

  test('a stored adjustment never goes past two days', () {
    expect(clampHijriAdjust(5), 2);
    expect(clampHijriAdjust(-9), -2);
    expect(clampHijriAdjust(1), 1);
  });

  group('Ramadan follows the adjusted date', () {
    final riyadh = PrayerTimesCalculator(
      latitude: 24.7136,
      longitude: 46.6753,
      zone: zoneOffsetsFor('Asia/Riyadh'),
      method: CalculationMethod.ummAlQura,
    );
    int ishaAfterMaghrib(PrayerTimesCalculator c, LocalDay day) {
      final d = c.forDay(day);
      return d.timeOf(Prayer.isha)! - d.timeOf(Prayer.maghrib)!;
    }

    // The calculated first day of Ramadan 1448.
    late LocalDay first;
    setUpAll(() {
      var day = DateTime(2027, 1, 15);
      while (hijriFor(day).hMonth != 9) {
        day = day.add(const Duration(days: 1));
      }
      first = LocalDay(day.year, day.month, day.day);
    });

    test('a day later: the eve of the calculated Ramadan is still Shaban', () {
      final dayBefore = first.addDays(-1);
      expect(ishaAfterMaghrib(riyadh, dayBefore), 90);
      expect(ishaAfterMaghrib(riyadh, first), 120);

      final later = riyadh.copyWithHijri(-1);
      expect(
        ishaAfterMaghrib(later, first),
        90,
        reason: 'announced a day late: the calculated first day is Shaban 30',
      );
      final earlier = riyadh.copyWithHijri(1);
      expect(
        ishaAfterMaghrib(earlier, dayBefore),
        120,
        reason: 'announced a day early: Ramadan starts the day before',
      );
    });
  });

  test('the adjustment is stored and read back within range', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final settings = SettingsRepository(db);
    expect((await settings.read()).hijriAdjustDays, 0);
    await settings.setHijriAdjustDays(-1);
    expect((await settings.read()).hijriAdjustDays, -1);
    await db.customStatement(
      "UPDATE app_settings SET value = '7' "
      "WHERE key = '${SettingKeys.hijriAdjustDays}'",
    );
    expect((await settings.read()).hijriAdjustDays, 2);
  });
}

extension on PrayerTimesCalculator {
  PrayerTimesCalculator copyWithHijri(int days) => PrayerTimesCalculator(
    latitude: latitude,
    longitude: longitude,
    zone: zone,
    method: method,
    madhab: madhab,
    highLatitudeRule: highLatitudeRule,
    minuteOffsets: minuteOffsets,
    customAngles: customAngles,
    hijriAdjustDays: days,
  );
}
