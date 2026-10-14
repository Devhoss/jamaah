# Iqama as "N minutes after the Adhan" — design

Agreed 2026-10-14, from tester feedback: Kuwaiti mosques publish the Iqama as
minutes after the Adhan (Awqaf card: Fajr 22, Dhuhr 20, Asr 20, Maghrib 10,
Isha 15). Users should type the minutes; the app adds them.

## Rule change (AGENTS.md)

An Iqama is either a **fixed time** or **N minutes after the Adhan**, both
entered by the user. The app never fills one in; a new mosque starts with every
prayer (and Jumu'ah) "Not configured".

## Data

- `PrayerIqama` keeps `iqama` (fixed `LocalTime?`) and gains `afterAdhanMinutes`
  (`int?`, 1–90). At most one is set; neither = Not configured.
- Schema v6: `schedule_prayers.iqama_after_adhan_minutes`,
  `schedules.jumuah_after_adhan_minutes` (nullable, addColumn).

## Resolution

- Adhan = the day's time at the **current place** (as everywhere else). Jumu'ah
  counts from Dhuhr's Adhan.
- Minutes are added to the Adhan's instant, so Isha past midnight and DST days
  are right. `PrayerIqama.minutesOfDay(int? adhan)` returns unwrapped minutes
  (may be ≥ 1440 → the next date).
- No Adhan that day ⇒ no Iqama that day (never guessed).
- The Isha-after-midnight rule for fixed times is unchanged.

## UI

- Iqama editor: a two-way choice, **Minutes after Adhan** (default for a new
  entry) or **Fixed time**. Minutes: a number field (1–90) and a live line
  "Adhan 4:29 AM + 22 min = Iqama 4:51 AM today". Reminder settings unchanged.
- Mosque page: "Enter all five" opens a sheet of five number fields with each
  prayer's Adhan and resulting Iqama; Save stores the filled ones; empty fields
  leave that prayer as it is.
- Mosque rows show "22 min after Adhan" with the resolved time; Today, the
  hero card, notifications and reminders use the resolved time.

## Testing

Unit: resolution (normal, Isha past midnight, no Adhan), planner, repository,
v5→v6 schema. Widget: editor modes, enter-all-five, Today/mosque display.
Device check.
