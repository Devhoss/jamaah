# Jama’ah

A minimal Muslim prayer companion. Know when to pray, know when your mosque starts, get reminded on time.

Flutter, **Android only** for now (iOS is deferred — see AGENTS.md). Offline-first.

## Principles that shape the code

- **Adhan times and Iqama times are separate concepts** — in the data model, the code and the UI.
- **Iqama times belong to a mosque** and are always entered by the user. A new mosque starts with every Iqama time "Not configured" — the app never invents a default, and never derives one from Adhan times.
- Sunrise is shown, but never has an Iqama or an Iqama reminder. It may carry an Adhan alert (off by default).
- Nothing unverified is presented as verified.

Read **AGENTS.md** before changing anything — it defines the product rules and overrides any instruction given elsewhere.

## Layout

```
lib/src/domain/   pure Dart: prayer times, qibla, iqama/reminder math, models
lib/src/data/     SQLite, repositories, discovery providers, platform adapters
lib/src/features/ screens and their Riverpod controllers
lib/src/app/      theme, tokens, localization, branding, config
test/             domain unit tests and widget tests
tool/             build helpers (branding sync)
docs/             design reference (docs/prayer-prototype.html)
```

Dependencies point one way: `features → data → domain`. The domain layer imports no Flutter, which is why prayer times, Qibla and reminder math are tested without a device.

## Setup

```bash
flutter pub get
cp .env.example .env          # then fill in the Places key, if you have one
flutter gen-l10n              # or `flutter build`, which does it for you
```

Run with the environment file so discovery is configured:

```bash
flutter run --dart-define-from-file=.env
```

`.env` is git-ignored. Keys never go in source. `DISCOVERY_PROVIDER` selects `google` (default) or `osm`.

**Machine-specific Gradle workarounds are not committed.** If a build fails inside
the NDK, it is usually because `flutter.ndkVersion` points at an SDK package that
is only partially installed on that machine. Fix it locally by setting
`ndkVersion = "<an installed NDK>"` in `android/app/build.gradle.kts` (check
`<sdk>/ndk/` for what is there) — the app has no native code, so any recent NDK
works. Do not commit that edit. Likewise, if Kotlin's incremental compilation
fails to close its caches, put `kotlin.incremental=false` in
`~/.gradle/gradle.properties`, never in `android/gradle.properties`.

## Branding

`branding.yaml` is the single source of truth for the app name and application id.

```bash
dart run tool/sync_branding.dart           # regenerate lib/src/app/branding.g.dart and the Android config
dart run tool/sync_branding.dart --check   # fail if out of date
```

`flutter test` also asserts the generated files still match the YAML.

## Generated code — policy

**Generated files are committed.** `*.g.dart` (drift, branding) and
`drift_schemas/app/drift_schema_v*.json` are in the repo, so a fresh clone builds,
tests and runs with nothing but `flutter pub get`. CI does not have to run
codegen, and the diff of a schema change is reviewable.

Regenerate after editing drift tables:

```bash
dart run build_runner build          # rewrites lib/src/data/app_database.g.dart
dart run drift_dev make-migrations   # exports drift_schemas/app/drift_schema_v<N>.json
```

Both are needed when `schemaVersion` changes; `test/data/migration_test.dart`
fails if the exported snapshot is missing, and documents the steps for adding a
real migration.

## Storage

`lib/src/data/app_database.dart` holds the drift schema: settings, per-prayer
Adhan alerts and offsets, mosques, Iqama schedules. Sunrise cannot get an Iqama
time — a CHECK constraint in `schedule_prayers` and a guard in `MosqueRepository`
both enforce it. Deleting a mosque clears the active-mosque setting in the same
transaction, so reminders never point at a mosque that is gone.

## Location

Prayer times need a place, and a place needs three things: coordinates, an IANA
time zone, and a label. The app gets them two ways, in this order:

1. **The device, coarse only.** `DevicePlaceSource` asks for
   `ACCESS_COARSE_LOCATION` at city level, after the explanation sheet — the
   permission dialog is never the first thing a user sees. The time zone comes from
   `flutter_timezone`, so the stored place is DST-correct rather than a fixed offset.
2. **The bundled list.** `lib/src/domain/placeholder_places.dart` is a labelled
   placeholder: roughly 95 cities with a wide regional spread, chosen so the app
   works with no network, no account and no permission. `test/domain/place_list_test.dart`
   fails if any zone name is missing from the time zone database or any expected
   offset is wrong, because a silent typo there shifts every prayer time.

Denied, permanently denied (with a link to the app's system settings), location
services off, timeout, or any other platform failure: each shows its own calm
message and keeps "Choose a city" in reach. Nothing falls through silently. The
chosen place is stored in settings, and whichever way it arrived, that one stored
record is what every later screen reads.

Fine location is deliberately not requested yet — it belongs to nearby-mosque
search. `test/manifest_test.dart` guards the manifest so a later step
cannot pick up a permission by accident.

## Today

The first screen the user sees, and the only one that reads the stored place.

- "Today" is the calendar date **in the saved place's zone**, not the device's. A
  device on another continent still shows the right day for Cairo. DST days and the
  day's rollover at the place's own midnight are covered by `test/domain/today_test.dart`.
- The hero card shows the next prayer, its Adhan time and a countdown. After Isha the
  next prayer is **tomorrow's Fajr**; between midnight and Fajr the prayer still in
  effect is **yesterday's Isha**.
- Under it, the mosque's **next Iqama is the earliest one still ahead**, whatever
  prayer it belongs to — a Maghrib jama'ah ten minutes away is the next Iqama even
  though the Adhan in front of the user is Isha's. When the day's entered times have
  all run out the card shows tomorrow's Fajr Iqama labelled "Tomorrow", or "No more
  Iqama times today." if that is not configured either. A mosque with nothing entered
  is a different answer from a day that has finished, and is never filled in.
- Six rows, sunrise muted, the current prayer highlighted, the next one distinct. An
  Iqama line appears on a row **only when that mosque has one configured** — an
  unconfigured prayer says so and never shows or implies a time (AGENTS.md).
- Adhan and Iqama are visibly separate: the row's Iqama belongs to the mosque, the
  Adhan time does not. The reminder bell reports the *setting's* state only;
  notifications are not built yet, and nothing here claims a schedule exists.
- A time the high-latitude rule moved is annotated; a day it cannot compute (polar)
  is a calm message, not a blank screen.
- Bottom navigation: Today / Mosques / Qibla, plus the gear from the prototype. The
  two unbuilt tabs say so instead of showing fake content.
- The minute ticker runs in the foreground only; on resume the day is re-read, so a
  launch after midnight shows the new one.

## Tests

```bash
flutter test       # 244 tests: prayer times, today-in-zone and iqama/reminder math, qibla,
                   # notification planning, storage, the placeholder city list, the location
                   # flow, the Today screen, the app shell, the manifest guard
flutter analyze
```

`test/README.md` explains the layout and the one drift-specific gotcha that makes a
widget test look like it hangs.

Prayer-time fixtures are pinned against the Aladhan API, used **only** as a dev-time test oracle — the app never calls it. The fixtures were fetched with `latitudeAdjustmentMethod=1` (middle of the night) so the comparison is against the same astronomical definition `adhan_dart` implements.

## Adhan audio

Not in the app yet: `assets/audio/` is created in the notifications-and-sound step,
which ships a clearly marked **generated placeholder tone** so the sound plumbing can
be exercised. See `docs/audio-licence.md` for what must be recorded before a real
recording replaces it.

## Not yet built

Nothing ships until its step is done. Built so far: the domain layer, the drift
storage layer with its repositories, the location flow (device coarse location plus
the placeholder city list), and the Today screen with its bottom navigation. The
remaining build order is mosque and Iqama → discovery → notifications and sound →
Settings → Qibla. The mosque and Iqama step writes through `MosqueRepository`, which
is already tested; Mosques and Qibla currently show honest "comes next" states.
