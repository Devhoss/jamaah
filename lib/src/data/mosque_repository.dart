import 'package:drift/drift.dart';

import '../domain/app_clock.dart';
import '../domain/mosque.dart';
import '../domain/prayer.dart';
import '../domain/time_model.dart';
import 'app_database.dart';

/// Thrown when something tries to give a mosque an Iqama for a prayer that cannot
/// have one — today that means sunrise (AGENTS.md).
class IqamaNotAllowedException implements Exception {
  IqamaNotAllowedException(this.prayer);

  final Prayer prayer;

  @override
  String toString() =>
      '$prayer cannot have an Iqama time. Sunrise has no Iqama and no Iqama '
      'reminder.';
}

/// Stores and loads saved mosques with their Iqama schedules.
///
/// Every Iqama time the user has not entered stays "Not configured": nothing here
/// writes a default, and nothing derives an Iqama from an Adhan time.
class MosqueRepository {
  /// [clock] decides which day a schedule is in force for and what stamp a write
  /// carries. It is injected rather than read from the wall here, because a stored
  /// schedule belongs to a date and that date has to be knowable from a test.
  MosqueRepository(this._db, {AppClock? clock}) : _clock = clock ?? const DeviceClock();

  final AppDatabase _db;
  final AppClock _clock;

  /// Saved mosques, newest first.
  Future<List<Mosque>> saved() async {
    final rows = await (_db.select(_db.mosques)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return Future.wait(rows.map(_load));
  }

  Stream<List<Mosque>> watchSaved() => _db
      .select(_db.mosques)
      .watch()
      .asyncMap((rows) => Future.wait(rows.map(_load)));

  /// Inserts or replaces a whole mosque with its schedules.
  Future<void> save(Mosque mosque) => _db.transaction(() async {
    await _db
        .into(_db.mosques)
        .insert(_toMosqueRow(mosque), mode: InsertMode.insertOrReplace);
    for (final schedule in mosque.schedules) {
      await _saveSchedule(mosque.id, schedule);
    }
  });

  /// Adds a mosque from a discovery result or manual entry, with one empty
  /// schedule — every Iqama time starts "Not configured".
  Future<Mosque> add({
    required String name,
    required String address,
    required MosqueSource source,
    double? latitude,
    double? longitude,
    String? placeId,
  }) async {
    final mosque = Mosque.draft(
      name: name,
      address: address,
      source: source,
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
    );
    await save(mosque);
    return mosque;
  }

  /// Deletes a mosque. If it was the active one, the active-mosque setting is
  /// cleared in the same transaction so reminders stop pointing at a mosque that
  /// no longer exists.
  Future<void> delete(String mosqueId) => _db.transaction(() async {
    await (_db.delete(_db.mosques)..where((t) => t.id.equals(mosqueId))).go();
    final active = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(SettingKeys.activeMosqueId)))
        .getSingleOrNull();
    if (active?.value == mosqueId) {
      await (_db.delete(_db.appSettings)
            ..where((t) => t.key.equals(SettingKeys.activeMosqueId)))
          .go();
    }
  });

  /// Writes one prayer's Iqama entry for the mosque's current schedule.
  ///
  /// [prayer] must be one of the five; anything else (sunrise) is rejected before
  /// it reaches the database, whose CHECK constraint would also refuse it.
  Future<Schedule> setIqama(
    String mosqueId,
    Prayer prayer,
    LocalTime? iqama, {
    bool reminderEnabled = false,
    int reminderMinutesBefore = 10,
  }) async {
    if (!prayer.canHaveIqama) throw IqamaNotAllowedException(prayer);

    final now = _clock.nowUtc();
    final mosque = await requireById(mosqueId);
    // Resolved on the device's own calendar day, since that is the day the user is
    // editing a mosque's schedule for; the place's prayer day is the reading side.
    final schedule = mosque.scheduleFor(LocalDay.fromDateTime(now.toLocal())) ??
        Schedule.empty(mosqueId: mosqueId, updatedAt: now);

    final updated = schedule.withPrayer(
      PrayerIqama(
        prayer: prayer,
        iqama: iqama,
        reminderEnabled: prayer.canHaveIqama &&
            iqama != null &&
            reminderEnabled,
        reminderMinutesBefore: reminderMinutesBefore,
      ),
      updatedAt: now,
    );

    await _db.transaction(() async {
      await _saveSchedule(mosqueId, updated);
    });
    return updated;
  }

  Future<Mosque?> byId(String id) async {
    final row = await (_db.select(_db.mosques)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _load(row);
  }

  Future<Mosque> requireById(String id) async =>
      (await byId(id)) ??
      (throw ArgumentError.value(id, 'mosqueId', 'No saved mosque has this id'));

  Future<void> _saveSchedule(String mosqueId, Schedule schedule) async {
    await _db
        .into(_db.schedules)
        .insert(
          ScheduleRow(
            id: schedule.id,
            mosqueId: mosqueId,
            effectiveFrom: _dayToInt(schedule.effectiveFrom),
            updatedAt: schedule.updatedAt.millisecondsSinceEpoch,
          ),
          mode: InsertMode.insertOrReplace,
        );
    await (_db.delete(_db.schedulePrayers)
          ..where((t) => t.scheduleId.equals(schedule.id)))
        .go();
    for (final prayer in Prayer.iqamaPrayers) {
      final entry = schedule.iqamaFor(prayer);
      await _db
          .into(_db.schedulePrayers)
          .insert(
            SchedulePrayerRow(
              scheduleId: schedule.id,
              prayer: prayer.name,
              iqamaMinutes: entry.iqama?.minutes,
              reminderEnabled: entry.reminderEnabled,
              reminderMinutesBefore: entry.reminderMinutesBefore,
            ),
          );
    }
  }

  Future<Mosque> _load(MosqueRow row) async {
    final scheduleRows = await (_db.select(_db.schedules)
          ..where((t) => t.mosqueId.equals(row.id)))
        .get();
    final prayerRows = await (_db.select(_db.schedulePrayers)
          ..where((t) => t.scheduleId.isIn(scheduleRows.map((s) => s.id))))
        .get();

    return Mosque(
      id: row.id,
      name: row.name,
      address: row.address,
      source: _source(row.source),
      latitude: row.latitude,
      longitude: row.longitude,
      placeId: row.placeId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      schedules: [
        for (final schedule in scheduleRows)
          Schedule(
            id: schedule.id,
            mosqueId: schedule.mosqueId,
            effectiveFrom: _intToDay(schedule.effectiveFrom),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(schedule.updatedAt),
            prayers: {
              for (final prayer in Prayer.iqamaPrayers)
                prayer: PrayerIqama(
                  prayer: prayer,
                  iqama: _minutesOf(prayerRows, schedule.id, prayer),
                  reminderEnabled: _reminderEnabledOf(
                    prayerRows,
                    schedule.id,
                    prayer,
                  ),
                  reminderMinutesBefore: _reminderMinutesOf(
                    prayerRows,
                    schedule.id,
                    prayer,
                  ),
                ),
            },
          ),
      ],
    );
  }

  LocalTime? _minutesOf(
    List<SchedulePrayerRow> rows,
    String scheduleId,
    Prayer prayer,
  ) {
    final row = rows.where(
      (r) => r.scheduleId == scheduleId && r.prayer == prayer.name,
    ).firstOrNull;
    return row?.iqamaMinutes == null
        ? null
        : LocalTime(row!.iqamaMinutes!);
  }

  bool _reminderEnabledOf(
    List<SchedulePrayerRow> rows,
    String scheduleId,
    Prayer prayer,
  ) => rows
      .where((r) => r.scheduleId == scheduleId && r.prayer == prayer.name)
      .firstOrNull
      ?.reminderEnabled ??
      false;

  int _reminderMinutesOf(
    List<SchedulePrayerRow> rows,
    String scheduleId,
    Prayer prayer,
  ) => rows
      .where((r) => r.scheduleId == scheduleId && r.prayer == prayer.name)
      .firstOrNull
      ?.reminderMinutesBefore ??
      10;

  MosqueSource _source(String name) => MosqueSource.values.firstWhere(
    (s) => s.name == name,
    orElse: () => MosqueSource.manual,
  );

  /// `yyyyMMdd`, so a plain integer compare orders effective dates correctly.
  int? _dayToInt(LocalDay? day) => day == null
      ? null
      : day.year * 10000 + day.month * 100 + day.day;

  LocalDay? _intToDay(int? value) => value == null
      ? null
      : LocalDay(
          value ~/ 10000,
          (value ~/ 100) % 100,
          value % 100,
        );
}

MosqueRow _toMosqueRow(Mosque mosque) => MosqueRow(
  id: mosque.id,
  name: mosque.name,
  address: mosque.address,
  source: mosque.source.name,
  latitude: mosque.latitude,
  longitude: mosque.longitude,
  placeId: mosque.placeId,
  createdAt: mosque.createdAt.millisecondsSinceEpoch,
);

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
