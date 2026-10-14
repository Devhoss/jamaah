# Extra times (Imsak, Duha, Qiyam) and Jumu'ah Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show Imsak, Duha and the last third of the night on Today with optional alerts, and give each mosque a Jumu'ah time that replaces Dhuhr's Iqama on Fridays.

**Architecture:** Pure-Dart domain first (`extra_times.dart`, Friday resolution on `Schedule`), then storage (app_settings keys; schema v4 columns on `schedules`), then the planner/channels, then UI (Settings page, Today rows, mosque Jumu'ah row). Every time is derived from the existing `PrayerTimesCalculator` and `ZoneOffsets`, measured between UTC instants.

**Tech Stack:** Flutter, Riverpod 3, drift (+ `drift_dev make-migrations`), flutter_local_notifications, gen-l10n (EN template + Arabic via `tool/arabic_strings.py`).

**Spec:** `docs/superpowers/specs/2026-10-14-extra-times-jumuah-design.md`

## Global Constraints

- Imsak = Fajr − N min, N ∈ 0–20, default 10. Duha = sunrise + M min, M ∈ 10–30, default 15. Qiyam = Maghrib + ⅔ × (next day's Fajr − Maghrib).
- Defaults: shown `{imsak}`, alerts `{}`. Extra times never have an Iqama, a countdown, or become "next prayer".
- A missing input time ⇒ that extra time is absent. Never guessed.
- Jumu'ah starts "Not configured" on every mosque; the picker may *start* at Dhuhr's Adhan but nothing is stored until confirmed.
- Friday = the place's own date (`LocalDay` from `todayProvider` / the planner's day), never the phone's.
- Jumu'ah not set on a Friday ⇒ the Dhuhr Iqama and Dhuhr's reminder settings are used, with the note "Jumu'ah time not set · showing Dhuhr Iqama".
- Code/data keep iqama names; UI says "Jama’ah reminder". No hard-coded strings: EN in `app_en.arb`, AR in `tool/arabic_strings.py`, then `flutter gen-l10n` and `python tool/gen_arabic_digits.py`.
- Commit each green task: `git -c user.name="Jamaah dev" -c user.email="dev@jamaah.local" commit`, message ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; stage with `git add -A -- . ':!android/app/build.gradle.kts'`.
- `dart format` new files only. Write string patches as Python scripts (Write tool), never Bash heredocs.

## Review Focus

1. **Qiyam before Fajr:** at 02:00 Today must show the night in progress (yesterday evening's Qiyam), not tomorrow night's — pinned in Task 1 (`extraTimesForToday`).
2. **Friday at a place whose date differs from the phone's:** Jumu'ah follows the place's date — pinned in Task 4 (planner test with a Friday `LocalDay`) and Task 7 (Today widget at a Friday place date).
3. **Old database upgrade:** a v3 database with Iqama rows opens on v4 with every row kept and Jumu'ah unset — pinned in Task 3.
4. **In-flight hold:** extra-time alerts are held like everything else — pinned in Task 4 (`applyInFlightHold` test).
5. **Jumu'ah unset but Dhuhr reminder on:** the Friday reminder still fires at Dhuhr's Iqama — pinned in Task 4.

---

### Task 1: Extra-times domain

**Files:**
- Create: `lib/src/domain/extra_times.dart`
- Test: `test/domain/extra_times_test.dart`

**Interfaces:**
- Produces: `enum ExtraTime { imsak, duha, qiyam }`; `class ExtraTimesSettings { int imsakMinutes; int duhaMinutes; Set<ExtraTime> shown; Set<ExtraTime> alerts; copyWith(...) }`; `int clampImsakMinutes(int)`, `int clampDuhaMinutes(int)`; constants `kMinImsakMinutes=0, kMaxImsakMinutes=20, kMinDuhaMinutes=10, kMaxDuhaMinutes=30`; `class ExtraTimeAt { ExtraTime time; LocalDay day; LocalTime at; DateTime utc; }`; `List<ExtraTimeAt> extraTimesFor({required PrayerTimesCalculator calculator, required LocalDay day, required ExtraTimesSettings settings})`; `List<ExtraTimeAt> extraTimesForToday({required PrayerTimesCalculator calculator, required LocalMoment moment, required ExtraTimesSettings settings})` (filtered to `settings.shown`, in time order).

- [ ] **Step 1: Write the failing tests** (`test/domain/extra_times_test.dart`). Use the Kuwait calculator the other domain tests use (see `test/domain/prayer_times_test.dart` for `loadTimeZoneDatabase` and building `ZoneOffsets` for `Asia/Kuwait`). Cases:

```dart
test('Imsak is N minutes before Fajr, Duha M after sunrise', () {
  final day = const LocalDay(2026, 10, 14);
  final times = calc.forDay(day).times;
  final out = extraTimesFor(calculator: calc, day: day,
      settings: const ExtraTimesSettings(imsakMinutes: 10, duhaMinutes: 15));
  final byTime = {for (final e in out) e.time: e};
  expect(byTime[ExtraTime.imsak]!.at.minutes, times[Prayer.fajr]! - 10);
  expect(byTime[ExtraTime.duha]!.at.minutes, times[Prayer.sunrise]! + 15);
});

test('Qiyam starts the last third of Maghrib to next Fajr', () {
  final day = const LocalDay(2026, 10, 14);
  final maghrib = calc.forDay(day).times[Prayer.maghrib]!;
  final fajr = calc.forDay(day.addDays(1)).times[Prayer.fajr]!;
  final night = fajr + 1440 - maghrib;
  final q = extraTimesFor(calculator: calc, day: day,
          settings: const ExtraTimesSettings())
      .singleWhere((e) => e.time == ExtraTime.qiyam);
  expect(q.day, day.addDays(1)); // after midnight in Kuwait
  expect(q.at.minutes, (maghrib + night * 2 ~/ 3) - 1440);
});

test('a DST night is measured at its real length', () {
  // London, the night of 2026-10-24 → 25 (clocks go back at 02:00).
  // Expected: maghrib instant + 2/3 of the real (25-hour-day) gap.
});

test('a day with no Fajr has no Imsak and no Qiyam the evening before', () {
  // Calculator at 70°N on 2026-06-21 (unresolved polar): times empty → [].
});

test('Today before Fajr shows the night in progress', () {
  // moment = 02:00 on 2026-10-15 at Kuwait → Qiyam.day == 2026-10-15 and
  // equals extraTimesFor(day: 2026-10-14)'s Qiyam.
});

test('Today after Fajr shows tonight', () { /* moment 12:00 → from day itself */ });

test('only shown times, in time order', () {
  // shown {qiyam, imsak} → [imsak, qiyam]; duha absent.
});

test('clamping', () {
  expect(clampImsakMinutes(-3), 0); expect(clampImsakMinutes(99), 20);
  expect(clampDuhaMinutes(1), 10); expect(clampDuhaMinutes(99), 30);
});
```

- [ ] **Step 2: Run and see it fail** — `flutter test test/domain/extra_times_test.dart` → compile error, `extra_times.dart` missing.

- [ ] **Step 3: Implement** `lib/src/domain/extra_times.dart`:

```dart
import 'prayer.dart';
import 'prayer_times_calculator.dart';
import 'time_model.dart';
import 'today.dart';

/// Times that are not one of the five prayers (2026-10-14). Shown on Today
/// when the user asks; never an Iqama, never the next prayer.
enum ExtraTime { imsak, duha, qiyam }

const kMinImsakMinutes = 0;
const kMaxImsakMinutes = 20;
const kMinDuhaMinutes = 10;
const kMaxDuhaMinutes = 30;

int clampImsakMinutes(int m) => m.clamp(kMinImsakMinutes, kMaxImsakMinutes);
int clampDuhaMinutes(int m) => m.clamp(kMinDuhaMinutes, kMaxDuhaMinutes);

class ExtraTimesSettings {
  const ExtraTimesSettings({
    this.imsakMinutes = 10,
    this.duhaMinutes = 15,
    this.shown = const {ExtraTime.imsak},
    this.alerts = const {},
  });

  /// Imsak is this many minutes before Fajr.
  final int imsakMinutes;

  /// Duha starts this many minutes after sunrise.
  final int duhaMinutes;

  final Set<ExtraTime> shown;
  final Set<ExtraTime> alerts;

  ExtraTimesSettings copyWith({int? imsakMinutes, int? duhaMinutes,
      Set<ExtraTime>? shown, Set<ExtraTime>? alerts}) => ExtraTimesSettings(
    imsakMinutes: imsakMinutes ?? this.imsakMinutes,
    duhaMinutes: duhaMinutes ?? this.duhaMinutes,
    shown: shown ?? this.shown,
    alerts: alerts ?? this.alerts,
  );

  @override
  bool operator ==(Object other) =>
      other is ExtraTimesSettings &&
      other.imsakMinutes == imsakMinutes &&
      other.duhaMinutes == duhaMinutes &&
      _sameSet(other.shown, shown) &&
      _sameSet(other.alerts, alerts);

  @override
  int get hashCode => Object.hash(imsakMinutes, duhaMinutes,
      Object.hashAllUnordered(shown), Object.hashAllUnordered(alerts));
}

bool _sameSet(Set<ExtraTime> a, Set<ExtraTime> b) =>
    a.length == b.length && a.containsAll(b);

/// One extra time on the place's wall clock, and the instant it falls on.
class ExtraTimeAt {
  const ExtraTimeAt({required this.time, required this.day, required this.at, required this.utc});
  final ExtraTime time;
  final LocalDay day;
  final LocalTime at;
  final DateTime utc;
}

/// Imsak before [day]'s Fajr, Duha after its sunrise, and the Qiyam of the
/// night that begins on its evening. Measured between instants, so a night
/// with a clock change is counted at its real length. A time whose inputs are
/// missing is left out, never guessed.
List<ExtraTimeAt> extraTimesFor({
  required PrayerTimesCalculator calculator,
  required LocalDay day,
  required ExtraTimesSettings settings,
}) {
  final zone = calculator.zone;
  final times = calculator.forDay(day).times;
  DateTime? instant(LocalDay d, int? minutes) => minutes == null
      ? null
      : zone.utcInstantOf(day: d, time: LocalTime(minutes));
  ExtraTimeAt at(ExtraTime time, DateTime utc) {
    final ms = utc.millisecondsSinceEpoch;
    final whole = DateTime.fromMillisecondsSinceEpoch(ms - ms % 60000, isUtc: true);
    final local = LocalMoment.inZone(zone: zone, utcInstant: whole);
    return ExtraTimeAt(time: time, day: local.day,
        at: LocalTime(local.minutesOfDay), utc: whole);
  }

  final out = <ExtraTimeAt>[];
  if (instant(day, times[Prayer.fajr]) case final fajr?) {
    out.add(at(ExtraTime.imsak, fajr.subtract(Duration(minutes: settings.imsakMinutes))));
  }
  if (instant(day, times[Prayer.sunrise]) case final sunrise?) {
    out.add(at(ExtraTime.duha, sunrise.add(Duration(minutes: settings.duhaMinutes))));
  }
  final maghrib = instant(day, times[Prayer.maghrib]);
  final next = day.addDays(1);
  final fajr = instant(next, calculator.forDay(next).times[Prayer.fajr]);
  if (maghrib != null && fajr != null && fajr.isAfter(maghrib)) {
    out.add(at(ExtraTime.qiyam, maghrib.add(fajr.difference(maghrib) * 2 ~/ 3)));
  }
  return out;
}

/// What Today lists: Imsak and Duha of [moment]'s day, and the Qiyam of the
/// night in progress (before Fajr, last evening's) or the one ahead. Only the
/// [ExtraTimesSettings.shown] ones, in time order.
List<ExtraTimeAt> extraTimesForToday({
  required PrayerTimesCalculator calculator,
  required LocalMoment moment,
  required ExtraTimesSettings settings,
}) {
  final today = extraTimesFor(calculator: calculator, day: moment.day, settings: settings);
  final fajr = calculator.forDay(moment.day).times[Prayer.fajr];
  final beforeFajr = fajr != null && moment.minutesOfDay < fajr;
  final night = beforeFajr
      ? extraTimesFor(calculator: calculator, day: moment.day.addDays(-1), settings: settings)
      : today;
  return [
    for (final e in today) if (e.time != ExtraTime.qiyam) e,
    for (final e in night) if (e.time == ExtraTime.qiyam) e,
  ].where((e) => settings.shown.contains(e.time)).toList()
    ..sort((a, b) => a.utc.compareTo(b.utc));
}
```

- [ ] **Step 4: Run** `flutter test test/domain/extra_times_test.dart` → all pass. Fill the DST and polar cases with concrete expectations computed from the calculator (as the Qiyam test does), not hard-coded clock values.
- [ ] **Step 5: `dart format` the two new files; commit** "Extra times: Imsak, Duha and the last third of the night (domain)".

---

### Task 2: Extra-times settings storage

**Files:**
- Modify: `lib/src/data/app_database.dart` (SettingKeys), `lib/src/data/settings_repository.dart`
- Test: `test/data/settings_repository_test.dart`

**Interfaces:**
- Consumes: `ExtraTimesSettings`, `ExtraTime`, clamp helpers (Task 1).
- Produces: `AppSettingsSnapshot.extraTimes` (`ExtraTimesSettings`, default `const ExtraTimesSettings()`); `SettingsRepository.saveExtraTimes(ExtraTimesSettings)`; keys `extra_imsak_minutes`, `extra_duha_minutes`, `extra_shown`, `extra_alerts`.

- [ ] **Step 1: Failing tests** in `settings_repository_test.dart`:

```dart
test('extra times default to Imsak shown, no alerts', () async {
  expect((await settings.read()).extraTimes, const ExtraTimesSettings());
});
test('extra times round-trip, clamped', () async {
  await settings.saveExtraTimes(const ExtraTimesSettings(
      imsakMinutes: 25, duhaMinutes: 20,
      shown: {ExtraTime.duha, ExtraTime.qiyam}, alerts: {ExtraTime.imsak}));
  final read = (await settings.read()).extraTimes;
  expect(read.imsakMinutes, 20);
  expect(read.duhaMinutes, 20);
  expect(read.shown, {ExtraTime.duha, ExtraTime.qiyam});
  expect(read.alerts, {ExtraTime.imsak});
});
test('nothing shown is stored as nothing, not as the default', () async {
  await settings.saveExtraTimes(const ExtraTimesSettings(shown: {}));
  expect((await settings.read()).extraTimes.shown, isEmpty);
});
```

- [ ] **Step 2: Run** → fails (no `extraTimes`).
- [ ] **Step 3: Implement.** SettingKeys:

```dart
  /// Extra times (2026-10-14): minutes, and comma lists of ExtraTime names.
  static const extraImsakMinutes = 'extra_imsak_minutes';
  static const extraDuhaMinutes = 'extra_duha_minutes';
  static const extraShown = 'extra_shown';
  static const extraAlerts = 'extra_alerts';
```

Snapshot field `final ExtraTimesSettings extraTimes;` (constructor default `const ExtraTimesSettings()`), read with:

```dart
      extraTimes: ExtraTimesSettings(
        imsakMinutes: clampImsakMinutes(int.tryParse(values[SettingKeys.extraImsakMinutes] ?? '') ?? 10),
        duhaMinutes: clampDuhaMinutes(int.tryParse(values[SettingKeys.extraDuhaMinutes] ?? '') ?? 15),
        shown: _extraSet(values[SettingKeys.extraShown], const {ExtraTime.imsak}),
        alerts: _extraSet(values[SettingKeys.extraAlerts], const {}),
      ),
```

```dart
/// A stored comma list; absent means [fallback], empty means none.
Set<ExtraTime> _extraSet(String? stored, Set<ExtraTime> fallback) {
  if (stored == null) return fallback;
  return {
    for (final name in stored.split(','))
      if (ExtraTime.values.asNameMap()[name] case final t?) t,
  };
}

  Future<void> saveExtraTimes(ExtraTimesSettings extra) => _db.transaction(() async {
    await _put(SettingKeys.extraImsakMinutes, '${clampImsakMinutes(extra.imsakMinutes)}');
    await _put(SettingKeys.extraDuhaMinutes, '${clampDuhaMinutes(extra.duhaMinutes)}');
    await _put(SettingKeys.extraShown, extra.shown.map((t) => t.name).join(','));
    await _put(SettingKeys.extraAlerts, extra.alerts.map((t) => t.name).join(','));
  });
```

Also add `extraTimes` to `SettingsRepository.defaults` if it lists fields explicitly, and to the snapshot's `==`/`copyWith` if they exist (check the class).
- [ ] **Step 4: Run** the repository tests → pass.
- [ ] **Step 5: Commit** "Store the extra-times settings".

---

### Task 3: Jumu'ah in the mosque model and database (schema v4)

**Files:**
- Modify: `lib/src/domain/time_model.dart` (`LocalDay.isFriday`), `lib/src/domain/mosque.dart`, `lib/src/data/app_database.dart`, `lib/src/data/mosque_repository.dart`
- Generated: `drift_schemas/app/drift_schema_v4.json`, `test/drift/app/generated/*` (via `dart run drift_dev make-migrations`), `lib/src/data/app_database.g.dart`, `app_database.steps.dart` (via `dart run build_runner build`)
- Test: `test/domain/iqama_and_reminders_test.dart`, `test/data/mosque_repository_test.dart`, `test/drift/app/migration_test.dart`, `test/data/migration_test.dart` (expect 4)

**Interfaces:**
- Produces:
  - `bool get LocalDay.isFriday`
  - `Schedule.jumuah` (`PrayerIqama`, `prayer: Prayer.dhuhr`; `Schedule.empty` gives an unset one; in `copyWith`, `==`)
  - `class DayIqama { PrayerIqama entry; bool isJumuah; bool jumuahNotSet; }` and `DayIqama Schedule.iqamaOn(LocalDay day, Prayer prayer)`
  - `MosqueRepository.setJumuah(String mosqueId, LocalTime? time, {bool reminderEnabled = false, int reminderMinutesBefore = 10}) → Future<Schedule>`
  - `MosqueRepository.setJumuahReminderEnabled(String mosqueId, {required bool enabled}) → Future<Schedule>` (throws `ReminderWithoutIqamaException(Prayer.dhuhr)` when unset)

- [ ] **Step 1: Failing domain tests** (`iqama_and_reminders_test.dart`):

```dart
const friday = LocalDay(2026, 10, 16);
const thursday = LocalDay(2026, 10, 15);
test('LocalDay.isFriday', () { expect(friday.isFriday, isTrue); expect(thursday.isFriday, isFalse); });

test('a new schedule has Jumu\'ah not configured', () {
  expect(Schedule.empty().jumuah.isConfigured, isFalse);
});

test('on a Friday Dhuhr resolves to Jumu\'ah when set', () {
  final s = Schedule.empty()
      .withPrayer(const PrayerIqama(prayer: Prayer.dhuhr, iqama: LocalTime(12 * 60 + 15)))
      .copyWith(jumuah: const PrayerIqama(prayer: Prayer.dhuhr, iqama: LocalTime(11 * 60 + 45), reminderEnabled: true));
  final r = s.iqamaOn(friday, Prayer.dhuhr);
  expect(r.isJumuah, isTrue); expect(r.jumuahNotSet, isFalse);
  expect(r.entry.iqama, const LocalTime(11 * 60 + 45));
  expect(s.iqamaOn(thursday, Prayer.dhuhr).entry.iqama, const LocalTime(12 * 60 + 15));
  expect(s.iqamaOn(friday, Prayer.asr).isJumuah, isFalse);
});

test('Friday without Jumu\'ah falls back to the Dhuhr Iqama, flagged', () {
  final s = Schedule.empty().withPrayer(const PrayerIqama(prayer: Prayer.dhuhr, iqama: LocalTime(750), reminderEnabled: true));
  final r = s.iqamaOn(friday, Prayer.dhuhr);
  expect(r.isJumuah, isTrue); expect(r.jumuahNotSet, isTrue);
  expect(r.entry.iqama, const LocalTime(750)); expect(r.entry.reminderEnabled, isTrue);
});
```

- [ ] **Step 2: Run** → fail.
- [ ] **Step 3: Implement domain.** `time_model.dart`:

```dart
  bool get isFriday => DateTime.utc(year, month, day).weekday == DateTime.friday;
```

`mosque.dart`: add `this.jumuah = const PrayerIqama(prayer: Prayer.dhuhr)` to `Schedule`'s constructor (optional, so existing callers compile), the field with doc comment ("Jumu'ah's Iqama (2026-10-14), kept apart from Dhuhr's: it replaces it on Fridays. Stored with prayer dhuhr; the UI names it Jumu'ah."), `PrayerIqama? jumuah` in `copyWith` (`jumuah: jumuah ?? this.jumuah`), `other.jumuah == jumuah` in `==`, and:

```dart
  /// The Iqama for [prayer] on [day]: on a Friday, Dhuhr's is Jumu'ah's, or
  /// Dhuhr's own (flagged) while Jumu'ah has no time.
  DayIqama iqamaOn(LocalDay day, Prayer prayer) {
    if (prayer != Prayer.dhuhr || !day.isFriday) {
      return DayIqama(entry: iqamaFor(prayer));
    }
    if (jumuah.isConfigured) return DayIqama(entry: jumuah, isJumuah: true);
    return DayIqama(entry: iqamaFor(Prayer.dhuhr), isJumuah: true, jumuahNotSet: true);
  }
```

```dart
/// One prayer's Iqama as it applies on a given day.
class DayIqama {
  const DayIqama({required this.entry, this.isJumuah = false, this.jumuahNotSet = false});
  final PrayerIqama entry;

  /// Friday's Dhuhr: named Jumu'ah wherever it is shown.
  final bool isJumuah;

  /// Friday, but the mosque has no Jumu'ah time: [entry] is Dhuhr's own, and
  /// the UI says so rather than present it as the Jumu'ah time.
  final bool jumuahNotSet;
}
```

- [ ] **Step 4: Schema.** In `Schedules` add:

```dart
  /// Jumu'ah's Iqama (schema v4, 2026-10-14). Null is "Not configured".
  IntColumn get jumuahMinutes => integer().nullable()();
  BoolColumn get jumuahReminderEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get jumuahReminderMinutesBefore => integer().withDefault(const Constant(10))();
```

`schemaVersion => 4`; doc comment adds "4 added Jumu'ah to [Schedules]"; step:

```dart
      from3To4: (m, schema) async {
        await m.addColumn(schema.schedules, schema.schedules.jumuahMinutes);
        await m.addColumn(schema.schedules, schema.schedules.jumuahReminderEnabled);
        await m.addColumn(schema.schedules, schema.schedules.jumuahReminderMinutesBefore);
      },
```

Run `dart run build_runner build --delete-conflicting-outputs`, then `dart run drift_dev make-migrations` (generates v4 snapshot, steps and test schema; build_runner again if the steps file asks). Update `test/data/migration_test.dart` to expect 4.

- [ ] **Step 5: Migration data test** in `test/drift/app/migration_test.dart`, following the existing v1→v2 test's shape with `v3`/`v4` generated schemas: insert one mosque, one schedule and one `schedule_prayers` row (dhuhr 750, reminder on) at v3, migrate to v4, assert the rows are unchanged and the schedule row has `jumuahMinutes == null`, `jumuahReminderEnabled == false`, `jumuahReminderMinutesBefore == 10`.

- [ ] **Step 6: Repository.** In `_saveSchedule` write `jumuahMinutes: schedule.jumuah.iqama?.minutes, jumuahReminderEnabled: schedule.jumuah.reminderEnabled, jumuahReminderMinutesBefore: schedule.jumuah.reminderMinutesBefore` on the `ScheduleRow`; in `_load` build `jumuah: PrayerIqama(prayer: Prayer.dhuhr, iqama: schedule.jumuahMinutes == null ? null : LocalTime(schedule.jumuahMinutes!), reminderEnabled: schedule.jumuahReminderEnabled, reminderMinutesBefore: schedule.jumuahReminderMinutesBefore)`. Add:

```dart
  /// Writes the mosque's Jumu'ah Iqama, as [setIqama] does for the five.
  Future<Schedule> setJumuah(String mosqueId, LocalTime? time,
      {bool reminderEnabled = false, int reminderMinutesBefore = 10}) async {
    if (!ReminderInterval.isValid(reminderMinutesBefore)) {
      throw ArgumentError.value(reminderMinutesBefore, 'reminderMinutesBefore',
          'must be ${ReminderInterval.minMinutes}..${ReminderInterval.maxMinutes}');
    }
    final now = _clock.nowUtc();
    final schedule = await _scheduleInForce(mosqueId, now);
    final updated = schedule.copyWith(
      jumuah: PrayerIqama(prayer: Prayer.dhuhr, iqama: time,
          reminderEnabled: time != null && reminderEnabled,
          reminderMinutesBefore: reminderMinutesBefore),
      updatedAt: now,
    );
    await _db.transaction(() => _saveSchedule(mosqueId, updated));
    return updated;
  }

  Future<Schedule> setJumuahReminderEnabled(String mosqueId, {required bool enabled}) async {
    final now = _clock.nowUtc();
    final schedule = await _scheduleInForce(mosqueId, now);
    if (enabled && !schedule.jumuah.isConfigured) {
      throw ReminderWithoutIqamaException(Prayer.dhuhr);
    }
    final updated = schedule.copyWith(
        jumuah: schedule.jumuah.copyWith(reminderEnabled: enabled), updatedAt: now);
    await _db.transaction(() => _saveSchedule(mosqueId, updated));
    return updated;
  }
```

Repository tests: set and read back Jumu'ah; clearing keeps Dhuhr; reminder without a time throws; a new mosque reads Jumu'ah unset.
- [ ] **Step 7: Run** `flutter test test/domain test/data test/drift` → pass.
- [ ] **Step 8: Commit** "Jumu'ah time per mosque (schema v4)".

---

### Task 4: Planner — extra-time alerts and Friday's Jumu'ah

**Files:**
- Modify: `lib/src/domain/notification_plan.dart`, `lib/src/domain/notification_channels.dart`, `lib/src/app/notification_scheduler.dart`, `lib/src/features/settings/scheduled_notifications_page.dart`
- Test: `test/domain/iqama_and_reminders_test.dart` (or the existing planner test file — `grep -l NotificationPlanner test`), `test/domain/notification_channels_test.dart`, `test/app/notification_scheduler_test.dart`

**Interfaces:**
- Consumes: `extraTimesFor`, `ExtraTimeAt`, `ExtraTimesSettings` (Task 1); `Schedule.iqamaOn`, `LocalDay.isFriday` (Task 3).
- Produces: `NotificationKind.extra` (appended last, index 3); `PlannedNotification.extraTime` (`ExtraTime?`) and `PlannedNotification.jumuah` (`bool`, default false); `int extraNotificationId(ExtraTime time, LocalDay day)` = `NotificationKind.extra.index * 1000000 + days * 10 + time.index`; `NotificationPlanInput.extraTimes` (`List<ExtraTimeAt>`, default `const []`, already filtered to alerted ones); `ChannelGroup.extra`; `buildNotificationPlan(..., ExtraTimesSettings extraTimes = const ExtraTimesSettings())`.

- [ ] **Step 1: Failing planner tests:**

```dart
test('extra-time alerts are planned with the reminder sound', () {
  final at = DateTime.utc(2026, 10, 14, 0, 50);
  final plan = const NotificationPlanner().plan(input(
    extraTimes: [ExtraTimeAt(time: ExtraTime.imsak, day: day, at: const LocalTime(230), utc: at)],
    jamaahReminders: const JamaahReminderSettings(sound: ReminderSound.hayya),
  ));
  final n = plan.singleWhere((n) => n.kind == NotificationKind.extra);
  expect(n.extraTime, ExtraTime.imsak);
  expect(n.at, at);
  expect(n.reminderSound, ReminderSound.hayya);
  expect(n.id, extraNotificationId(ExtraTime.imsak, day));
});

test('on a Friday the Jumu\'ah reminder replaces Dhuhr\'s', () {
  // mosque: dhuhr 12:15 reminder on 10 min; jumuah 11:45 reminder on 20 min.
  // day = 2026-10-16 (Friday): one iqama notification for dhuhr at 11:25 local,
  // jumuah == true, minutesBefore 20. Thursday: 12:05 local, jumuah == false.
});

test('Friday without Jumu\'ah still reminds at the Dhuhr Iqama', () {
  // dhuhr 12:15 reminder on, jumuah unset → Friday reminder at 12:05, jumuah true.
});

test('Friday Dhuhr Adhan is marked Jumu\'ah', () {
  // dhuhr adhan alert enabled → on Friday the adhan PlannedNotification.jumuah is true.
});
```

Channel test: an `extra` notification with `ReminderSound.chime`, vibrate → id `jamaah_extra_chime_vib_c1`, group `ChannelGroup.extra`, sound `ChannelSound.chime`.

Scheduler test: `buildNotificationPlan(... extraTimes: ExtraTimesSettings(alerts: {ExtraTime.qiyam}))` contains 7 `extra` notifications (one per window day) and none for imsak/duha; with an active `InFlightHold` none before `pausedUntil`.

- [ ] **Step 2: Run** → fail.
- [ ] **Step 3: Implement.**
  - `PlannedNotification`: add `this.extraTime, this.jumuah = false` with doc comments ("Extra-time alerts only: which time." / "Friday's Dhuhr: titled Jumu'ah.").
  - `enum NotificationKind { adhan, preAdhan, iqama, extra }` (doc: "and alerts at the extra times the user chose").
  - In `_adhanNotifications`, pass `jumuah: prayer == Prayer.dhuhr && day.isFriday` to both the Adhan (add an optional `bool jumuah = false` parameter to `adhanAlert`, forwarded to the constructor) and the pre-Adhan notification.
  - In `_iqamaNotifications`, replace `final iqama = schedule.iqamaFor(prayer);` with:

```dart
      final resolved = schedule.iqamaOn(day, prayer);
      final iqama = resolved.entry;
```

  and pass `jumuah: resolved.isJumuah`.
  - In `plan()`, after the day loop:

```dart
    for (final e in input.extraTimes) {
      out.add(PlannedNotification(
        id: extraNotificationId(e.time, e.day),
        kind: NotificationKind.extra,
        // The prayer each time leads to or follows, for anything that sorts by it.
        prayer: switch (e.time) {
          ExtraTime.imsak => Prayer.fajr,
          ExtraTime.duha => Prayer.sunrise,
          ExtraTime.qiyam => Prayer.isha,
        },
        at: e.utc,
        soundMode: null,
        mosqueId: '',
        vibrate: input.jamaahReminders.vibrate,
        reminderSound: input.jamaahReminders.sound,
        extraTime: e.time,
      ));
    }
```

  - `extraNotificationId` next to `notificationId`, same day arithmetic.
  - Channels: `enum ChannelGroup { adhan, preAdhan, iqama, extra }`; `channelFor` gets `NotificationKind.extra => _reminderChannel(n, 'extra', ChannelGroup.extra)` — refactor `_iqamaChannel` into `_reminderChannel(PlannedNotification n, String prefix, ChannelGroup group)` and call it with `('iqama', ChannelGroup.iqama)` so existing ids are unchanged.
  - `buildNotificationPlan`: add `ExtraTimesSettings extraTimes = const ExtraTimesSettings()` and pass

```dart
      extraTimes: [
        for (final d in days.take(windowDays))
          for (final e in extraTimesFor(calculator: calculator, day: d, settings: extraTimes))
            if (extraTimes.alerts.contains(e.time)) e,
      ],
```

  and in `_syncOnce` pass `extraTimes: settings.extraTimes`.
  - `notificationText`: dhuhr name becomes `l10n.prayerJumuah` when `n.jumuah` (use `final prayer = n.jumuah ? l10n.prayerJumuah : prayerName(l10n, n.prayer);`), and add

```dart
    NotificationKind.extra => (
      title: extraTimeName(l10n, n.extraTime!),
      body: switch (n.extraTime!) {
        ExtraTime.imsak => l10n.notifImsakBody,
        ExtraTime.duha => l10n.notifDuhaBody,
        ExtraTime.qiyam => l10n.notifQiyamBody,
      },
    ),
```

  - `channelDisplayName`: `ChannelGroup.extra => l10n.channelExtra(reminderSoundName(l10n, c.reminderSound ?? ReminderSound.chime))`.
  - `scheduled_notifications_page.dart`: `NotificationKind.extra => l10n.kindExtra`.
  - `lib/src/app/l10n/prayer_labels.dart`: add

```dart
String extraTimeName(AppLocalizations l10n, ExtraTime time) => switch (time) {
  ExtraTime.imsak => l10n.extraImsak,
  ExtraTime.duha => l10n.extraDuha,
  ExtraTime.qiyam => l10n.extraQiyam,
};

/// [prayerName], except that Friday's Dhuhr is Jumu'ah.
String prayerNameOn(AppLocalizations l10n, Prayer prayer, LocalDay day) =>
    prayer == Prayer.dhuhr && day.isFriday ? l10n.prayerJumuah : prayerName(l10n, prayer);
```

  - Strings (EN / AR) — add with one Python script (Task 4 needs them to compile):

| key | EN | AR |
|---|---|---|
| prayerJumuah | Jumu’ah | الجمعة |
| extraImsak | Imsak | الإمساك |
| extraDuha | Duha | الضحى |
| extraQiyam | Last third of the night | الثلث الأخير من الليل |
| notifImsakBody | Imsak: stop eating before Fajr. | الإمساك: أمسك عن الطعام قبل الفجر. |
| notifDuhaBody | The time for Duha prayer has begun. | دخل وقت صلاة الضحى. |
| notifQiyamBody | The last third of the night has begun. | دخل الثلث الأخير من الليل. |
| channelExtra (sound) | Other times · {sound} | أوقات أخرى · {sound} |
| kindExtra | Extra time | وقت إضافي |

  Then `flutter gen-l10n` and `python tool/gen_arabic_digits.py`.
  - Check the native side does not switch on the kind name: `grep -rn "\"kind\"\|iqama\|preAdhan" android/app/src/main/kotlin` — the payload's `kind` must stay informational; if Kotlin branches on it, treat `extra` like `iqama`.
- [ ] **Step 4: Run** `flutter test` (whole suite; the exhaustive switches surface anything missed) → pass.
- [ ] **Step 5: Commit** "Plan extra-time alerts and Friday's Jumu'ah".

---

### Task 5: Settings → Extra times page

**Files:**
- Create: `lib/src/features/settings/extra_times_page.dart`
- Modify: `lib/src/features/settings/settings_page.dart` (a row in the prayer-times section, after `PrayerTimesSettingsSection`), `lib/src/app/l10n/app_en.arb`, `tool/arabic_strings.py`
- Test: `test/features/settings/extra_times_page_test.dart`

**Interfaces:**
- Consumes: `ExtraTimesSettings`, `SettingsRepository.saveExtraTimes`, `appSettingsProvider`, `extraTimeName`, `notificationPermissionRequestProvider`.
- Produces: `Future<void> openExtraTimes(BuildContext context)`; `class ExtraTimesPage`.

- [ ] **Step 1: Failing widget tests** (pattern: `test/features/onboarding_test.dart`'s `open` helper with `appDatabaseProvider` over an in-memory db and `notificationPermissionRequestProvider` counting asks):
  - Settings shows a row "Extra times" with summary "Imsak" (shown names, or "Off" when none); tapping opens the page.
  - Switching "Show on Today" for Duha saves `shown` containing duha.
  - Switching Qiyam's "Alert" on saves `alerts` containing qiyam and asks for notification permission once.
  - The Imsak minutes row opens a sheet of choices 0, 5, 10, 15, 20; picking 5 saves `imsakMinutes == 5`. Duha: 10, 15, 20, 25, 30.
  - Arabic at text scale 2.0: no exception.
- [ ] **Step 2: Run** → fail.
- [ ] **Step 3: Implement.** Page layout (same widgets as `settings_page.dart`: `AppSectionHeader`, `AppRows`, `SwitchListTile`, `AppRow` + `_TwoLines`-style title):
  - Intro text `extraTimesIntro`.
  - Per `ExtraTime` a section header with `extraTimeName`, the rule line (`extraImsakRule(minutes)` / `extraDuhaRule(minutes)` / `extraQiyamRule`) as a tappable `AppRow` for Imsak and Duha (opens a `RadioListTile<int>` sheet like `_chooseTheme`), plain text for Qiyam, then two `SwitchListTile`s `extraShowOnToday` and `extraAlert` (alert subtitle `extraAlertHint`: uses the Jama’ah reminder sound).
  - Saving: `ref.read(settingsRepositoryProvider).saveExtraTimes(current.copyWith(...))`; on alert switched on, `await ref.read(notificationPermissionRequestProvider)()`.
  - Settings row: `AppRow(onTap: () => openExtraTimes(context), title: _TwoLines(first: l10n.settingsExtraTimes, second: <shown names joined with '، '/', ' or l10n.extraNoneShown>))`.
  - Strings:

| key | EN | AR |
|---|---|---|
| settingsExtraTimes | Extra times | أوقات إضافية |
| extraTimesIntro | Times beside the five prayers, worked out from your prayer times. They have no Iqama. | أوقات إلى جانب الصلوات الخمس، تُحسب من مواقيت صلاتك. ولا إقامة لها. |
| extraShowOnToday | Show on Today | إظهار في صفحة اليوم |
| extraAlert | Alert | تنبيه |
| extraAlertHint | Uses your Jama’ah reminder sound. | يستخدم صوت تذكير الجماعة. |
| extraImsakRule (int minutes) | {minutes} min before Fajr | `minutes('minutes', after=' قبل الفجر')` |
| extraDuhaRule (int minutes) | {minutes} min after sunrise | `minutes('minutes', after=' بعد الشروق')` |
| extraQiyamRule | The last third of the time from Maghrib to Fajr. | الثلث الأخير من الوقت بين المغرب والفجر. |
| extraNoneShown | None shown | لا شيء معروض |

  Regenerate l10n + digits.
- [ ] **Step 4: Run** the page tests and `test/l10n` → pass. `dart format` the new files.
- [ ] **Step 5: Commit** "Settings: Extra times".

---

### Task 6: Today — extra-time rows

**Files:**
- Modify: `lib/src/app/providers.dart` (provider), `lib/src/features/today/today_screen.dart`
- Test: `test/features/today/extra_times_rows_test.dart`

**Interfaces:**
- Consumes: `extraTimesForToday`, `extraTimeName`, `appSettingsProvider`, `prayerTimesCalculatorProvider`, `todayProvider`.
- Produces: `final todayExtraTimesProvider = Provider<List<ExtraTimeAt>>(...)` (empty when no calculator/reading).

- [ ] **Step 1: Failing widget tests** (use the Today test setup in `test/features/today/` with `FixedClock`):
  - Defaults at Kuwait 12:00: a row "Imsak" with Fajr − 10 shown directly above the Fajr row (check vertical order via `tester.getTopLeft`); no Duha/Qiyam rows.
  - Shown {duha, qiyam}: Duha row between Sunrise and Dhuhr; "Last third of the night" row after Isha.
  - At 02:00 local, the Qiyam row shows the night in progress's time (equal to `extraTimesFor(day: yesterday)`'s Qiyam formatted).
  - The hero card's next prayer is never an extra time (at Imsak − 5 min, next is still Fajr).
  - Arabic: rows show Arabic names and Arabic-Indic digits.
- [ ] **Step 2: Run** → fail.
- [ ] **Step 3: Implement.** Provider:

```dart
/// The extra times Today lists (2026-10-14), from the place's reading.
final todayExtraTimesProvider = Provider<List<ExtraTimeAt>>((ref) {
  final calculator = ref.watch(prayerTimesCalculatorProvider);
  final today = ref.watch(todayProvider);
  if (calculator == null || today == null) return const [];
  final settings = ref.watch(appSettingsProvider.select((s) => s.value?.extraTimes)) ??
      const ExtraTimesSettings();
  return extraTimesForToday(calculator: calculator, moment: today.moment, settings: settings);
});
```

  `_PrayerRows` takes `extras: List<ExtraTimeAt>` (passed from `TodayScreen` via `ref.watch(todayExtraTimesProvider)`) and builds children by walking `Prayer.adhanPrayers`, inserting `_ExtraRow`s: Imsak before Fajr, Duha after Sunrise, Qiyam after Isha:

```dart
  List<Widget> _rows(...) => [
    for (final prayer in Prayer.adhanPrayers) ...[
      if (prayer == Prayer.fajr) ..._extra(ExtraTime.imsak),
      _PrayerRow(...existing...),
      if (prayer == Prayer.sunrise) ..._extra(ExtraTime.duha),
      if (prayer == Prayer.isha) ..._extra(ExtraTime.qiyam),
    ],
  ];
```

  `_ExtraRow`: an `AppRow(muted: true, leading: <same 8px transparent dot slot>, title: Text(name, style: 12–13px muted), trailing: Text(clock.time(at), muted))` — quieter than Sunrise; no Iqama, no bell, never `selected`/`isNext`.
- [ ] **Step 4: Run** Today tests + the new file → pass.
- [ ] **Step 5: Commit** "Today: extra-time rows".

---

### Task 7: Jumu'ah on Today and on the mosque page

**Files:**
- Modify: `lib/src/domain/today.dart` (`readNextIqama`, `IqamaUpcoming`), `lib/src/features/today/today_screen.dart`, `lib/src/features/mosques/mosque_detail_page.dart`, `lib/src/features/mosques/iqama_editor_sheet.dart`, ARB + `tool/arabic_strings.py`
- Test: `test/domain/today_test.dart`, `test/features/today/jumuah_test.dart`, `test/features/mosques/` (the existing Iqama editing test file)

**Interfaces:**
- Consumes: `Schedule.iqamaOn`, `DayIqama`, `prayerNameOn`, `MosqueRepository.setJumuah`, `setJumuahReminderEnabled`.
- Produces: `IqamaUpcoming.isJumuah`, `IqamaUpcoming.jumuahNotSet` (both `bool`, default false); `showIqamaEditor(..., bool jumuah = false)`.

- [ ] **Step 1: Failing tests.**
  - Domain (`today_test.dart`): on Friday 2026-10-16 at 10:00 with dhuhr 12:15 and jumuah 11:45 → `IqamaUpcoming(prayer: dhuhr, at: 11:45, isJumuah: true)`; without jumuah → at 12:15, `jumuahNotSet: true`; Thursday → `isJumuah: false`.
  - Today widget (place date Friday): the Dhuhr row is titled "Jumu’ah" and shows the Jumu'ah Iqama; the hero card says "Jumu’ah …" when next; with no Jumu'ah time the card shows the `jumuahNotSetNote`. Thursday: "Dhuhr". Also a case where the phone's date is Thursday but the place's date is Friday (zone far east, e.g. `Pacific/Kiritimati` vs `FixedClock` UTC Thursday evening) → Jumu'ah.
  - Mosque page: a "Jumu’ah" row below Isha, "Not configured"; tapping opens the editor titled for Jumu'ah, the picker starts at Dhuhr's Adhan; Save writes via `setJumuah` (read back `schedule.jumuah.iqama`); its switch toggles `setJumuahReminderEnabled`.
- [ ] **Step 2: Run** → fail.
- [ ] **Step 3: Implement.**
  - `readNextIqama`: inside the loop use `final resolved = todaySchedule?.iqamaOn(moment.day, prayer); final entry = resolved?.entry;` and pass `isJumuah: resolved!.isJumuah, jumuahNotSet: resolved.jumuahNotSet`; `anythingEntered` also counts `todaySchedule?.jumuah.isConfigured`.
  - `_PrayerRows`: name via `prayerNameOn(l10n, prayer, today.day.day)`; `_iqama`/`reminderOn` via `schedule?.iqamaOn(today.day.day, prayer).entry`.
  - `_HeroCard`: Adhan line uses `prayerNameOn(l10n, next.prayer, next.on)`; Iqama line uses `iqama.isJumuah ? l10n.prayerJumuah : prayerName(...)`, and when `iqama.jumuahNotSet` adds `Text(l10n.jumuahNotSetNote, style: _heroLabel)` under it.
  - `mosque_detail_page.dart`: after the five `_IqamaRow`s add a `_IqamaRow` variant for Jumu'ah — give `_IqamaRow` a `bool jumuah = false` field: name `l10n.prayerJumuah`, hint line `l10n.jumuahRowHint` under the name, `adhan` = today's Dhuhr Adhan, editor opened with `jumuah: true`, switch calls `setJumuahReminderEnabled`.
  - `iqama_editor_sheet.dart`: `bool jumuah` on `showIqamaEditor`/`IqamaEditorSheet`; title label `jumuah ? l10n.prayerJumuah : prayerName(...)`; `_save`/`_clear` call `setJumuah(mosqueId, time, reminderEnabled:, reminderMinutesBefore:)` when `jumuah`.
  - Strings:

| key | EN | AR |
|---|---|---|
| jumuahNotSetNote | Jumu’ah time not set · showing Dhuhr Iqama | لم يُحدَّد وقت الجمعة · يُعرض وقت إقامة الظهر |
| jumuahRowHint | Fridays, in place of Dhuhr | يوم الجمعة بدلًا من الظهر |

- [ ] **Step 4: Run** `flutter test` (whole suite) → pass.
- [ ] **Step 5: Commit** "Jumu'ah on Today and on the mosque page".

---

### Task 8: Device check, docs, report

**Files:**
- Modify: `README.md` (features), `AGENTS.md` (data model: Schedule has a Jumu'ah entry; Prayer times: extra times), `docs/arabic-strings-review.md` (regenerated by `tool/arabic_strings.py`), `docs/user-guide/` (new `extra-times-and-jumuah.md`, in the style of `in-flight-mode.md`)
- Memory: `project-state-and-next-step.md`

- [ ] **Step 1:** `flutter analyze` → no issues; `flutter test` → all pass (record the count).
- [ ] **Step 2:** `flutter build apk --debug --dart-define-from-file=.env`, install, and on the phone: Settings → Extra times (switch Duha/Qiyam on), Today shows the rows in order; set a Qiyam/Imsak alert a few minutes ahead by temporarily choosing minutes so it falls soon, or use the Scheduled notifications page to confirm the `extra` entries exist; add a Jumu'ah time on the active mosque and confirm the row. Restore every setting changed for the test (extra times back to defaults, Jumu'ah cleared unless the user wants it).
- [ ] **Step 3:** Docs as listed; commit "Docs: extra times and Jumu'ah".
- [ ] **Step 4:** Discord report via the PowerShell tool (`report.ps1`, real test counts), update memory.
