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

**Generated files are committed.** `*.g.dart` (drift, branding),
`drift_schemas/app/drift_schema_v*.json`, `lib/src/data/app_database.steps.dart` and
`test/drift/app/` (the generated migration test) are in the repo, so a fresh clone builds,
tests and runs with nothing but `flutter pub get`. CI does not have to run
codegen, and the diff of a schema change is reviewable.

Regenerate after editing drift tables:

```bash
dart run build_runner build          # rewrites lib/src/data/app_database.g.dart
dart run drift_dev make-migrations   # exports drift_schema_v<N>.json, steps + test/drift/app
```

Both are needed when `schemaVersion` changes. The schema is at **v2** (v1 + the
per-prayer notification columns); v1 reached a device, so v2 is a real
`stepByStep` migration, and `test/drift/app/migration_test.dart` checks that a v1
database with mosques, Iqama times and alerts comes through intact.

## Storage

`lib/src/data/app_database.dart` holds the drift schema: settings, per-prayer
Adhan alerts and offsets, mosques, Iqama schedules. Sunrise cannot get an Iqama
time — a CHECK constraint in `schedule_prayers` and a guard in `MosqueRepository`
both enforce it. Deleting a mosque clears the active-mosque setting in the same
transaction, so reminders never point at a mosque that is gone.
The first mosque saved becomes the active one when none is active (as in the
prototype); a later one never takes over. A reminder can only be switched on for a
prayer with an Iqama time, and its interval is 1–120 minutes. `watchSaved()` re-emits
on any mosque, schedule or Iqama change, so Today follows an edit immediately.

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
- Bottom navigation: Today / Mosques / Qibla, plus the gear from the prototype.
  Qibla is not built yet and says so instead of showing fake content. The "Add your
  mosque" prompt opens the Mosques tab; "tap to set" opens that mosque's schedule.
- The minute ticker runs in the foreground only; on resume the day is re-read, so a
  launch after midnight shows the new one.


## Mosques and Iqama times

- The Mosques tab lists saved mosques with an **Active** tag and how much of the
  schedule is entered ("Iqama set", "2 of 5 Iqama set", "Iqama not configured").
  There is no sample data. "Find nearby mosques" is visible but disabled until the
  discovery step.
- **Add a mosque manually** needs a name; the address is optional. The new mosque
  opens with every Iqama time "Not configured", and the first one saved becomes
  active, as in the prototype.
- A mosque's page lists Fajr, Dhuhr, Asr, Maghrib and Isha (never Sunrise). Each row
  shows the day's Adhan time as a small secondary line and the mosque's Iqama time or
  "Not configured", plus a quick reminder switch that stays disabled until a time
  exists. "Set by you · last updated <date>" comes from the injected clock.
- The **Iqama editor** names the mosque and prayer, uses the device's time picker
  (12/24-hour from the system), and saves nothing until Save. An Iqama not entered
  yet reads "Adhan 5:36 AM · tap to set" and the picker opens at that Adhan time —
  a starting point only; Save still waits for the user to confirm a time. Reminders are 5, 10 or
  15 minutes or Custom (whole minutes 1–120). The live summary reads "Maghrib ·
  6:30 PM Iqama · Reminder at 6:20 PM", and says "before midnight" when the reminder
  falls on the evening before an after-midnight Iqama. Clear returns the prayer to
  "Not configured".
- Iqama reminders are scheduled as notifications (see Notifications below).
- Removing a mosque asks first. Removing the active one leaves no mosque active.
- Today follows every change at once: `MosqueRepository.watchSaved()` re-reads on
  drift's table-update notifications for mosques, schedules and Iqama entries.

## Finding mosques nearby

- **Mosques → Find nearby mosques** explains first, then asks for **precise**
  location (Android lets the user keep it approximate; the search still runs and
  says the list may be a few km off). **Search around a city** uses the bundled
  list and needs no permission. Today's "where are you?" asks for approximate
  location only: both levels go through `LocationPermissions` (MainActivity),
  because geolocator's own request would offer precise at the first prompt.
- The provider is `DISCOVERY_PROVIDER` in `.env` (`google` by default, or `osm`).
  Build with the key: `flutter run --dart-define-from-file=.env`. A build without
  it reports "not set up" and offers OpenStreetMap or adding by hand.
- Google: Places API (New) Nearby Search, 5 km, nearest first, field mask
  `places.id,places.displayName,places.formattedAddress,places.location` only. The
  app sends `X-Android-Package` and `X-Android-Cert`, the SHA-1 read from the
  installed APK, so a key restricted to the app works for any signing key.
- OpenStreetMap: Overpass, `amenity=place_of_worship` + `religion=muslim`. Unnamed
  places are listed as "Unnamed mosque" and must be named before saving.
- `DiscoverySession` reuses answers within 150 m, shares a search in flight, and
  allows 10 network calls per app session; each answer is logged with its provider.
- Results are labelled by source and "not verified". Saving asks the user to confirm
  the name and address. A Google mosque keeps its place id but **not** its
  coordinates (Google allows caching those for 30 days only); an OpenStreetMap
  mosque keeps both.

## Prayer-time settings

Settings → Prayer times: the **calculation method** (Auto detect from the place's
time zone, Custom angles, and 23 published methods, each listed with its angles and
regions read from the parameters the calculator uses), the **Asr method**
(Standard / Hanafi), the **higher-latitude rule**, and **manual adjustments** of up to
±30 minutes per prayer. Every change recomputes Today and reschedules notifications.

## Notifications

- Three independent kinds: **Adhan alerts** and optional **reminders before the
  Adhan** (global, per prayer, sunrise included) and **Iqama reminders** (the active
  mosque only). Iqama reminders can be paused by hand, per mosque or all at once;
  Adhan alerts never pause.
- `buildNotificationPlan` makes a 7-day plan from the saved place (its own zone,
  DST-aware), the settings and the active mosque. `NotificationSync` makes the
  phone's scheduled set match it exactly: future items only, stale ones cancelled,
  stable ids so a re-run never duplicates. `NotificationScheduler` re-syncs on start,
  on resume, and whenever settings, mosques, Iqama times, the place or the day
  change.
- Android channels fix their sound at creation, so the channel id encodes sound
  mode, vibration, alarm volume and the tone version (`notification_channels.dart`);
  unused app channels are retired. Silent is its own channel, shown with no sound.
- Notification permission is asked for when the user turns a reminder or alert on.
  Exact alarms: when Android denies them, timing falls back to inexact and the app
  says so. **Gear → Scheduled notifications** lists what the phone has actually
  scheduled, with both permissions and battery guidance.
- **Gear → Settings → Appearance**: the theme (same as the phone, light or dark).
- **Gear → Settings**: the default sound, and a page per prayer (Adhan alert,
  sound with preview, vibrate, ring in silent, reminder before the Adhan, a test
  notification). Changes save at once. Iqama reminders are only linked to the
  active mosque, never edited here. **Pause all Iqama reminders** lives here too;
  Today and the mosque page say when reminders are paused.
- The **full Adhan** and any **full-screen Adhan** are played by the app itself,
  not as a notification sound: native `AdhanAlarms` (stored exact alarms, restored
  after a reboot), `AdhanService` (foreground media playback on the notification
  volume, or the alarm volume when "ring in silent" is on; vibrates; stops on the
  notification's Stop, the volume keys, or the phone turned face down) and
  `AdhanActivity` (a plain native page over the lock screen with a large Stop).
  When it ends, a normal notification stays. Android 14+ can withhold full-screen
  alerts; Settings then says so and links to the permission.
- **Short Adhan** (Settings → Short Adhan): the opening of Naghshbandi, or «حيّ على
  الصلاة» (1:09–1:19 of `audio_sources/حي على الصلاه.mp3`). The clip is also the channel
  sound of a full Adhan's notification.
- **Jama’ah reminders** (Settings → Jama’ah reminders): the app's own chime by default,
  or «حيّ على الصلاة», or the phone's standard sound, or silent; vibrate on or off; a test reminder. Each
  combination is its own channel (`iqama_<sound>_<vib>_c<chime version>`). The
  reminder's title is «حيّ على الصلاة», with the prayer, minutes and mosque under it.
- **Settings → Full Adhan recording** chooses one of 17 bundled recordings, each
  playable there first (`adhan_recordings.dart`). The short Adhan is the first 8 s
  of Naghshbandi. Provenance: `docs/audio-licence.md`.

## Travel

- **Travel mode** is one switch: the airplane beside the gear on the top bar, or
  Settings → Travel. It turns on the travel options listed under it in Settings
  (today only Follow my location; on by default). A user who already followed their
  location starts with travel mode on.
- **Follow my location** (a travel-mode option): each time the app opens or comes back,
  it reads the device's coarse location **without asking** (the permission is asked
  only when the switch is turned on) and replaces the saved place when the phone is
  more than 10 km away or in another time zone (`place_follow.dart`). The place,
  "today" and every scheduled notification follow. Today shows "Following your
  location · updated 2 h ago", or says plainly when it could not update and the
  last place is in use.
- **Pausing Iqama reminders** is manual. Each mosque's page has **Pause this
  mosque's reminders** (kept on the mosque, so it applies whenever that mosque is
  the active one, and switching to another mosque brings that mosque's reminders
  back); Settings has **Pause all Iqama reminders**. Iqama times and reminder
  settings are kept either way, and Adhan alerts never pause. This replaced the
  earlier travel-mode pause (a pause made there reads as "Pause all").
- **Time zone from where you are:** a place read from the device ("Use my location",
  Follow my location) takes its zone from its coordinates, through a time-zone map
  bundled in the app (`lat_lng_to_timezone`, MIT; `domain/zone_lookup.dart`), not from
  the phone's clock setting. So the phone never has to be set to the local zone. If the
  map's answer is unknown, the phone's zone is used.
- When the place's clock and the phone's differ, Today says so: "Times are local time in
  London (UTC+1). Your phone's clock is on UTC+3." Notifications always fire at the
  right moment either way; only the clock they are shown against differs.
- **In flight** (phase 1; plan in `docs/in-flight-mode.md`): with travel mode on, Today
  shows "On a flight?". The screen reads GPS from the platform's location manager (works
  in airplane mode, no network), only while open and only after the user starts it, and
  shows: the prayer now and the next one (countdown and time on the phone's clock), with
  sunrise and Maghrib as seen from the aircraft (horizon dip at altitude,
  `domain/in_flight.dart`); the day's times aboard; and the Qibla relative to the
  aircraft's nose from the GPS course, or a heading typed in from the seat-back map. The
  phone's compass is not used aboard.
- **In flight, phase 2:** while moving, the next prayers are projected along the current
  course and speed ("Along this route: Maghrib, in 1 h 40 m"), stepping the point forward
  and finding where the prayer period changes (`projectAlongRoute`, run off the UI
  thread). The screen also sets an `InFlightHold`: regular notifications for the last
  place are held, and the next projected prayer is alerted as that prayer's Adhan alert
  is set up, saying it is estimated. The hold ends on its own 90 minutes after the last
  GPS fix, or with "End in-flight mode" (on the screen or on Today).
- **User guide:** the ? on the in-flight screen opens "How it works" (English and
  Arabic, works offline). The same text is in `docs/user-guide/in-flight-mode.md`,
  generated from the strings by `tool/user_guide.py`.
- **Preview another city** (location sheet): any city's times for today, without
  moving the saved place or touching notifications.

## Hijri date

- Settings → Prayer times → **Hijri date**: move the Hijri date by up to two days either
  way (`domain/hijri.dart`), to match countries such as Kuwait that start months by moon
  sighting. Each choice is shown as the date it gives. It moves Today's Hijri line and,
  with Umm al-Qura, the days that get Ramadan's 120-minute Isha; nothing else.

## Languages

- **English and Arabic** (Settings → Language: the phone's, English or العربية). Changes
  apply at once, notifications included; Arabic is right to left.
- Strings live in `lib/src/app/l10n/app_en.arb` (the template) and `app_ar.arb`, which is
  built by `tool/arabic_strings.py` (Arabic counting forms come from helpers there). After
  changing strings:

  ```
  python tool/arabic_strings.py && flutter gen-l10n && python tool/gen_arabic_digits.py
  ```

- Arabic shows Arabic-Indic digits (٠١٢٣): dates and times are formatted with intl's
  `ar_EG` data (plain `ar` gives Western digits; there is no `ar_KW`), and every Arabic
  string passes through `arabicDigits()` via the generated `AppLocalizationsArDigits`. A
  number with a degree sign is kept as one left-to-right unit so the sign stays after it.
- The Arabic is a first draft by the coding agent, to be reviewed before release.

## Qibla

- The bearing is the great-circle bearing from the saved place to the Kaaba
  (`domain/qibla.dart`), worked out on the device and shown whether or not there is a
  compass, with the distance.
- The dial turns with the phone (`flutter_compass`). Android's compass reads magnetic
  north, so the heading is corrected to true north with the declination from Android's
  World Magnetic Model (`GeomagneticField`, method channel `dev.jamaah.app/compass`,
  offline); the screen says which north it is measuring from.
- Within 3° it says "Facing the Qibla" with one light haptic tap. Low compass accuracy
  shows a calibration note with figure-8 instructions. A compass that says nothing for
  3 s is treated as missing: the bearing stays, with how to use it with any compass.
- The compass only runs while the Qibla tab is open.

## Tests

```bash
flutter test       # 501 tests: prayer times, today-in-zone and iqama/reminder math, qibla,
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
the placeholder city list), the Today screen with its bottom navigation, and the
Mosques tab with the Iqama editor. The remaining build order is discovery →
notifications and sound → Settings → Qibla. Qibla and Settings currently show honest
"comes later" states, and "Find nearby mosques" is disabled until discovery.
