# Extra times (Imsak, Duha, Qiyam) and Jumu'ah — design

Agreed 2026-10-14. Two independent pieces, built and committed in this order.

## 1. Extra times

### What they are

| Time  | Rule                                                         | Range / default |
|-------|--------------------------------------------------------------|-----------------|
| Imsak | Fajr − N minutes                                             | N 0–20, 10      |
| Duha  | Sunrise + M minutes                                          | M 10–30, 15     |
| Qiyam | Start of the last third of the night: Maghrib + ⅔ × (next day's Fajr − Maghrib) | — |

- Built on the day's Adhan times *after* the user's per-prayer offsets and the
  high-latitude rule, so they follow every existing prayer-time setting.
- Qiyam belongs to the night that begins on the given evening. Measured between
  instants (not wall-clock minutes) so a DST night has its real length.
- A missing input time (polar day/night) means that extra time is absent. Never guessed.
- Start times only: no end times, no Iqama, never "next prayer", no countdown.

### Domain

`lib/src/domain/extra_times.dart`, pure Dart:

- `enum ExtraTime { imsak, duha, qiyam }`
- `ExtraTimesSettings { imsakMinutes, duhaMinutes, shown: Set<ExtraTime>, alerts: Set<ExtraTime> }`
  with defaults: Imsak 10, Duha 15, shown `{imsak}`, alerts `{}`; clamping helpers.
- `ExtraTimes extraTimesFor({PrayerDay day, PrayerDay nextDay, ZoneOffsets zone, settings})`
  returning, per extra time, the local day + `LocalTime` (Qiyam may fall on the next date).

### Settings

- Stored in `app_settings` (no migration): `extra_imsak_minutes`, `extra_duha_minutes`,
  `extra_shown`, `extra_alerts` (comma lists of names).
- Settings → "Extra times" page: per time a "Show on Today" switch and an "Alert" switch;
  Imsak minutes and Duha minutes pickers. Arabic: إمساك، ضحى، قيام الليل.

### Today

Each shown extra time is a quiet secondary line in time order: Imsak above Fajr,
Duha after Sunrise, Qiyam (labelled "Last third of the night") after Isha. Between
midnight and Fajr, Today shows the current night's Qiyam.

### Alerts

- New channel "Other times" using the Jama'ah reminder sound choice (chime / حيّ على
  الصلاة / standard / silent) and its vibrate setting; versioned like the reminder channel.
- New `NotificationKind.extra`, ids in the existing `kind * 1 000 000 + day * 10 + n` scheme.
- Same rolling 7-day window; suppressed while an in-flight hold is active.
- Title: the time's name; body: its time and place, in the chosen language.

## 2. Jumu'ah

### Data

Schema v4 adds three nullable/defaulted columns to `Schedules` (`addColumn`, no rebuild):
`jumuahMinutes` (null = Not configured), `jumuahReminderEnabled` (false),
`jumuahReminderMinutesBefore` (10). `Schedule` gains `jumuah: PrayerIqama`
(prayer = dhuhr internally; the UI names it Jumu'ah). A new mosque starts with it unset.

### Mosque detail

A Jumu'ah row under the five prayers, same Iqama editor: the picker may start at the
day's Dhuhr Adhan with the hint "Adhan <time> · tap to set"; nothing is stored until
confirmed. Its own Jama'ah reminder switch and lead minutes.

### Fridays (by the place's date, not the phone's)

- Today's Dhuhr row is labelled Jumu'ah; the Dhuhr Adhan notification title says Jumu'ah.
- The Iqama card and Jama'ah reminder use the mosque's Jumu'ah entry and its reminder
  settings; the Dhuhr Iqama reminder does not fire that Friday.
- If Jumu'ah is not set: fall back to the Dhuhr Iqama, with a quiet note on the card
  "Jumu'ah time not set · showing Dhuhr Iqama" so a time the user did not enter for
  Jumu'ah is never presented as one. Dhuhr's reminder settings apply in that case.
- Paused mosque reminders and the pause-all switch apply to Jumu'ah as to every Iqama.

## Strings

English in `app_en.arb`, Arabic via `tool/arabic_strings.py` (then `flutter gen-l10n` and
`tool/gen_arabic_digits.py`). New Arabic strings added to `docs/arabic-strings-review.md`.

## Testing

- Unit: extra-time maths (normal day, Qiyam across midnight, DST night, missing Fajr,
  clamping); settings round trip; Friday resolution with and without Jumu'ah;
  v3 → v4 migration keeps data; notification plan (extra alerts, in-flight hold,
  no Dhuhr reminder on Friday, Jumu'ah reminder instead).
- Widget: Extra times page; Today rows (EN and AR, before/after midnight); Friday on
  Today with and without a Jumu'ah time; editing the Jumu'ah row.
- Device check on the phone, then commit, Discord report, docs/user guide update.

## Out of scope

End times / windows, Ramadan-only Imsak, a Friday-morning nudge, extra times in
in-flight mode.
