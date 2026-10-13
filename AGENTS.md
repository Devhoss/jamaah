# AGENTS.md — Jama’ah

Jama’ah is a minimal Muslim prayer companion (Flutter, Android, offline-first).
iOS is deferred: keep the domain layer platform-neutral so iOS can be added later, but do not spend
effort on iOS build config, permissions or platform limits for now.
Principle: "Know when to pray. Know when your mosque starts. Get reminded on time."
It must feel calm, fast and trustworthy, never like an overloaded Islamic super-app.

Design reference (exploration, not a spec; its mock data must never ship):
docs/prayer-prototype.html — the interactive prototype, open it locally. Use it for layout, hierarchy
and tone; its mock mosque names, times and bearings must never ship.
The prototype does not cover Adhan alerts or sound options; design those in the same visual language.

## Product rules (non-negotiable; ask before changing)
- Adhan times and Iqama times are separate concepts in UI, code and data.
- Iqama times belong to individual mosques. Never global, never derived from Adhan times.
- A new mosque starts with every Iqama time "Not configured". Never fill defaults or invent times.
- The Iqama editor may open its time picker at the day's Adhan time, as a starting position only:
  the field says "Adhan <time> · tap to set", nothing is stored until the user confirms a time,
  and the Adhan time is never shown or saved as the Iqama (decided 2026-10-13).
- Iqama times are entered and managed by the user. No external Iqama data source.
- One editable schedule per mosque, modelled as an entry with an optional effective-from date
  so dated/seasonal schedules can be added later without a migration.
- Adhan alerts (global, per prayer) and Iqama reminders (per mosque) are fully independent.
- Iqama reminders exist only for prayers with a configured Iqama time. Sunrise has no Iqama or reminder.
- In the UI an Iqama reminder is called a "Jama’ah reminder" (decided 2026-10-13); the Iqama
  time itself keeps the name Iqama. Code, data and notification ids keep the iqama names.
- Sunrise may have an Adhan alert (default off). It never has an Iqama or Iqama reminder.
- A mosque's Adhan alerts come from the global per-prayer settings, never from the mosque.
- Switching the active mosque switches the schedule driving Iqama reminders; reschedule accordingly.
- Mosque Iqama configuration lives on the mosque, never in general Settings.
- Never present unverified mosques as verified. There is no verification mechanic; label results by source.

## Architecture
- Flutter/Dart, Android only for now (iOS deferred). No accounts, analytics or custom backend
  (a minimal proxy is allowed only to protect an API key).
- Domain logic is independent of Flutter and unit-testable, and platform-neutral so iOS can be added later.
- Offline-first: prayer times, Qibla, saved mosques, Iqama schedules, reminders, Adhan alerts and
  settings work with no network. Network only for: mosque discovery, geocoding the manual place
  fallback (or a bundled offline city list), and Aladhan as a dev-time test oracle only.
- On-device: adhan_dart (times), geolocator, flutter_compass, drift/SQLite, flutter_local_notifications,
  just_audio or audioplayers (full adhan). Substitute equivalents if justified.
- App name, bundle ID and branding live in one config location. Logo/branding undecided: neutral wordmark.
- Branding source: branding.yaml (app name "Jama’ah" with the typographic apostrophe U+2019; identifiers
  stay ASCII: placeholder application id dev.jamaah.app, Dart package jamaah).
  tool/sync_branding.dart generates the Dart values and applies the Android/iOS values. Keys and
  other secrets live only in an untracked .env and reach the app via --dart-define.

## Data model
- Mosque: id, name, address, optional coordinates, optional provider place ID, list of schedules.
- Schedule: per prayer (fajr, dhuhr, asr, maghrib, isha) a nullable local time of day, reminderEnabled,
  reminderMinutesBefore, updatedAt. UI shows "Set by you · last updated <date>".
- Schedule resolution: the schedule in force on a given date is the one with the latest effectiveFrom
  on or before that date. If none applies, the schedule with no effectiveFrom is used.
- Adhan alert settings: global default sound mode (full | short | standard | silent) plus, per prayer,
  enabled (all six prayers including sunrise) and an optional per-prayer sound override.
  `standard` means the platform's default notification sound; `silent` means the notification is still
  shown but makes no sound; `enabled=false` means no notification at all — these are three different
  things and must never be collapsed.
- Store times as local time of day / minutes-from-midnight, never absolute timestamps.

## Prayer times
- Compute on-device. Methods (expanded 2026-10-13): Auto detect (from the place's time zone,
  MWL fallback), Custom angles, Egypt (EGAS), ISNA, Moonsighting Committee, MWL, Umm al-Qura
  (Isha 120 min in Ramadan), Karachi, JAKIM (20°/18°), MUIS, KEMENAG, Diyanet, UOIF, Kuwait, Qatar,
  Dubai, Gulf, Jordan, Algeria, Morocco, Tunisia, Russia, Portugal, Tehran, Ja'fari.
  Asr: Standard/Hanafi. Per-prayer minute offsets.
- Handle high latitudes via the library's rules and state which rule applies. Default rule:
  middleOfTheNight, selectable in Settings; add a quiet note whenever the rule actually moves a time.
- Recompute on location, method, date, timezone and DST changes.
- adhan_dart returns UTC wall-clock times: the wrapper must add the location's zone offset
  (DST-aware, via the timezone database + the device's IANA zone name) to get local times.

## Mosque discovery (configurable)
- MosqueDiscoveryProvider interface, two implementations selected by config
  (DISCOVERY_PROVIDER=google|osm via .env or --dart-define):
  1. GooglePlacesProvider (default, free tier): Places API (New) Nearby Search, includedTypes "mosque".
     Request ONLY rendered fields (name, address, location, place ID). Billing follows the highest-priced
     field requested, so never add ratings, reviews, photos or hours without a deliberate cost decision.
     No per-result Place Details calls.
  2. OpenStreetMapProvider: Muslim places of worship via Overpass (or equivalent), for comparison.
- Keys never in source control. A key inside an app is extractable: restrict to package name/signing
  identity and bundle ID, cap quota/budget; use a minimal proxy if that is insufficient.
- Debounce, cache and limit calls per session. Store place ID plus the user's own saved name/address;
  verify Google's caching terms before storing other place content.
- Request location only when the user taps "Find nearby", after a respectful explanation.
  Always offer manual place search. Log which provider served results.
- Two location levels (decided 2026-10-13): prayer times use approximate location only;
  "Find nearby" asks for precise location (the user may keep it approximate). Each level is
  requested on its own, so the first prompt never offers precise.
- Google mosques keep the place id plus the user's confirmed name/address, not coordinates
  (Google allows caching lat/lng for 30 days). OSM mosques may keep coordinates (ODbL).

## Notifications and Adhan sound
- Local notifications only, rolling window (~7 days). Reschedule on app start, timezone/DST change,
  location change, and any prayer-time setting, Iqama edit or sound change.
- Sound modes in Settings: full adhan, short adhan (first part only), standard (the platform's default
  notification sound) and silent (notification shown, no sound); global default mode with a per-prayer
  override. Include preview and stop controls. Silent is not the same as disabled: a silent alert still
  appears in the shade.
- Android platform rules (iOS deferred):
  - Sounds are bound to the notification channel at creation: use separate channels per mode
    (adhan_full, adhan_short, standard, silent — silent with `sound: null` and no buzz) and create a
    NEW channel id whenever the sound changes, retiring the old one.
  - Handle the notification permission (Android 13+) and the exact-alarm permission
    (SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM) honestly: if exact alarms are denied, degrade to inexact
    timing and say so in the UI rather than failing silently.
  - Include battery-optimisation guidance so reminders survive Doze.
  - A full-length adhan may not be usable as a channel sound; verify on a real device. If it cannot,
    play the full adhan through the app's own audio route (alarm stream) and keep the short version
    as the channel sound.
- Bundle adhan audio only with clear usage rights; record source and licence in the repo.
  The MVP ships a clearly marked generated placeholder tone that is trivially swappable.
- Provide a debug view listing scheduled notifications.

## Qibla
Great-circle bearing, unit-tested against known cities. Device compass with calibration prompt;
static-bearing fallback when sensors/location are unavailable. Supporting feature; never dominant.

## Visual design
- Light first: warm off-white, deep forest green, restrained sage; dark theme secondary.
- Strong typography, efficient spacing, 48dp minimum touch targets, quiet transitions.
- Avoid: gold gradients, mosque silhouettes everywhere, ornate decorative patterns, glassmorphism,
  stacked floating cards, streaks, badges, feeds, gamification.
- Support dynamic text sizes, screen readers, localization and RTL (no hard-coded strings).

## Non-goals (MVP)
Accounts, cloud sync, social features, Quran/dua content, prayer tracking/streaks, community-sourced
Iqama data, widgets, wearables, iOS (deferred), Arabic UI.

## Quality bar
- Unit tests: prayer-time wrappers, Iqama/reminder math, notification scheduling logic, Qibla bearing,
  provider mapping (Google and OSM responses to one Mosque model).
- Widget tests: Iqama editing flow, unconfigured/empty states, Adhan sound settings.
- Prefer the lightest solution that satisfies the rules above.

## Open questions (flag, do not decide silently)
1. Source and licence of adhan audio (full and short), and which recording.
2. Google Places vs OSM coverage in target regions; free-tier cost ceiling.
3. Bundle identifier and store listing details.
