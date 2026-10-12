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

## Branding

`branding.yaml` is the single source of truth for the app name and application id.

```bash
dart run tool/sync_branding.dart           # regenerate lib/src/app/branding.g.dart and the Android config
dart run tool/sync_branding.dart --check   # fail if out of date
```

`flutter test` also asserts the generated files still match the YAML.

## Tests

```bash
flutter test       # 73 tests: prayer times, iqama/reminder math, qibla, notification planning
flutter analyze
```

Prayer-time fixtures are pinned against the Aladhan API, used **only** as a dev-time test oracle — the app never calls it. The fixtures were fetched with `latitudeAdjustmentMethod=1` (middle of the night) so the comparison is against the same astronomical definition `adhan_dart` implements.

## Adhan audio

The MVP ships a clearly marked **generated placeholder tone** so the sound plumbing can be exercised. Replace `assets/audio/` with a properly licensed recording and record its source and licence in `docs/audio-licence.md`.

## Not yet built

Nothing ships until its step is done; the remaining build order is Today screen → mosque and Iqama → discovery → notifications and sound → Settings → Qibla.
