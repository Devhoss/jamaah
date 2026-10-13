import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/prayer.dart';
import 'app_database.steps.dart';

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

  /// Show the Adhan full screen when the phone is idle. Absent means off.
  static const adhanFullScreen = 'adhan_full_screen';
  static const adhanFullRecording = 'adhan_full_recording';
  static const jamaahReminderSound = 'jamaah_reminder_sound';
  static const jamaahReminderVibrate = 'jamaah_reminder_vibrate';

  /// Travel mode and its manual Iqama pause (decided 2026-10-13). Absent means off.
  static const travelMode = 'travel_mode';
  static const pauseIqamaReminders = 'pause_iqama_reminders';
  static const followLocation = 'follow_location';

  /// The travel-mode switch (2026-10-13). Not [travelMode], which was the
  /// earlier switch for the Iqama pause and is only read for that.
  static const travelModeOn = 'travel_mode_on';

  /// "Pause all Iqama reminders" in Settings (2026-10-13). Replaces the
  /// travel-mode pause; when absent, the old travel_mode + pause pair is read.
  static const pauseAllIqamaReminders = 'pause_all_iqama_reminders';

  /// "Follow my location": when the device last confirmed the place (Unix ms),
  /// and whether the latest try failed (the last place is then still in use).
  static const placeCheckedAt = 'place_checked_at';
  static const placeCheckFailed = 'place_check_failed';

  /// The user's own angles for the "Custom angles" method. Absent means the
  /// defaults in CustomAngles.
  static const customFajrAngle = 'custom_fajr_angle';
  static const customIshaAngle = 'custom_isha_angle';
  static const customIshaMinutes = 'custom_isha_minutes';
}

/// Per-prayer Adhan alert config: enabled flag, an optional sound override, and
/// (since schema v2) vibration, a reminder before the Adhan, and ringing in
/// silent mode.
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

  /// Schema v2. Whether the alert vibrates; on for every existing row.
  BoolColumn get vibrate => boolean().withDefault(const Constant(true))();

  /// Schema v2. Minutes before the Adhan for a heads-up; null means none.
  IntColumn get preAdhanMinutes => integer().nullable().customConstraint(
    'NULL CHECK (pre_adhan_minutes BETWEEN 1 AND 120)',
  )();

  /// Schema v2. Play the Adhan through the alarm volume even on silent.
  BoolColumn get ringInSilent => boolean().withDefault(const Constant(false))();

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

  /// Schema v3. The user paused this mosque's Iqama reminders (decided
  /// 2026-10-13); its Iqama times and reminder settings are kept.
  BoolColumn get remindersPaused =>
      boolean().withDefault(const Constant(false))();

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
/// `schemaVersion` 2 added the per-prayer notification columns to
/// [AdhanAlertRows]; 3 added [Mosques.remindersPaused]. v1 was already on a device, so v2 is a real migration and
/// keeps every existing row (see test/data/migration_test.dart).
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
  AppDatabase.open() : this(driftDatabase(name: 'jamaah'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedAdhanAlerts(this);
    },
    // Each step runs against the schema frozen at its version (generated by
    // `dart run drift_dev make-migrations`), so a later table edit cannot change
    // what an old migration does.
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.addColumn(schema.adhanAlertRows, schema.adhanAlertRows.vibrate);
        await m.addColumn(
          schema.adhanAlertRows,
          schema.adhanAlertRows.preAdhanMinutes,
        );
        await m.addColumn(
          schema.adhanAlertRows,
          schema.adhanAlertRows.ringInSilent,
        );
      },
      from2To3: (m, schema) async {
        await m.addColumn(schema.mosques, schema.mosques.remindersPaused);
      },
    ),
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
