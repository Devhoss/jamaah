import 'package:drift/drift.dart';

import '../domain/app_clock.dart';
import '../domain/iqama_editing.dart';
import '../domain/mosque.dart';
import '../domain/prayer.dart';
import '../domain/time_model.dart';
import 'app_database.dart';
import 'table_watch.dart';

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

/// Thrown when a reminder is switched on for a prayer with no Iqama time: a
/// reminder can never exist without one (AGENTS.md).
class ReminderWithoutIqamaException implements Exception {
  ReminderWithoutIqamaException(this.prayer);

  final Prayer prayer;

  @override
  String toString() =>
      '$prayer has no Iqama time, so it cannot have an Iqama reminder.';
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

  /// Saved mosques, newest first. Two added on the same instant fall back to
  /// insertion order, so the newest still leads.
  Future<List<Mosque>> saved() async {
    final rows = await (_db.select(_db.mosques)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.rowId),
          ]))
        .get();
    return Future.wait(rows.map(_load));
  }

  /// [saved], re-emitted whenever a mosque, a schedule or an Iqama entry changes.
  ///
  /// Watching only the mosques table would miss an Iqama edit, which writes
  /// schedules and schedule_prayers alone, and Today would keep the old time.
  Stream<List<Mosque>> watchSaved() => watchTables(
    _db,
    [_db.mosques, _db.schedules, _db.schedulePrayers],
    saved,
  );

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
  ///
  /// The name is required and both fields are trimmed. When no mosque is active
  /// yet, this one becomes active, as in the prototype, so Today has a mosque to
  /// read without an extra step. An existing active mosque is never replaced.
  Future<Mosque> add({
    required String name,
    required String address,
    required MosqueSource source,
    double? latitude,
    double? longitude,
    String? placeId,
  }) async {
    final mosque = Mosque.draft(
      name: _requireName(name),
      address: MosqueDetailsInput.address(address),
      source: source,
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
      now: _clock.nowUtc(),
    );
    await _db.transaction(() async {
      await save(mosque);
      final active = await (_db.select(_db.appSettings)
            ..where((t) => t.key.equals(SettingKeys.activeMosqueId)))
          .getSingleOrNull();
      if (active?.value == null) {
        await _db
            .into(_db.appSettings)
            .insert(
              AppSettingRow(key: SettingKeys.activeMosqueId, value: mosque.id),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
    return mosque;
  }

  /// Changes a mosque's name and address, leaving every schedule untouched.
  Future<void> updateDetails(
    String mosqueId, {
    required String name,
    required String address,
  }) async {
    final cleanName = _requireName(name);
    final changed = await (_db.update(_db.mosques)
          ..where((t) => t.id.equals(mosqueId)))
        .write(
          MosquesCompanion(
            name: Value(cleanName),
            address: Value(MosqueDetailsInput.address(address)),
          ),
        );
    if (changed == 0) {
      throw ArgumentError.value(
        mosqueId,
        'mosqueId',
        'No saved mosque has this id',
      );
    }
  }

  String _requireName(String raw) =>
      MosqueDetailsInput.name(raw) ??
      (throw ArgumentError.value(raw, 'name', 'A mosque needs a name'));

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
    if (!ReminderInterval.isValid(reminderMinutesBefore)) {
      throw ArgumentError.value(
        reminderMinutesBefore,
        'reminderMinutesBefore',
        'must be ${ReminderInterval.minMinutes}..${ReminderInterval.maxMinutes}',
      );
    }

    final now = _clock.nowUtc();
    final schedule = await _scheduleInForce(mosqueId, now);

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

  /// Pauses or resumes all of this mosque's Iqama reminders, keeping its Iqama
  /// times and every reminder setting.
  Future<void> setRemindersPaused(String mosqueId, {required bool paused}) async {
    final changed = await (_db.update(_db.mosques)
          ..where((t) => t.id.equals(mosqueId)))
        .write(MosquesCompanion(remindersPaused: Value(paused)));
    if (changed == 0) {
      throw ArgumentError.value(
        mosqueId,
        'mosqueId',
        'No saved mosque has this id',
      );
    }
  }

  /// Switches one prayer's reminder on or off, keeping its time and interval.
  ///
  /// Switching on a prayer with no Iqama time is refused: a reminder never
  /// exists without one (AGENTS.md).
  Future<Schedule> setReminderEnabled(
    String mosqueId,
    Prayer prayer, {
    required bool enabled,
  }) async {
    if (!prayer.canHaveIqama) throw IqamaNotAllowedException(prayer);

    final now = _clock.nowUtc();
    final schedule = await _scheduleInForce(mosqueId, now);
    final entry = schedule.iqamaFor(prayer);
    if (enabled && !entry.isConfigured) {
      throw ReminderWithoutIqamaException(prayer);
    }

    final updated = schedule.withPrayer(
      entry.copyWith(reminderEnabled: enabled),
      updatedAt: now,
    );
    await _db.transaction(() => _saveSchedule(mosqueId, updated));
    return updated;
  }

  /// The schedule an edit at [now] belongs to.
  ///
  /// Resolved on the device's own calendar day, since that is the day the user is
  /// editing a mosque's schedule for; the place's prayer day is the reading side.
  Future<Schedule> _scheduleInForce(String mosqueId, DateTime now) async {
    final mosque = await requireById(mosqueId);
    return mosque.scheduleFor(LocalDay.fromDateTime(now.toLocal())) ??
        Schedule.empty(mosqueId: mosqueId, updatedAt: now);
  }

  Future<Mosque?> byId(String id) async {
    final row = await (_db.select(_db.mosques)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _load(row);
  }

  /// The saved mosque with this provider place id, if any — how a search result
  /// knows it is already saved.
  Future<Mosque?> byPlaceId(String placeId) async {
    final row = await (_db.select(_db.mosques)
          ..where((t) => t.placeId.equals(placeId))
          ..limit(1))
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
      remindersPaused: row.remindersPaused,
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
  remindersPaused: mosque.remindersPaused,
);

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
