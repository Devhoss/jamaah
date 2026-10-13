// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // v1 is on a real device with the user's mosques and Iqama times on it, so
  // the upgrade must carry every row across unchanged and only add the new
  // per-prayer notification columns with their defaults.
  test('migration from v1 to v2 keeps every row and adds the defaults', () async {
    final oldAppSettingsData = <v1.AppSettingsData>[
      const v1.AppSettingsData(key: 'active_mosque_id', value: 'm1'),
      const v1.AppSettingsData(key: 'adhan_default_sound_mode', value: 'short'),
      const v1.AppSettingsData(key: 'iana_zone', value: 'Africa/Cairo'),
    ];
    final expectedNewAppSettingsData = <v2.AppSettingsData>[
      const v2.AppSettingsData(key: 'active_mosque_id', value: 'm1'),
      const v2.AppSettingsData(key: 'adhan_default_sound_mode', value: 'short'),
      const v2.AppSettingsData(key: 'iana_zone', value: 'Africa/Cairo'),
    ];

    final oldAdhanAlertRowsData = <v1.AdhanAlertRowsData>[
      const v1.AdhanAlertRowsData(prayer: 'fajr', enabled: 1, soundOverride: 'full'),
      const v1.AdhanAlertRowsData(prayer: 'sunrise', enabled: 0),
      const v1.AdhanAlertRowsData(prayer: 'isha', enabled: 1),
    ];
    final expectedNewAdhanAlertRowsData = <v2.AdhanAlertRowsData>[
      const v2.AdhanAlertRowsData(
        prayer: 'fajr',
        enabled: 1,
        soundOverride: 'full',
        vibrate: 1,
        ringInSilent: 0,
      ),
      const v2.AdhanAlertRowsData(
        prayer: 'sunrise',
        enabled: 0,
        vibrate: 1,
        ringInSilent: 0,
      ),
      const v2.AdhanAlertRowsData(
        prayer: 'isha',
        enabled: 1,
        vibrate: 1,
        ringInSilent: 0,
      ),
    ];

    final oldPrayerOffsetsData = <v1.PrayerOffsetsData>[
      const v1.PrayerOffsetsData(prayer: 'maghrib', minutes: 2),
    ];
    final expectedNewPrayerOffsetsData = <v2.PrayerOffsetsData>[
      const v2.PrayerOffsetsData(prayer: 'maghrib', minutes: 2),
    ];

    final oldMosquesData = <v1.MosquesData>[
      const v1.MosquesData(
        id: 'm1',
        name: 'Test Mosque',
        address: '',
        source: 'manual',
        createdAt: 1791884400000,
      ),
      const v1.MosquesData(
        id: 'm2',
        name: 'Omar Makram Mosque',
        address: 'Qasr El Nil, Cairo',
        source: 'google',
        placeId: 'ChIJ-example',
        createdAt: 1791887000000,
      ),
    ];
    final expectedNewMosquesData = <v2.MosquesData>[
      const v2.MosquesData(
        id: 'm1',
        name: 'Test Mosque',
        address: '',
        source: 'manual',
        createdAt: 1791884400000,
      ),
      const v2.MosquesData(
        id: 'm2',
        name: 'Omar Makram Mosque',
        address: 'Qasr El Nil, Cairo',
        source: 'google',
        placeId: 'ChIJ-example',
        createdAt: 1791887000000,
      ),
    ];

    final oldSchedulesData = <v1.SchedulesData>[
      const v1.SchedulesData(id: 's1', mosqueId: 'm1', updatedAt: 1791885000000),
    ];
    final expectedNewSchedulesData = <v2.SchedulesData>[
      const v2.SchedulesData(id: 's1', mosqueId: 'm1', updatedAt: 1791885000000),
    ];

    final oldSchedulePrayersData = <v1.SchedulePrayersData>[
      const v1.SchedulePrayersData(
        scheduleId: 's1',
        prayer: 'asr',
        iqamaMinutes: 15 * 60 + 15,
        reminderEnabled: 1,
        reminderMinutesBefore: 10,
      ),
      const v1.SchedulePrayersData(
        scheduleId: 's1',
        prayer: 'fajr',
        reminderEnabled: 0,
        reminderMinutesBefore: 10,
      ),
    ];
    final expectedNewSchedulePrayersData = <v2.SchedulePrayersData>[
      const v2.SchedulePrayersData(
        scheduleId: 's1',
        prayer: 'asr',
        iqamaMinutes: 15 * 60 + 15,
        reminderEnabled: 1,
        reminderMinutesBefore: 10,
      ),
      const v2.SchedulePrayersData(
        scheduleId: 's1',
        prayer: 'fajr',
        reminderEnabled: 0,
        reminderMinutesBefore: 10,
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.appSettings, oldAppSettingsData);
        batch.insertAll(oldDb.adhanAlertRows, oldAdhanAlertRowsData);
        batch.insertAll(oldDb.prayerOffsets, oldPrayerOffsetsData);
        batch.insertAll(oldDb.mosques, oldMosquesData);
        batch.insertAll(oldDb.schedules, oldSchedulesData);
        batch.insertAll(oldDb.schedulePrayers, oldSchedulePrayersData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewAppSettingsData,
          await newDb.select(newDb.appSettings).get(),
        );
        expect(
          expectedNewAdhanAlertRowsData,
          await newDb.select(newDb.adhanAlertRows).get(),
        );
        expect(
          expectedNewPrayerOffsetsData,
          await newDb.select(newDb.prayerOffsets).get(),
        );
        expect(expectedNewMosquesData, await newDb.select(newDb.mosques).get());
        expect(
          expectedNewSchedulesData,
          await newDb.select(newDb.schedules).get(),
        );
        expect(
          expectedNewSchedulePrayersData,
          await newDb.select(newDb.schedulePrayers).get(),
        );
      },
    );
  });

  // v3 adds mosques.reminders_paused. Every mosque keeps its row and starts
  // unpaused, and nothing else changes.
  test('migration from v2 to v3 keeps every mosque, none paused', () async {
    final oldMosques = <v2.MosquesData>[
      const v2.MosquesData(
        id: 'm1',
        name: 'Test Mosque',
        address: '',
        source: 'manual',
        createdAt: 1791884400000,
      ),
      const v2.MosquesData(
        id: 'm2',
        name: 'Omar Makram Mosque',
        address: 'Qasr El Nil, Cairo',
        source: 'google',
        placeId: 'ChIJ-example',
        createdAt: 1791887000000,
      ),
    ];
    final expectedMosques = <v3.MosquesData>[
      const v3.MosquesData(
        id: 'm1',
        name: 'Test Mosque',
        address: '',
        source: 'manual',
        createdAt: 1791884400000,
        remindersPaused: 0,
      ),
      const v3.MosquesData(
        id: 'm2',
        name: 'Omar Makram Mosque',
        address: 'Qasr El Nil, Cairo',
        source: 'google',
        placeId: 'ChIJ-example',
        createdAt: 1791887000000,
        remindersPaused: 0,
      ),
    ];
    final oldSchedules = <v2.SchedulesData>[
      const v2.SchedulesData(id: 's1', mosqueId: 'm1', updatedAt: 1791885000000),
    ];
    final oldPrayers = <v2.SchedulePrayersData>[
      const v2.SchedulePrayersData(
        scheduleId: 's1',
        prayer: 'asr',
        iqamaMinutes: 16 * 60 + 5,
        reminderEnabled: 1,
        reminderMinutesBefore: 10,
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.mosques, oldMosques);
        batch.insertAll(oldDb.schedules, oldSchedules);
        batch.insertAll(oldDb.schedulePrayers, oldPrayers);
      },
      validateItems: (newDb) async {
        expect(expectedMosques, await newDb.select(newDb.mosques).get());
        final prayers = await newDb.select(newDb.schedulePrayers).get();
        expect(prayers.single.iqamaMinutes, 16 * 60 + 5);
        expect(prayers.single.reminderEnabled, 1);
      },
    );
  });
}
