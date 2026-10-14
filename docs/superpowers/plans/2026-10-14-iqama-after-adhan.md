# Iqama after Adhan — implementation plan

> Executed inline (superpowers:executing-plans). Spec:
> `docs/superpowers/specs/2026-10-14-iqama-after-adhan-design.md`.

**Global constraints:** offsets 1–90 min; never auto-filled; Adhan from the
current place; minutes added to the Adhan instant; commits as usual
(`git -c user.name="Jamaah dev" …`, never `android/app/build.gradle.kts`);
strings EN in `app_en.arb`, AR in `tool/arabic_strings.py`, then gen-l10n and
`tool/gen_arabic_digits.py`.

**Review focus:** Isha + offset past midnight (Today card and reminder on the
right date); a day with no Isha/Fajr time; switching an entry between modes
clears the other; Jumu'ah offset counts from Dhuhr; tomorrow's Fajr on the card
after Isha uses tomorrow's Adhan.

### Task 1 — Domain
`PrayerIqama.afterAdhanMinutes`, `isConfigured`, `minutesOfDay(int? adhan)`;
`kMinAfterAdhan = 1`, `kMaxAfterAdhan = 90`. Tests in
`test/domain/iqama_after_adhan_test.dart`: fixed, offset, offset past midnight
(≥1440), no Adhan → null, equality, copyWith switching modes.

### Task 2 — Storage (schema v6)
Columns, migration step, repository read/write; `setIqama(…, afterAdhanMinutes:)`,
`setJumuah(…, afterAdhanMinutes:)`, `setAfterAdhanForAll(mosqueId, Map<Prayer,int>)`.
Tests: round trip, mode switch clears the other, enter-all keeps other prayers.

### Task 3 — Readers
Planner (instant = Adhan instant + minutes), `readNextIqama` (with tomorrow's
times for the Fajr fallback), Today rows, hero card. Tests: planner offset incl.
Isha past midnight and Friday Jumu'ah offset; next-Iqama offset incl. past
midnight and tomorrow's Fajr.

### Task 4 — Editor and "Enter all five"
Editor mode choice + minutes field + live line; mosque row text; enter-all
sheet. Widget tests EN + AR 2×.

### Task 5 — Docs, device check, report
AGENTS.md rule, README, user guide; device check; Discord.
