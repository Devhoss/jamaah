import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/prayer.dart';

part 'app_database.g.dart';

/// Every stored setting, one row each.
///
/// Keys are [AppSettings] constants below so a typo cannot silently create a
/// second, unreadable setting. Values are TEXT: the enums and numbers are parsed
/// by [SettingsRepository], which falls back to documented defaults for any value
/// it cannot read rather than throwing.
/// Row classes are suffixed `Row` so they never shadow the domain types
/// (`Mosque`, `Schedule`, ...) that the repositories map them to.
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Column names in [AppSettings.key].
abstract final class SettingKeys {
  static const calculationMethod = 'calculation_method';
  static const madhab = 'madhab';
  static const highLatitudeRule = 'high_latitude_rule';
  static const themeMode = 'theme_mode';

  /// The mosque whose Iqama schedule drives reminders. Null or absent means no
  /// active mosque, which is what a fresh install has.
  static const activeMosqueId = 'active_mosque_id';

  static const adhanDefaultSoundMode = 'adhan_default_sound_mode';

  /// Location the prayer times are calculated for, as reported by the device or
  /// picked from the city list. Absent means "location not set yet".
  static const latitude = 'latitude';
  static const longitude = 'longitude';
  static const ianaZone = 'iana_zone';
  static const placeLabel = 'place_label';

  /// The user's own name for the saved place. Absent means the app's label for it
  /// stands. It is the only part of a place the user can rewrite.
  static const placeUserName = 'place_user_name';

  /// True when the location came from the device GPS rather than a manual pick.
  static const usesGps = 'uses_gps';
}

/// Per-prayer Adhan alert config: enabled flag plus an optional sound override.
///
/// Holds a row for all six prayers including sunrise, which starts disabled
/// (AGENTS.md: sunrise may have an Adhan alert, default off).
@DataClassName('AdhanAlertRow')
class AdhanAlertRows extends Table {
  TextColumn get prayer => text().customConstraint(
    'NOT NULL CHECK (prayer IN '
    "('fajr','sunrise','dhuhr','asr','maghrib','isha'))",
  )();

  BoolColumn get enabled => boolean().withDefault(const Constant(false))();

  /// Null means "use the global default sound mode".
  TextColumn get soundOverride => text().nullable().customConstraint(
    'NULL CHECK (sound_override IN '
    '(\'full\',\'short\',\'standard\',\'silent\'))',
  )();

  @override
  Set<Column> get primaryKey => {prayer};
}

/// Per-prayer minute offsets applied on top of the calculation method.
@DataClassName('PrayerOffsetRow')
class PrayerOffsets extends Table {
  TextColumn get prayer => text().customConstraint(
    'NOT NULL CHECK (prayer IN '
    "('fajr','sunrise','dhuhr','asr','maghrib','isha'))",
  )();

  IntColumn get minutes => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {prayer};
}

@DataClassName('MosqueRow')
class Mosques extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();

  /// Which provider found this mosque, shown in the UI. There is no verification
  /// concept, so this is a source label and never a check mark (AGENTS.md).
  TextColumn get source => text().customConstraint(
    "NOT NULL CHECK (source IN ('google','osm','manual'))",
  )();

  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  /// Provider place ID, kept so a re-search recognises the same mosque.
  TextColumn get placeId => text().nullable()();

  /// Unix milliseconds, written by [MosqueRepository] from the domain model.
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ScheduleRow')
class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get mosqueId =>
      text().references(Mosques, #id, onDelete: KeyAction.cascade)();

  /// First day this schedule applies, as a `yyyyMMdd` number so it compares
  /// correctly. Null means "always", the fallback when no dated schedule applies.
  IntColumn get effectiveFrom => integer().nullable()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One user-entered Iqama time of one schedule.
///
/// Sunrise is impossible here by design: it has no Iqama and no Iqama reminder
/// (AGENTS.md), so the CHECK below rejects it and [MosqueRepository] refuses it
/// too. A missing Iqama value means "Not configured" — the app never stores or
/// displays a guessed default.
@DataClassName('SchedulePrayerRow')
class SchedulePrayers extends Table {
  TextColumn get scheduleId =>
      text().references(Schedules, #id, onDelete: KeyAction.cascade)();

  TextColumn get prayer => text().customConstraint(
    'NOT NULL CHECK (prayer IN '
    "('fajr','dhuhr','asr','maghrib','isha'))",
  )();

  /// Minutes from local midnight. Null is "Not configured".
  IntColumn get iqamaMinutes => integer().nullable()();

  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(false))();

  IntColumn get reminderMinutesBefore => integer().withDefault(const Constant(10))();

  @override
  Set<Column> get primaryKey => {scheduleId, prayer};
}

/// On-device storage: settings, mosques, Iqama schedules and Adhan alerts.
///
/// `schemaVersion` is 1. Every table the build order needs is already here so
/// later steps add no migration; when a real change is needed, bump the version,
/// write `onUpgrade`, and add a `SchemaVerifier` migration test (see
/// test/data/migration_test.dart).
@DriftDatabase(
  tables: [
    AppSettings,
    AdhanAlertRows,
    PrayerOffsets,
    Mosques,
    Schedules,
    SchedulePrayers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The app's own database, created lazily on first use.
  AppDatabase.open() : this(driftDatabase(name: 'awqaity'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedAdhanAlerts(this);
    },
    beforeOpen: (details) async {
      // Cascading deletes from mosques -> schedules -> schedule_prayers need this.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// Inserts one disabled, default-sound row per Adhan prayer, sunrise included.
///
/// Called when the database is first created so per-prayer Adhan settings always
/// have a row to read and update.
Future<void> seedAdhanAlerts(AppDatabase db) async {
  await db.batch((batch) {
    for (final prayer in Prayer.adhanPrayers) {
      batch.insert(
        db.adhanAlertRows,
        AdhanAlertRowsCompanion.insert(prayer: prayer.name),
        mode: InsertMode.insertOrIgnore,
      );
    }
  });
}
