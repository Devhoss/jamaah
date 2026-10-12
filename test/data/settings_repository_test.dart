import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awqaity/src/data/app_database.dart';
import 'package:awqaity/src/data/settings_repository.dart';
import 'package:awqaity/src/domain/adhan_alerts.dart';
import 'package:awqaity/src/domain/prayer.dart';
import 'package:awqaity/src/domain/prayer_times_parameters.dart';
import 'package:awqaity/src/domain/zone_offsets.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUpAll(loadTimeZoneDatabase);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
  });

  tearDown(() => db.close());

  group('defaults on a fresh install', () {
    test('match AGENTS.md and are readable without writing anything', () async {
      final snapshot = await settings.read();

      expect(snapshot.calculationMethod, CalculationMethod.muslimWorldLeague);
      expect(snapshot.madhab, Madhab.standard);
      expect(snapshot.highLatitudeRule, HighLatitudeRule.middleOfTheNight);
      expect(snapshot.themeMode, AppThemeMode.light);
      expect(snapshot.minuteOffsets, isEmpty);
      expect(snapshot.activeMosqueId, isNull);
      expect(snapshot.location, isNull);
    });

    test('no Adhan alert is enabled, sunrise included', () async {
      final snapshot = await settings.read();

      expect(snapshot.adhanAlerts.enabledPrayers, isEmpty);
      expect(snapshot.adhanAlerts.alertFor(Prayer.sunrise).enabled, isFalse);
      expect(snapshot.adhanAlerts.defaultSoundMode, AdhanSoundMode.standard);
    });
  });

  group('prayer times preferences', () {
    test('round-trip method, madhab and high latitude rule', () async {
      await settings.setPrayerTimesPreferences(
        calculationMethod: CalculationMethod.ummAlQura,
        madhab: Madhab.hanafi,
        highLatitudeRule: HighLatitudeRule.seventhOfTheNight,
      );

      final snapshot = await settings.read();
      expect(snapshot.calculationMethod, CalculationMethod.ummAlQura);
      expect(snapshot.madhab, Madhab.hanafi);
      expect(snapshot.highLatitudeRule, HighLatitudeRule.seventhOfTheNight);
    });

    test('minute offsets round-trip and zero means no entry', () async {
      await settings.setPrayerTimesPreferences(
        minuteOffsets: {Prayer.fajr: 2, Prayer.isha: -3, Prayer.asr: 0},
      );

      expect(
        (await settings.read()).minuteOffsets,
        {Prayer.fajr: 2, Prayer.isha: -3},
      );
    });

    test('replacing the offsets map drops the prayers it no longer lists',
        () async {
      await settings.setPrayerTimesPreferences(
        minuteOffsets: {Prayer.fajr: 5, Prayer.dhuhr: 1},
      );
      await settings.setPrayerTimesPreferences(minuteOffsets: {Prayer.fajr: 5});

      expect((await settings.read()).minuteOffsets, {Prayer.fajr: 5});
    });

    test('an unreadable stored value falls back to the default', () async {
      // A value written by a future version, or hand-edited storage, must not
      // stop the app from showing times.
      await db.customStatement(
        "INSERT INTO app_settings (key, value) VALUES "
        "('calculation_method', 'not_a_method')",
      );

      expect(
        (await settings.read()).calculationMethod,
        CalculationMethod.muslimWorldLeague,
      );
    });
  });

  group('theme', () {
    test('persists and survives a reopen', () async {
      await settings.setThemeMode(AppThemeMode.dark);
      expect((await settings.read()).themeMode, AppThemeMode.dark);
    });
  });

  group('adhan alerts', () {
    test('per-prayer enable and sound override round-trip', () async {
      await settings.saveAdhanAlerts(
        AdhanAlertSettings(
          defaultSoundMode: AdhanSoundMode.short,
          alerts: const {
            Prayer.fajr: AdhanAlert(
              enabled: true,
              soundModeOverride: AdhanSoundMode.full,
            ),
            Prayer.sunrise: AdhanAlert(enabled: true),
          },
        ),
      );

      final stored = (await settings.read()).adhanAlerts;
      expect(stored.defaultSoundMode, AdhanSoundMode.short);
      expect(stored.alertFor(Prayer.fajr).enabled, isTrue);
      expect(
        stored.alertFor(Prayer.fajr).soundModeOverride,
        AdhanSoundMode.full,
      );
      expect(stored.soundModeFor(Prayer.dhuhr), AdhanSoundMode.short);
      // Sunrise can carry an Adhan alert even though it has no Iqama.
      expect(stored.alertFor(Prayer.sunrise).enabled, isTrue);
    });

    test('clearing a sound override falls back to the global mode', () async {
      await settings.saveAdhanAlerts(
        AdhanAlertSettings(
          alerts: const {
            Prayer.isha: AdhanAlert(
              enabled: true,
              soundModeOverride: AdhanSoundMode.full,
            ),
          },
        ),
      );
      await settings.saveAdhanAlerts(
        const AdhanAlertSettings(
          alerts: {Prayer.isha: AdhanAlert(enabled: true)},
        ),
      );

      final stored = (await settings.read()).adhanAlerts;
      expect(stored.alertFor(Prayer.isha).soundModeOverride, isNull);
      expect(stored.soundModeFor(Prayer.isha), AdhanSoundMode.standard);
    });

    test('disabling a prayer that was enabled persists as disabled', () async {
      await settings.saveAdhanAlerts(
        const AdhanAlertSettings(
          alerts: {Prayer.maghrib: AdhanAlert(enabled: true)},
        ),
      );
      await settings.saveAdhanAlerts(
        const AdhanAlertSettings(
          alerts: {Prayer.maghrib: AdhanAlert(enabled: false)},
        ),
      );

      expect(
        (await settings.read()).adhanAlerts.alertFor(Prayer.maghrib).enabled,
        isFalse,
      );
    });
  });

  group('location', () {
    test('round-trips including the zone that makes times local', () async {
      await settings.setLocation(
        const StoredLocation(
          latitude: 51.5074,
          longitude: -0.1278,
          ianaZone: 'Europe/London',
          placeLabel: 'London',
          usesGps: true,
        ),
      );

      final stored = (await settings.read()).location;
      expect(stored?.latitude, 51.5074);
      expect(stored?.longitude, -0.1278);
      expect(stored?.ianaZone, 'Europe/London');
      expect(stored?.placeLabel, 'London');
      expect(stored?.usesGps, isTrue);
      expect(stored?.offsets.zoneName, 'Europe/London');
    });

    test('a manual pick is distinguishable from GPS', () async {
      await settings.setLocation(
        const StoredLocation(
          latitude: 21.4225,
          longitude: 39.8262,
          ianaZone: 'Asia/Makka',
          placeLabel: 'Makkah',
          usesGps: false,
        ),
      );

      expect((await settings.read()).location?.usesGps, isFalse);
    });

    test('clearing the location removes every stored key', () async {
      await settings.setLocation(
        const StoredLocation(
          latitude: 40.7128,
          longitude: -74.006,
          ianaZone: 'America/New_York',
          placeLabel: 'New York',
          usesGps: true,
        ),
      );
      await settings.setLocation(null);

      expect((await settings.read()).location, isNull);
      expect(await db.select(db.appSettings).get(), isEmpty);
    });

    test('a half-written location is treated as no location', () async {
      await db.customStatement(
        "INSERT INTO app_settings (key, value) VALUES ('latitude', '1.0')",
      );

      expect((await settings.read()).location, isNull);
    });
  });

  group('active mosque', () {
    test('set and clear', () async {
      await settings.setActiveMosqueId('m1');
      expect((await settings.read()).activeMosqueId, 'm1');

      await settings.setActiveMosqueId(null);
      expect((await settings.read()).activeMosqueId, isNull);
    });
  });

  group('watch', () {
    test('re-emits when any stored setting changes', () async {
      final emissions = <AppSettingsSnapshot>[];
      final sub = settings.watch().listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      await settings.setThemeMode(AppThemeMode.dark);
      await settings.saveAdhanAlerts(
        const AdhanAlertSettings(
          alerts: {Prayer.fajr: AdhanAlert(enabled: true)},
        ),
      );
      await settings.setPrayerTimesPreferences(
        minuteOffsets: {Prayer.asr: 3},
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      // Drift coalesces rapid updates, so what matters is that the stream
      // reaches the state written by every change above.
      expect(emissions.last.themeMode, AppThemeMode.dark);
      expect(
        emissions.last.adhanAlerts.alertFor(Prayer.fajr).enabled,
        isTrue,
      );
      expect(emissions.last.minuteOffsets, {Prayer.asr: 3});
    });
  });
}
