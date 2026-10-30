# Jama’ah

<p align="center">
  <img src="docs/app-icon.png" alt="Jama’ah app icon" width="160" />
</p>

A calm, offline-first prayer companion for knowing when to pray, when your
Iqama starts, and when to leave. The app is built with Flutter for Android.
iOS is deferred.

## What it does

- Computes prayer times on the device for the saved place, using its time zone.
- Keeps each mosque’s Iqama schedule separate from Adhan times. Iqama times are
  entered by the user; new mosques start unconfigured.
- Supports a mosque’s Friday Jumu’ah time and a reminder set before the Khutbah.
- Schedules optional Adhan alerts and Jama’ah reminders locally on the phone.
- Offers full Adhan recordings, short Adhan clips, and Fajr-only recordings.
- Stores settings, mosques, prayer times and schedules on-device. No account or
  custom backend is required.

To choose one of the Fajr-only recordings, open **Settings → Adhan alerts →
Fajr → Sound → Recording**. It applies to Fajr when **Full Adhan** is selected;
other prayers keep their own recording choice or use the shared recording.

## Project guide

`AGENTS.md` contains product rules and architectural constraints. The code is
organized into three layers:

```text
lib/src/domain/    Prayer-time, Iqama, notification and Qibla logic
lib/src/data/      Drift database, repositories and platform adapters
lib/src/features/  Screens and user interactions
lib/src/app/       App shell, theme, localization, notifications and diagnostics
android/           Android notification and Adhan playback services
audio/             Owner-supplied Adhan recordings used by the app
assets/audio/      App-generated Jama’ah reminder chime
test/              Domain, data, app and widget tests
tool/              Branding, localization and release helpers
docs/              Design and source/licence notes
```

The domain layer does not depend on Flutter. Prayer-time calculation, Iqama
math, notification planning and Qibla bearings can be tested without a device.

## Set up

Install the Flutter SDK required by the project and Android SDK/command-line
tools. Then fetch packages and create a local environment file:

```powershell
flutter pub get
Copy-Item .env.example .env
```

Add a restricted Google Places API key to `.env` if nearby mosque discovery
uses Google. `DISCOVERY_PROVIDER` can be `google` or `osm`. Leave
`SENTRY_DSN` empty to keep diagnostics on-device; Sentry reporting is optional
and consent-based. Never commit `.env` or put credentials in source control.

Run the app with:

```powershell
flutter run --dart-define-from-file=.env
```

The app name and Android application ID are defined in `branding.yaml`. After
changing that file, update generated branding with:

```powershell
dart run tool/sync_branding.dart
```

## Tests and localization

Run the complete test suite with:

```powershell
flutter test
```

English and Arabic strings are in `lib/src/app/l10n/app_en.arb` and
`app_ar.arb`. After changing them, regenerate localization and Arabic-digit
wrappers:

```powershell
flutter gen-l10n
python tool/gen_arabic_digits.py
```

## Build an APK

Build a versioned release APK from PowerShell:

```powershell
tool\build_release.ps1
```

The script refuses to run without a `.env` (the release build must be built
with the same dart-defines dev builds use, or mosque discovery and Sentry are
dead), bakes `APP_VERSION` / `GIT_COMMIT` / `BUILD_DATE` in for the About
page, and emits:

```
build/app/outputs/flutter-apk/Jamaah-<version>.apk
build/app/outputs/flutter-apk/Jamaah-<version>.apk.sha256
```

The APK uses the stable ASCII filename `Jamaah-<version>.apk` (for example,
`Jamaah-1.0.5.apk`) for every release, independent of the branded app label.
The `.sha256` sidecar (`<hash>  Jamaah-<version>.apk`, as `sha256sum` writes
it) is what the app's in-app updater verifies a download against; a release
uploaded without it is not offered as a direct update. Both files stay under
the ignored `build/` directory; do not add them to the source commit.

For a public release, create an annotated source tag such as `v1.0.5` on the
release commit, publish the GitHub release with the tag, and attach the APK
and its sidecar:

```powershell
gh release create v1.0.5 --title "1.0.5" --notes "…" `
  build/app/outputs/flutter-apk/Jamaah-1.0.5.apk `
  build/app/outputs/flutter-apk/Jamaah-1.0.5.apk.sha256
```

The app's updater checks `releases/latest` on that repository, so the tag may
carry a `v` prefix (`v1.0.5`); the row shows the version without it.
Prereleases and drafts never surface as updates. Release builds for public
distribution still need an agreed application ID, store listing and signing
key. Confirm audio rights before redistributing the supplied recordings; see
[`docs/audio-licence.md`](docs/audio-licence.md).

## Notifications and diagnostics

Prayer alerts and Jama’ah reminders are scheduled locally. Android permission
and exact-alarm status are shown in the app; denied exact alarms use the
platform’s inexact timing. A diagnostic screen can share on-device logs when a
tester chooses to send them. Error reporting to Sentry is opt-in. The app does
not send prayer schedules, location, analytics, session replay or performance
telemetry.
