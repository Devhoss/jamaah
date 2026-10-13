import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/prayer_times_calculator.dart';
import 'package:jamaah/src/domain/prayer_times_parameters.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

/// The calculation methods (expanded 2026-10-13): what each one is, how "Auto
/// detect" picks one, Umm al-Qura's Ramadan Isha, and the user's own angles.
void main() {
  setUpAll(loadTimeZoneDatabase);

  group('the angles each method is published with', () {
    // Published values; the Settings list reads them from the same parameters
    // the calculator uses, so this also pins what the user is shown.
    final published = {
      CalculationMethod.egyptian: (19.5, 17.5, null),
      CalculationMethod.isna: (15.0, 15.0, null),
      CalculationMethod.moonsightingCommittee: (18.0, 18.0, null),
      CalculationMethod.muslimWorldLeague: (18.0, 17.0, null),
      CalculationMethod.ummAlQura: (18.5, null, 90),
      CalculationMethod.karachi: (18.0, 18.0, null),
      CalculationMethod.jakim: (20.0, 18.0, null),
      CalculationMethod.singapore: (20.0, 18.0, null),
      CalculationMethod.indonesia: (20.0, 18.0, null),
      CalculationMethod.turkiye: (18.0, 17.0, null),
      CalculationMethod.france: (12.0, 12.0, null),
      CalculationMethod.kuwait: (18.0, 17.5, null),
      CalculationMethod.qatar: (18.0, null, 90),
      CalculationMethod.dubai: (18.2, 18.2, null),
      CalculationMethod.gulfRegion: (19.5, null, 90),
    };
    for (final MapEntry(key: method, value: (fajr, isha, minutes))
        in published.entries) {
      test(method.name, () {
        final a = methodAngles(method);
        expect(a.fajrAngle, fajr);
        expect(a.ishaAngle, isha);
        expect(a.ishaMinutes, minutes);
      });
    }
  });

  group('auto detect', () {
    test('picks the method used where the place is', () {
      expect(autoMethodFor('Africa/Cairo'), CalculationMethod.egyptian);
      expect(autoMethodFor('Asia/Riyadh'), CalculationMethod.ummAlQura);
      expect(autoMethodFor('America/New_York'), CalculationMethod.isna);
      expect(
        autoMethodFor('America/Indiana/Indianapolis'),
        CalculationMethod.isna,
      );
      expect(autoMethodFor('Asia/Karachi'), CalculationMethod.karachi);
      expect(autoMethodFor('Asia/Kuala_Lumpur'), CalculationMethod.jakim);
      expect(autoMethodFor('Asia/Singapore'), CalculationMethod.singapore);
      expect(autoMethodFor('Asia/Jakarta'), CalculationMethod.indonesia);
      expect(autoMethodFor('Europe/Istanbul'), CalculationMethod.turkiye);
      expect(autoMethodFor('Europe/Paris'), CalculationMethod.france);
      expect(autoMethodFor('Asia/Dubai'), CalculationMethod.dubai);
    });

    test('anywhere else falls back to the Muslim World League', () {
      expect(
        autoMethodFor('Europe/London'),
        CalculationMethod.muslimWorldLeague,
      );
      expect(autoMethodFor('device/EEST'), CalculationMethod.muslimWorldLeague);
    });

    test('only auto is resolved; a chosen method stays as chosen', () {
      expect(
        CalculationMethod.auto.resolvedFor('Africa/Cairo'),
        CalculationMethod.egyptian,
      );
      expect(
        CalculationMethod.isna.resolvedFor('Africa/Cairo'),
        CalculationMethod.isna,
      );
    });
  });

  group('calculated times', () {
    final riyadhZone = zoneOffsetsFor('Asia/Riyadh');
    PrayerTimesCalculator riyadh(
      CalculationMethod method, {
      CustomAngles custom = const CustomAngles(),
    }) => PrayerTimesCalculator(
      latitude: 24.7136,
      longitude: 46.6753,
      zone: riyadhZone,
      method: method,
      customAngles: custom,
    );

    int ishaAfterMaghrib(PrayerDay d) =>
        d.timeOf(Prayer.isha)! - d.timeOf(Prayer.maghrib)!;

    test('Umm al-Qura: Isha 90 minutes after Maghrib, 120 in Ramadan', () {
      // 2026-10-13 is outside Ramadan; 2027-02-20 is inside Ramadan 1448.
      final normal = riyadh(CalculationMethod.ummAlQura)
          .forDay(const LocalDay(2026, 10, 13));
      final ramadan = riyadh(CalculationMethod.ummAlQura)
          .forDay(const LocalDay(2027, 2, 20));
      expect(ishaAfterMaghrib(normal), 90);
      expect(ishaAfterMaghrib(ramadan), 120);
    });

    test('a smaller custom Fajr angle gives a later Fajr', () {
      const day = LocalDay(2026, 10, 13);
      final deep = riyadh(
        CalculationMethod.custom,
        custom: const CustomAngles(fajrAngle: 20),
      ).forDay(day);
      final shallow = riyadh(
        CalculationMethod.custom,
        custom: const CustomAngles(fajrAngle: 12),
      ).forDay(day);
      expect(
        shallow.timeOf(Prayer.fajr)!,
        greaterThan(deep.timeOf(Prayer.fajr)!),
      );
    });

    test('custom Isha by minutes is that long after Maghrib', () {
      final day = riyadh(
        CalculationMethod.custom,
        custom: const CustomAngles(ishaMinutesAfterMaghrib: 75),
      ).forDay(const LocalDay(2026, 10, 13));
      expect(ishaAfterMaghrib(day), 75);
    });

    test('every method gives a full, ordered day in Cairo', () {
      final zone = zoneOffsetsFor('Africa/Cairo');
      for (final method in CalculationMethod.values) {
        final day = PrayerTimesCalculator(
          latitude: 30.0444,
          longitude: 31.2357,
          zone: zone,
          method: method,
        ).forDay(const LocalDay(2026, 10, 13));
        final times = [for (final p in Prayer.adhanPrayers) day.timeOf(p)];
        expect(times, everyElement(isNotNull), reason: method.name);
        for (var i = 1; i < times.length; i++) {
          expect(times[i]!, greaterThan(times[i - 1]!), reason: method.name);
        }
      }
    });
  });

  group('stored', () {
    late AppDatabase db;
    late SettingsRepository settings;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      settings = SettingsRepository(db);
    });
    tearDown(() => db.close());

    test('every method round-trips by name', () async {
      for (final method in CalculationMethod.values) {
        await settings.setPrayerTimesPreferences(calculationMethod: method);
        expect((await settings.read()).calculationMethod, method);
      }
    });

    test('the names stored before the list grew still read back', () {
      for (final name in [
        'muslimWorldLeague',
        'isna',
        'egyptian',
        'kuwait',
        'ummAlQura',
      ]) {
        expect(CalculationMethod.fromStorageKey(name).name, name);
      }
    });

    test(
      'custom angles round-trip, with Isha by angle or by minutes',
      () async {
        await settings.setPrayerTimesPreferences(
          customAngles: const CustomAngles(fajrAngle: 16.5, ishaAngle: 15),
        );
        expect(
          (await settings.read()).customAngles,
          const CustomAngles(fajrAngle: 16.5, ishaAngle: 15),
        );

        await settings.setPrayerTimesPreferences(
          customAngles: const CustomAngles(
            fajrAngle: 16.5,
            ishaAngle: 15,
            ishaMinutesAfterMaghrib: 80,
          ),
        );
        expect(
          (await settings.read()).customAngles.ishaMinutesAfterMaghrib,
          80,
        );
      },
    );

    test(
      'an out-of-range stored angle falls back instead of breaking',
      () async {
        await db.customStatement(
          "INSERT INTO app_settings (key, value) VALUES ('custom_fajr_angle', '45')",
        );
        expect(
          (await settings.read()).customAngles.fajrAngle,
          const CustomAngles().fajrAngle,
        );
      },
    );
  });
}
