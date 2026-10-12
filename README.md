# Awqaity

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

## Tests

```bash
flutter test       # 111 tests: prayer times, iqama/reminder math, qibla, notification planning, storage
flutter analyze
```

Prayer-time fixtures are pinned against the Aladhan API, used **only** as a dev-time test oracle — the app never calls it. The fixtures were fetched with `latitudeAdjustmentMethod=1` (middle of the night) so the comparison is against the same astronomical definition `adhan_dart` implements.

## Adhan audio

Not in the app yet: `assets/audio/` is created in the notifications-and-sound step,
which ships a clearly marked **generated placeholder tone** so the sound plumbing can
be exercised. See `docs/audio-licence.md` for what must be recorded before a real
recording replaces it.

## Not yet built

Nothing ships until its step is done. Built so far: the domain layer and the drift
storage layer with its repositories. The remaining build order is Today screen →
mosque and Iqama → discovery → notifications and sound → Settings → Qibla. The
mosque and Iqama step writes through `MosqueRepository`, which is already tested.
