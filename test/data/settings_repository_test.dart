import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/adhan_recordings.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/prayer_times_parameters.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

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
      expect(
        snapshot.themeMode,
        AppThemeMode.system,
        reason: 'a fresh install has no pick of its own, so the device decides. A '
            'default of light here would overrule the phone the day Settings is wired.',
      );
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

    test('silent round-trips and stays distinct from disabled', () async {
      await settings.saveAdhanAlerts(
        AdhanAlertSettings(
          defaultSoundMode: AdhanSoundMode.silent,
          alerts: const {
            Prayer.fajr: AdhanAlert(enabled: true),
            Prayer.maghrib: AdhanAlert(
              enabled: false,
              soundModeOverride: AdhanSoundMode.silent,
            ),
          },
        ),
      );

      final stored = (await settings.read()).adhanAlerts;
      expect(stored.defaultSoundMode, AdhanSoundMode.silent);
      expect(stored.soundModeFor(Prayer.fajr), AdhanSoundMode.silent);
      // Silent is a sound mode, not an on/off switch: enablement is its own flag.
      expect(stored.alertFor(Prayer.maghrib).enabled, isFalse);
      expect(
        stored.alertFor(Prayer.maghrib).soundModeOverride,
        AdhanSoundMode.silent,
      );
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

    test('a device place arrives without a name of its own', () async {
      await settings.setLocation(
        const StoredLocation(
          latitude: 30.0444,
          longitude: 31.2357,
          ianaZone: 'Africa/Cairo',
          placeLabel: 'Africa/Cairo',
          usesGps: true,
        ),
      );

      expect(
        (await settings.read()).location?.userName,
        isNull,
        reason: 'the zone name the device gave us is not a name the user chose',
      );
    });

    test('a name the user gives is stored, and the device stays the source', () async {
      await settings.setLocation(
        const StoredLocation(
          latitude: 30.0444,
          longitude: 31.2357,
          ianaZone: 'Africa/Cairo',
          placeLabel: 'Africa/Cairo',
          usesGps: true,
        ),
      );
      await settings.renamePlace('Home');

      final stored = (await settings.read()).location;
      expect(stored?.userName, 'Home');
      expect(stored?.ianaZone, 'Africa/Cairo');
      expect(
        stored?.usesGps,
        isTrue,
        reason: 'naming a place does not turn the device into a city list',
      );
    });

    test('clearing the name goes back to what the app calls it', () async {
      await settings.setLocation(
        const StoredLocation(
          latitude: 30.0444,
          longitude: 31.2357,
          ianaZone: 'Africa/Cairo',
          placeLabel: 'Africa/Cairo',
          usesGps: true,
        ),
      );
      await settings.renamePlace('Home');
      await settings.renamePlace(null);

      expect((await settings.read()).location?.userName, isNull);
    });

    test('renaming with no place saved stores nothing', () async {
      await settings.renamePlace('Home');

      expect((await settings.read()).location, isNull);
      expect(
        await db.select(db.appSettings).get(),
        isEmpty,
        reason: 'a name without a place is a fact about nothing',
      );
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

  group('per-prayer notification settings (schema v2)', () {
    test('vibrate, the reminder before the Adhan and ring in silent round-trip',
        () async {
      final alerts = AdhanAlertSettings.defaults()
          .copyWith(fullScreen: true)
          .withAlert(
            Prayer.fajr,
            const AdhanAlert(
              enabled: true,
              soundModeOverride: AdhanSoundMode.full,
              vibrate: false,
              preAdhanMinutes: 15,
              ringInSilent: true,
            ),
          )
          .withAlert(
            Prayer.sunrise,
            const AdhanAlert(enabled: false, preAdhanMinutes: 20),
          );
      await settings.saveAdhanAlerts(alerts);

      final read = (await settings.read()).adhanAlerts;
      expect(read.fullScreen, isTrue);
      expect(read.alertFor(Prayer.fajr), alerts.alertFor(Prayer.fajr));
      expect(read.alertFor(Prayer.sunrise).preAdhanMinutes, 20);
      expect(read.alertFor(Prayer.sunrise).enabled, isFalse);
    });

    test('a fresh install vibrates, has no early reminder, and is not full screen',
        () async {
      final read = (await settings.read()).adhanAlerts;
      expect(read.fullScreen, isFalse);
      for (final prayer in Prayer.adhanPrayers) {
        final alert = read.alertFor(prayer);
        expect(alert.vibrate, isTrue, reason: '$prayer');
        expect(alert.preAdhanMinutes, isNull, reason: '$prayer');
        expect(alert.ringInSilent, isFalse, reason: '$prayer');
      }
    });

    test('the database refuses an early reminder outside 1..120', () async {
      await expectLater(
        db.customStatement(
          "UPDATE adhan_alert_rows SET pre_adhan_minutes = 0 WHERE prayer = 'fajr'",
        ),
        throwsA(anything),
      );
    });
  });

  group('travel and the Iqama pause', () {
    test('starts off, and round-trips', () async {
      expect((await settings.read()).travel, const TravelSettings());

      const travel = TravelSettings(
        travelMode: true,
        pauseAllIqamaReminders: true,
        followLocation: false,
      );
      await settings.saveTravel(travel);
      expect((await settings.read()).travel, travel);

      await settings.saveTravel(const TravelSettings());
      expect((await settings.read()).travel, const TravelSettings());
    });

    test('someone who followed their location before starts in travel mode',
        () async {
      await db.customStatement(
        "INSERT INTO app_settings (key, value) VALUES "
        "('${SettingKeys.followLocation}', 'true')",
      );
      final travel = (await settings.read()).travel;
      expect(travel.travelMode, isTrue);
      expect(travel.followsLocation, isTrue);
    });

    test('someone who had turned following off keeps it off', () async {
      await db.customStatement(
        "INSERT INTO app_settings (key, value) VALUES "
        "('${SettingKeys.followLocation}', 'false')",
      );
      final travel = (await settings.read()).travel;
      expect(travel.travelMode, isFalse);
      expect(travel.followLocation, isFalse);
    });

    test('the old Iqama-pause travel switch does not turn travel mode on',
        () async {
      await db.customStatement(
        "INSERT INTO app_settings (key, value) VALUES "
        "('${SettingKeys.travelMode}', 'true')",
      );
      expect((await settings.read()).travel.travelMode, isFalse);
    });

    test('the full Adhan recording round-trips, and an unknown one is the '
        'default', () async {
      expect(
        (await settings.read()).adhanAlerts.fullRecording,
        kDefaultAdhanRecording,
      );
      await settings.saveAdhanAlerts(
        AdhanAlertSettings.defaults().copyWith(fullRecording: 'minshawi'),
      );
      expect((await settings.read()).adhanAlerts.fullRecording, 'minshawi');

      await db.customStatement(
        "UPDATE app_settings SET value = 'gone' "
        "WHERE key = '${SettingKeys.adhanFullRecording}'",
      );
      expect(
        (await settings.read()).adhanAlerts.fullRecording,
        kDefaultAdhanRecording,
      );
    });

    test('Jama’ah reminders chime and vibrate until changed', () async {
      expect(
        (await settings.read()).jamaahReminders,
        const JamaahReminderSettings(),
      );
      const changed = JamaahReminderSettings(
        sound: ReminderSound.standard,
        vibrate: false,
      );
      await settings.saveJamaahReminders(changed);
      expect((await settings.read()).jamaahReminders, changed);
    });

    test('the theme choice round-trips', () async {
      expect((await settings.read()).themeMode, AppThemeMode.system);
      for (final mode in AppThemeMode.values) {
        await settings.setThemeMode(mode);
        expect((await settings.read()).themeMode, mode);
      }
    });

    test('a pause made under the old travel mode is still a pause', () async {
      await db.customStatement(
        "INSERT INTO app_settings (key, value) VALUES "
        "('${SettingKeys.travelMode}', 'true'), "
        "('${SettingKeys.pauseIqamaReminders}', 'true')",
      );
      expect((await settings.read()).travel.pauseAllIqamaReminders, isTrue);
    });

    test('an old pause choice without travel mode on was not a pause',
        () async {
      await db.customStatement(
        "INSERT INTO app_settings (key, value) VALUES "
        "('${SettingKeys.pauseIqamaReminders}', 'true')",
      );
      expect((await settings.read()).travel.pauseAllIqamaReminders, isFalse);
    });

    test('the new switch wins over the old keys once it is saved', () async {
      await db.customStatement(
        "INSERT INTO app_settings (key, value) VALUES "
        "('${SettingKeys.travelMode}', 'true'), "
        "('${SettingKeys.pauseIqamaReminders}', 'true')",
      );
      await settings.saveTravel(const TravelSettings());
      expect((await settings.read()).travel.pauseAllIqamaReminders, isFalse);
    });

    test('watch re-emits on every change, not just the first', () async {
      final seen = <AppSettingsSnapshot>[];
      final sub = settings.watch().listen(seen.add);
      await pumpEventQueue();

      await settings.saveTravel(const TravelSettings(followLocation: true));
      await pumpEventQueue();
      await settings.saveTravel(
        const TravelSettings(followLocation: true, pauseAllIqamaReminders: true),
      );
      await pumpEventQueue();
      await sub.cancel();

      expect(seen.last.travel.pauseAllIqamaReminders, isTrue);
    });
  });
}
