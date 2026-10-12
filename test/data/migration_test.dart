import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awqaity/src/data/app_database.dart';
import 'package:awqaity/src/domain/adhan_alerts.dart';
import 'package:awqaity/src/domain/prayer.dart';

/// The drift migration harness.
///
/// The app is at `schemaVersion` 1, so there is no migration to run yet — what
/// this pins down is that the schema we create today is exactly the one drift
/// generated code believes in, and that the exported snapshot the future
/// migration tests build on stays in step with the Dart tables.
///
/// While no build of the app has reached a device, schema changes are folded back
/// into v1: edit the tables, keep `schemaVersion` at 1, delete
/// `drift_schema_v1.json`, then re-run `dart run drift_dev make-migrations`.
/// `make-migrations` refuses to overwrite a snapshot that differs from the tables,
/// which is how it notices an accidental edit to a version already in use.
///
/// Once v1 is on a device: bump `schemaVersion`, write `onUpgrade`, run
/// `dart run drift_dev make-migrations` (which exports `drift_schema_v<N>.json`
/// and, from two versions onwards, generates the verifier helper and a skeleton
/// migration test), then add a case here that migrates the old version and
/// asserts the data survived.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a freshly created v1 database matches drift\'s own expectations',
      () async {
    expect(db.schemaVersion, 1);
    await db.validateDatabaseSchema();
  });

  test('the exported schema snapshot matches the live schema version', () {
    final file = File('drift_schemas/app/drift_schema_v${db.schemaVersion}.json');
    expect(
      file.existsSync(),
      isTrue,
      reason:
          'Run `dart run drift_dev make-migrations` after changing tables so '
          'future migration tests have this snapshot.',
    );

    final exported = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final entities = exported['entities'] as List<dynamic>;
    final tables = entities
        .where((e) => (e as Map<String, dynamic>)['type'] == 'table')
        .map((e) => (e as Map<String, dynamic>)['data'])
        .cast<Map<String, dynamic>>();
    final names = tables.map((t) => t['name']).toSet();
    expect(
      names,
      containsAll(<String>{
        'app_settings',
        'adhan_alert_rows',
        'prayer_offsets',
        'mosques',
        'schedules',
        'schedule_prayers',
      }),
    );

    // The sunrise ban lives in the schema: schedule_prayers may only hold the
    // five Iqama prayers, so a future migration that rebuilds the table must
    // carry the same allowed set.
    final schedulePrayers = tables.firstWhere(
      (t) => t['name'] == 'schedule_prayers',
    );
    final prayerColumn = (schedulePrayers['columns'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((c) => c['name'] == 'prayer');
    final constraint = prayerColumn['customConstraints'] as String;
    expect(constraint, contains('CHECK'));
    for (final prayer in Prayer.iqamaPrayers) {
      expect(constraint, contains(prayer.name));
    }
    expect(
      constraint,
      isNot(contains('sunrise')),
      reason: 'AGENTS.md: sunrise has no Iqama, and storage must agree',
    );

    // The four sound modes are a CHECK constraint too, so a rebuilt table has to
    // carry all of them — an app that can store only three cannot offer silent,
    // which AGENTS.md requires to be distinct from "no notification at all".
    final adhanAlertRows = tables.firstWhere(
      (t) => t['name'] == 'adhan_alert_rows',
    );
    final soundOverride = (adhanAlertRows['columns'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((c) => c['name'] == 'sound_override');
    final soundConstraint = soundOverride['customConstraints'] as String;
    for (final mode in AdhanSoundMode.values) {
      expect(
        soundConstraint,
        contains(mode.name),
        reason: 'the stored sound modes must match the domain enum',
      );
    }
  });

  test('deleting a mosque cascades to its schedules and Iqama rows', () async {
    await db.into(db.mosques).insert(
      MosqueRow(
        id: 'm1',
        name: 'Masjid al-Nasr',
        address: '1 Example Road',
        source: 'manual',
        createdAt: 1,
      ),
    );
    await db.into(db.schedules).insert(
      ScheduleRow(id: 's1', mosqueId: 'm1', updatedAt: 1),
    );
    await db.into(db.schedulePrayers).insert(
      SchedulePrayerRow(
        scheduleId: 's1',
        prayer: 'fajr',
        iqamaMinutes: 320,
        reminderEnabled: false,
        reminderMinutesBefore: 10,
      ),
    );

    await db.delete(db.mosques).go();

    expect(await db.select(db.schedules).get(), isEmpty);
    expect(await db.select(db.schedulePrayers).get(), isEmpty);
  });

  test('the database refuses to store a sunrise Iqama', () async {
    await db.into(db.mosques).insert(
      MosqueRow(
        id: 'm1',
        name: 'Masjid al-Nasr',
        address: '1 Example Road',
        source: 'manual',
        createdAt: 1,
      ),
    );
    await db.into(db.schedules).insert(
      ScheduleRow(id: 's1', mosqueId: 'm1', updatedAt: 1),
    );

    // AGENTS.md: sunrise has no Iqama. The CHECK constraint makes that
    // impossible at storage level, not just by convention in the UI.
    expect(
      db.into(db.schedulePrayers).insert(
        SchedulePrayerRow(
          scheduleId: 's1',
          prayer: 'sunrise',
          reminderEnabled: false,
          reminderMinutesBefore: 10,
        ),
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('adhan alert rows exist for all six prayers, disabled, after create',
      () async {
    final rows = await db.select(db.adhanAlertRows).get();
    expect(rows.map((r) => r.prayer), hasLength(6));
    expect(rows.every((r) => !r.enabled), isTrue);
    expect(rows.map((r) => r.soundOverride), everyElement(isNull));
  });

  test('a sound override outside the stored modes is rejected', () async {
    // The CHECK constraint is the same list the domain enum holds, so a value the
    // app cannot interpret can never reach the table.
    expect(
      db.customUpdate(
        'UPDATE adhan_alert_rows SET sound_override = ? WHERE prayer = ?',
        variables: [
          Variable.withString('whisper'),
          Variable.withString(Prayer.fajr.name),
        ],
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('silent is a storable sound override', () async {
    await db.customUpdate(
      'UPDATE adhan_alert_rows SET sound_override = ? WHERE prayer = ?',
      variables: [
        Variable.withString(AdhanSoundMode.silent.storageKey),
        Variable.withString(Prayer.fajr.name),
      ],
    );

    final row = await (db.select(
      db.adhanAlertRows,
    )..where((t) => t.prayer.equals(Prayer.fajr.name))).getSingle();
    expect(row.soundOverride, 'silent');
  });
}
