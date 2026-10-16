# Jama’ah redesign: “Horizon” handoff spec

Status: agreed with the owner on 2026-10-15. This replaces the prototype palette and look
described in `README.md` (“Current visual language”). The product rules in `AGENTS.md` are
unchanged and win over anything here.

- **Interactive designs:** the Claude Design canvas “Jama’ah Redesign”
  (https://claude.ai/artifact/KiDbUXiAM6y4ee2MwUKtWR, private to the owner). Rows on the canvas:
  Horizon (Today, travel, full-screen Adhan), Mosques, Onboarding, Qibla and in-flight, Settings.
  The rows above them (Sky, Paper, Night) and the icon concepts are earlier explorations.
- **Reference source:** `horizon-reference/Horizon.dc.html` is the canvas’s single source file
  for every Horizon screen. It is prototype code (HTML + JS), not something to port line by line,
  but its `renderVals()` holds the exact sky, ink, sun, moon and arc maths this spec describes.
  Its sample data (Test Mosque, times, the other mosque names, flight position) must never ship.

---

## 1. The idea in one paragraph

The app is a window onto today’s sky. The background is the real sky for the time being
shown, blended continuously from dawn to night, with the sun on its path, the actual moon
phase and stars after dark. Everything else stays quiet: one large Adhan time in a light
serif, the mosque’s Iqama as a separate solid “ticket”, plain rows, plain switches. Secondary
pages keep the sky as a header band and put their controls on a calm solid surface (“sky
above, ground below”). The purpose is to bring people to pray **together, at their mosque**;
the copy and the icon direction carry that.

The owner chose to go beyond the brief’s “no gradients / no decoration” for the sky, stars and
grain. Still out: gold, ornament, mosque silhouettes as decoration, glassmorphism, badges,
streaks, feeds.

---

## 2. Foundations

### 2.1 Fonts (bundled for the whole app, all OFL)

| Role | Latin | Arabic |
|---|---|---|
| Display: big times, prayer names, page titles, section titles | **Fraunces** (300, 400, 400 italic) | **Noto Naskh Arabic** (500, 600) |
| UI: rows, labels, buttons, body | **Instrument Sans** (400, 500, 600) | **Noto Sans Arabic** (400, 500, 600) |

- Bundle only these weights. Times use tabular, lining figures. Arabic uses Arabic-Indic
  digits (٠١٢٣) as today.
- Fraunces italic is used for prayer names next to the big time, sheet titles and a few
  section titles (“Iqama schedule”, “Along the route”). Arabic has no italic: use Naskh 500.

### 2.2 Type scale (logical px; must still work at 2× text size)

| Token | Use | Spec |
|---|---|---|
| `hero` | Next Adhan time on Today | Fraunces 300, 108, letter-spacing −4%, line-height 0.92 |
| `display` | Page titles (Mosques, Qibla, Settings, mosque name) | Fraunces 400, 38–40, −2% |
| `onboardingTitle` | Onboarding headings | Fraunces 400, 40, line-height 1.08 |
| `prayerName` | Name beside the hero, sheet titles | Fraunces 400 italic, 26 |
| `section` | Section titles on surfaces | Fraunces 400 italic, 22 |
| `kicker` | “NEXT PRAYER · ADHAN”, “YOUR MOSQUE” | Instrument 600, 12, uppercase, +12–14% tracking |
| `row` | Prayer rows, list titles | Instrument 600, 16 |
| `body` | Paragraphs | Instrument 400, 14–16, line-height 1.45–1.5 |
| `meta` | Sub-lines, captions | Instrument 400/500, 12–13 |
| `rowTime` | Times in rows | Instrument 500, 15–16, tabular |

At 2× text: rows grow (no fixed heights below 48), the hero may drop to 2 lines (time, then
name), the bottom nav labels may wrap. Nothing truncates a time.

### 2.3 Surfaces and colour tokens

Two colour systems:

**A. Sky tokens** (computed each frame from the time being shown; see §3): `ink`, `deep`,
`mute` (ink 76%), `line` (ink 22%), `halo` (ink 12%), `trail` (ink 85%). Everything drawn on the
sky uses these.

**B. Surface tokens** (static) for sheets and the “ground” panel of secondary pages:

| Token | Light | Dark |
|---|---|---|
| `surface` | #FBF9F6 | #14151C |
| `onSurface` | #15161C | #ECEDF2 |
| `onSurfaceMuted` | #575A66 | #A3A6B3 |
| `divider` | #E2DED7 | #2A2C36 |
| `well` (segmented controls, highlighted rows) | #EFEBE4 | #1E2029 |
| `accent` (filled buttons, switch on) | #15161C | #ECEDF2 |
| `onAccent` | #FBF9F6 | #14151C |
| `danger` (Remove, Clear) | #B3261E | #F2B8B5 |
| `scrim` behind sheets | rgba(4,6,14,0.5) | same |

There is no brand accent colour. Emphasis is ink on sky, or `accent` on surfaces. The only
warm colour is the sun/amber in the sky itself.

### 2.4 Shape, spacing, touch

- Page gutter 24 on sky, 20 on surfaces. Rows: min height 48 (52 for prayer rows, 68–76 for
  two-line rows).
- Radii: surface panel top corners 28; bottom sheets 24; Iqama ticket and info boxes 14–18;
  segmented control 14 (inner 11); pill buttons fully round (heights 44–54); chips 13–15.
- Every control ≥ 48 dp. The arc “dots” are markers only (the arc itself is the control).
- Lines, not cards: lists are rows with dividers. The only boxed elements are the Iqama
  ticket, small info notes and sheets. No stacked floating cards.

### 2.5 Components (build once, reuse)

| Component | Notes |
|---|---|
| `SkyBackground` | Gradient + horizon glow + stars + grain (§3). Takes `minuteOfDay`, `dark`. |
| `SunPath` | The arc, trail, sun, moon, prayer markers; optional drag (`Slider` semantics). |
| `HeroTime` | Kicker, big time, italic name, “PM · in 50 min”. |
| `IqamaTicket` | Solid `ink` box with `deep` text: mosque, Iqama time, how it is set (“Adhan + 20 min · set by you” / “Fixed time · set by you”), reminder. States: set / not configured (dashed outline + “Set time”) / Sunrise (no Iqama) / no mosque. |
| `PrayerRow` | Select area + separate alert button (icon + word: Full, Short, Standard, Silent, Off). |
| `AlertSheet` | Three groups: “Notify with sound” (Full Adhan, Short Adhan, Standard sound) / “Notify without sound” (Silent) / divider / Off. Always on `surface`. |
| `TravelSwitch` | 72×40 pill; off: outline, ink knob with house; on: filled ink, knob turns `deep` with a plane. Knob springs (440 ms, overshoot) and stretches to 44 px for 180 ms while moving. Icons swap with scale+rotate. On surfaces it uses `accent`/`onAccent`. |
| `AppSwitch` | 52×32, solid. Off: `divider` track, muted knob. On: `accent`. Disabled (no Iqama yet): dashed outline track. |
| `Segmented` | `well` track, selected segment raised on `surface`. |
| `RadioList` | 20 px ring, filled ring when selected, label + one-line description. |
| `NotConfiguredPill` | Dashed 1.5 px outline, normal ink text “Not configured”. Calm, never error-coloured. |
| `SurfacePanel` | Rounded-top panel that holds a page’s controls under a sky header. |
| `Snackbar` | Ink on sky (`ink` bg, `deep` text), 2.2 s, slides up 8 px. |
| `BottomNav` | Four text tabs with a 5 px dot under the active one: **Today · Mosques · Qibla · Settings**. On sky it uses sky tokens, on surfaces surface tokens. |

Icons: one stroke set at 1.6–1.8 width, rounded caps (the reference uses Lucide-style
paths). No emoji, no filled icon mixes.

---

## 3. The sky engine (domain layer, unit-tested)

Put this in the domain layer (pure Dart, no Flutter imports) so it is testable and reused by
every screen. The painter only draws what it is given.

### 3.1 Keyframes

Five colour stops per keyframe at 0%, 13%, 22%, 34%, 100% of the screen height. The horizon
line sits at ~22%. `glow` is an elliptical radial highlight centred at (50%, 22%), radius 75%×16%.

| Minute | Moment | Stops (top → bottom) | Glow RGBA | Stars | Dark dim |
|---|---|---|---|---|---|
| 0 | night | #03050D #070C1E #0E1430 #0B1024 #090D1C | 90,110,180,0.12 | 1.0 | 0.20 |
| 261 | Fajr | #070B24 #1B2152 #4E4176 #27254C #121530 | 236,150,140,0.45 | 0.6 | 0.30 |
| 342 | sunrise | #5C79B5 #B79AC0 #F2B39A #F6D2B0 #FBEBDD | 255,214,160,0.75 | 0 | 0.55 |
| 430 | morning | #5E9BD6 #9CC6EA #DCEBF3 #EEF4F6 #F7F9FA | 255,240,210,0.40 | 0 | 0.65 |
| 689 | noon | #4C9BE0 #7DB8EA #B9DBF4 #DDEEF9 #EEF6FB | 255,255,255,0.35 | 0 | 0.68 |
| 889 | Asr | #7FB1DA #B5CCDC #EBD3A6 #F4E1C2 #FBF1E2 | 255,200,130,0.45 | 0 | 0.62 |
| 990 | golden | #6E93C4 #C9A9A6 #F2B27A #F3D2AE #FAE8D8 | 255,170,100,0.60 | 0 | 0.55 |
| 1035 | sunset | #232E66 #C05A7A #F2925E #6A3050 #1B1328 | 255,150,90,0.55 | 0.1 | 0.40 |
| 1070 | dusk | #141A40 #3A2A5E #8A4A6A #2E2040 #140F22 | 220,120,110,0.35 | 0.4 | 0.30 |
| 1111 | Isha | #05081A #0E1534 #22295A #141A38 #0C1124 | 110,120,190,0.20 | 0.85 | 0.20 |
| 1260 | night | = night | = night | 1.0 | 0.20 |
| 1440 | night | = night | = night | 1.0 | 0.20 |

**Important:** the minutes above are the sample day (Kuwait City, mid-October). In the app,
anchor the keyframes to the **day’s real events** instead of fixed minutes: Fajr, sunrise,
Dhuhr (noon), Asr, sunset (Maghrib), Isha come from the computed times; “morning” sits halfway
between sunrise and noon, “golden” ~45 min before sunset, “dusk” ~35 min after sunset, and the
deep-night keyframes ~2.5 h after Isha and at midnight. Then high latitudes, winter and summer
look right without retuning.

Interpolation: find the two keyframes around `t`, `f = (t − a)/(b − a)`, smoothstep
`f·f·(3 − 2f)`, mix each stop in sRGB. Stars and glow mix the same way.

**Dark theme:** after mixing, blend every stop toward #04050B by that keyframe’s “dark dim”
amount (interpolated), and multiply the glow alpha by 0.6.

*As built (owner, 2026-10-16):* the sRGB blend made a dark noon flat grey and sunrise/sunset
brown, so dimming is perceptual (OKLCH): each stop’s lightness moves by the dim amount toward
#04050B’s, and its hue and chroma turn by the same amount toward the top stop’s (the sky’s own
colour), never passing through green; chroma is pulled in only where a colour would leave sRGB.
A dark noon is deep blue, a dark sunrise or golden hour dusky rose. The Iqama ticket on a night
sky in the dark theme is ink at 88% over the sky behind it (still solid, text still ≥ 4.5:1).

### 3.2 Ink that flips automatically

```
Lmid  = (luminance(stop[3]) × 1.2 + luminance(stop[4])) / 2.2      // WCAG relative luminance
light = Lmid < 0.30
ink   = light ? #F5F3FA : mix(stop[0], #05070F, 0.82)
deep  = light ? mix(stop[4], #000000, 0.25) : #FBFAF7              // text on an ink fill
mute  = ink @ 76%   line = ink @ 22%   halo = ink @ 12%   trail = ink @ 85%
```

Animate ink/deep changes over ~400 ms so a flip during a drag is not abrupt. Unit-test that
`ink` on the stop under each text block keeps ≥ 4.5:1 (≥ 3:1 for the hero) at every minute of
a few sample days (Kuwait winter and summer, London summer for a long dusk).

**As built (owner, 2026-10-15).** The single threshold above left near-white text on mid-tone
sky (2.6:1 for rows before sunrise, 2.3:1 for the hero at golden hour), so:

- **Ink per block.** Each block of text (top bar, hero, notes and ticket, rows, the label under
  the sun) picks whichever of the two inks reads better against the sky actually behind it,
  glow included, measured from the real layout. For the few minutes when neither ink reaches
  the block's contrast, a faint shade of the opposite tone (≤ 20%) is laid under that block
  only. The dark theme never needs it.
- **Muted text.** `mute` starts at ink 76% per block and its opacity is raised only as far as
  needed to keep 4.5:1 against the sky behind that block (3:1 for text 24 px or larger); never
  below 76%, never above 100%. Where muted text reaches full ink, the hierarchy rests on size
  and weight; no other colour is added. The Iqama ticket's quieter lines follow the same rule
  on the ink box: `deep` at 80%, raised only as needed for 4.5:1.
- **Tests** check the ink, the shade and every muted block at every minute of Kuwait winter
  and summer, London summer and Oslo summer, in both themes.

### 3.3 Stars and grain

- 46 stars, seeded (fixed positions), in the top 300 px; size 0.8–2.4 px; brightness fades
  with height (`max(0.25, 1 − y/320)`); twinkle 2.6–5.6 s with random offsets. Layer opacity =
  the keyframe star value.
- Grain: fractal noise (base frequency ~0.85, 2 octaves, greyscale) blended as overlay at 7%
  (light) / 10% (dark). It prevents banding on OLED. In Flutter, precompute one noise image
  and draw it with an image shader; do not compute noise per frame.

### 3.4 Sun path geometry (a 390 × 168 box; scale with width)

- Horizon line y = 118. Day arc: ellipse centre (195, 118), radii 150 × 96, from sunrise (left,
  x = 45) to sunset (right, x = 345). Night arc: same centre, radii 150 × 36, below the line,
  from sunset back to sunrise, drawn dotted.
- Day: `a = π·(t − sunrise)/(sunset − sunrise)`, `x = 195 − 150·cos a`, `y = 118 − 96·sin a`.
- Night: `a = π·(t' − sunset)/nightLength` (t' wraps past midnight), `x = 195 + 150·cos a`,
  `y = 118 + 36·sin a`.
- Trail: the part of the day arc from sunrise to now is drawn at `trail`; after sunset the
  whole day arc plus the travelled part of the night arc (dotted).
- Sun colour by altitude `h = sin a`: core and disc mix from #FFB062/#FFC27E (horizon) to
  #FFF4DC/#FFF8EA (high) with `min(1, 2.4·h)`. Halo r = 30 breathes (scale 1 → 1.18, 4.8 s).
  Below the horizon the sun sits on the night arc at 28% opacity.
- Prayer markers: 10 px ink dots with a soft glow; the selected one 16 px with a pulsing ring
  (2.4 s); the next prayer gets a quiet 4 px halo ring; Sunrise is a hollow ring.
- Labels (owner, 2026-10-16): when the sun is within 48 px of the selected marker, one label
  says both (“Dhuhr · 12:42 PM”). Otherwise each label takes the first spot around its point
  (below/above, sides, corners, then a step further out) that touches no marker, no arc and
  no other label.

### 3.5 Moon

- Age in days ≈ Hijri day − 0.5 (after the user’s Hijri adjustment).
- The moon lags the sun ~50.5 min per day of age: moon time = t − age × 50.5; place it on the
  day arc with the same function; draw it only when that time is between sunrise and sunset.
- Phase: illuminated fraction `k = (1 − cos(2π·age/29.53))/2`; draw a disc (12% fill) plus the
  lit part bounded by the outer half-circle and a terminator ellipse with x-radius `r·|1 − 2k|`
  (crescent for k < 0.5, gibbous otherwise). Rotate so the lit side faces the sun.
- Opacity 0.35 while the sun is up, 0.95 after sunset.

This is an illustration, not astronomy. It only has to be right enough that a young crescent
hangs low in the west after Maghrib.

### 3.6 Performance and motion

- One clock drives twinkle/breathe/pulse. Pause it when the screen is not
  visible (`TickerMode`) and when the app is in the background.
  *As built (2026-10-16):* it ticks at 12 fps, and only the small layers that move (stars, the
  sun’s halo, the selected marker’s pulse) repaint, each behind a `RepaintBoundary`; the
  gradient, glow, shade, grain and the path’s still parts are cached images redrawn only when
  the minute or theme changes, and the stars are one sprite drawn in a single call. Measured on
  the A53: Today idles at ~13% of a core (was ~90%).
- `MediaQuery.disableAnimations` (reduce motion): no twinkle, pulse, breathe, figure-eight or
  spinner rotation; glides become instant.
- Glides along the arc: ease-in-out cubic, duration `min(1200, 380 + 0.9 ms × minutes)`, the
  short way round the clock.
- Spring for knobs/markers: cubic-bezier(0.34, 1.56, 0.64, 1).

---

## 4. Screens

Each screen below exists on the canvas in light and dark unless noted. Copy shown in quotes is
the English draft; every string goes through the ARB files, and Arabic needs review
(`docs/arabic-strings-review.md`).

### 4.1 Today

Layout top to bottom:

1. **Top bar on sky.** Place button (“Kuwait City ▾”, subline “Thu 15 Oct · 4 Jumada al-Awwal
   1448”) → location sheet. Right: `TravelSwitch`. (The settings gear moved to the nav.)
   A place the phone found, with no name of its own, is “Near Kuwait City” (the nearest city
   in the bundled list, offline); the Iqama ticket’s kicker keeps “IQAMA” in capitals and the
   mosque’s name as typed.
2. **SunPath**, interactive: drag anywhere on it (or arrow keys, Shift = 30 min) to look through
   the day; the sky, sun, moon, stars, hero and ticket follow. Label under the sun: “Now 1:59”,
   or the viewed time. Semantics: slider “Look through the day”, value text “4:12 PM, Asr”.
3. **Hero.** Kicker “NEXT PRAYER · ADHAN” (or “ADHAN”, “IN FORCE AT 4:12 PM”, “SUNRISE · NOT A
   PRAYER”, “NEXT PRAYER · TOMORROW”), big time, italic name, “PM · in 50 min”. A “Back to now”
   pill appears whenever the view is moved; it glides back.

   **Hold until the Iqama** (owner, 2026-10-15). At rest, between a prayer’s Adhan and its
   Iqama, Today keeps that prayer selected instead of jumping to the next Adhan:
   - Kicker “ASR · IQAMA IN 15 MIN”; the hero keeps the Asr Adhan time with “Adhan 5 min ago”;
     the Iqama ticket carries the main countdown (“Iqama 3:20 PM · in 15 min”). The “Next” tag
     stays on the next Adhan’s row (Maghrib).
   - Only when the active mosque has an Iqama for that prayer that is still ahead (Fridays: the
     Jumu’ah Iqama, falling back to Dhuhr’s own while Jumu’ah is unset). No hold while Iqama
     reminders are paused for travel or while travel mode follows the location; without a
     mosque or an Iqama, behave as above.
   - At the Iqama minute, glide on to the next prayer (instant under reduced motion).
4. **IqamaTicket** for the selected prayer and the active mosque.
5. **Travel mode on:** a ruled row “On a flight?” → in-flight screen. The place subline becomes
   “Following your location · checked 2 min ago”.
6. **Prayer rows** (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha; extra-time rows when enabled,
   quieter, never selectable as Next). Tapping a row glides the sun to that prayer. Each row has
   its own alert button → `AlertSheet`. “Next” tag on the next prayer. Iqama as “Iqama 3:09” or
   “Iqama not set”. List scrolls with no visible scroll bar when needed.
7. **BottomNav.** On the sky the bar fades the sky’s bottom colour in behind itself (24 px
   above its line), and Today’s scroll ends the bar’s height above the bottom, so rows never sit
   on the bar.

**Notes** (high-latitude rule moved a time, polar estimate, no times today, clock mismatch,
reminders paused, in-flight hold): not drawn on the canvas. Rule: show at most two as single
quiet lines (13 px, `mute`, small icon) between the hero and the ticket; more collapse into
“2 more notes”. In-flight hold adds an “End” text button. They are never boxed or coloured.

**Fridays:** Dhuhr is labelled Jumu’ah; the ticket shows the Jumu’ah Iqama, or “Jumu’ah time
not set · Dhuhr Iqama 11:45” while unset (as today’s logic).

**Loading / no place / error:** sky at the current minute with no hero; “Set your place”
(primary pill) for no place; “Settings couldn’t be read” + “Try again” for errors. Same quiet
typography, no illustrations.

### 4.2 Full-screen Adhan (over the lock screen)

The prayer’s sky fills the screen. Date line at the top, SunPath (not interactive), “IT’S TIME
FOR”, the prayer name in 76 px italic, “Adhan · 5:15 PM”, a 136 px round **Stop** button
(ink fill) with two slow expanding rings while playing, the Iqama line (“Iqama at Test Mosque ·
5:20 PM, in 5 min” or “No Iqama set at Test Mosque”), and “Volume keys or turning the phone
face down also stop it.” After Stop: “Adhan stopped” + “Dismiss”.

As built (Phase 5, 2026-10-16): the page stays native, so it shows at once over the lock
screen (owner). Dart works out each full-screen Adhan's page when it schedules the alarm
(lib/src/app/adhan_screen.dart): both themes' sky at the prayer's minute, the ink, the sun path
points and every line of text; the native page (AdhanPage.kt) only draws them, with the bundled
fonts. The sky is a still picture of that minute. An alarm stored before this keeps the plain
page. When the Adhan ends or is stopped any other way, the page turns to “Adhan stopped”.

### 4.3 Mosques tab

- Sky header: “Mosques”, lead “Today and your Jama’ah reminders follow your active mosque,
  now Test Mosque.”, buttons **Find nearby** (filled, pin icon) and **Add manually**.
- `SurfacePanel` list. Each mosque: name; source line (“Added by you” / “From Google Maps · not
  verified” / “From OpenStreetMap · not verified”); six small dots (five prayers + Jumu’ah,
  filled = set, dashed = not) with “4 of 6 Iqama set” / “No Iqama set yet”. The active one sits on
  `well` with the tag “✓ Active · Today uses this mosque”; others show **Make active** (→
  snackbar “Mosque near work is now your active mosque”, reschedule). Paused mosques show
  “Reminders paused”. Footer: “Mosques found online show where they came from and are not
  verified. Your Iqama times stay on this phone.”
- **Empty state:** a row of five figures with the last place dashed; “There’s a place for you”;
  “Add the mosque you pray at. Jama’ah will show when its congregation starts and remind you
  before it.”; **Find mosques nearby** / **Add one yourself**; “You enter its Iqama times.
  Nothing is guessed, and nothing leaves your phone.”

### 4.4 Mosque page

- Sky header: back, **Edit details**; “YOUR MOSQUE”, name in `display`; tags Active / source;
  “4 of 6 Iqama set”; bell line “Next Jama’ah · Asr 3:09 PM · in 1 h 10 min”.
- Surface: “Pause Jama’ah reminders” switch (“Your Iqama times and settings are kept.”).
- “Iqama schedule” (italic section) · “Tap a prayer to set it”. Six rows (Fajr … Isha, Jumu’ah
  “Fridays, in place of Dhuhr”): name + Adhan time; Iqama time with how it is set underneath
  (“Adhan + 20 min” / “Fixed time”) or `NotConfiguredPill`; reminder line (“Reminder at 4:31 AM”,
  “Paused · Reminder at …”, “Reminder off”, “Set an Iqama time to add a reminder”); `AppSwitch`
  (disabled, dashed, until a time exists).
- Footer: “Set by you · last updated 12 Oct 2026. The app never fills in an Iqama.”, **Remove
  this mosque** (danger, with confirmation, not drawn).

### 4.5 Iqama editor (bottom sheet)

- Title “Isha Iqama” (italic), sub “Test Mosque · Adhan 6:31 PM today”.
- `Segmented`: **Minutes after Adhan** (“Moves with the Adhan”) | **Fixed time** (“Same time
  every day”). For a new prayer, Minutes after Adhan is selected with no value.
- Minutes: big number with − / + (1–90; empty shows “—”), quick chips 5/10/15/20/25/30, preview
  “Today: Iqama 6:51 PM. It moves with the Adhan each day.” Empty: “Choose how many minutes after
  the Adhan this mosque starts. Nothing is saved until you do.”
- Fixed: empty shows a dashed button “Adhan 6:31 PM · tap to set” + “Nothing is saved until you
  choose a time” (tapping starts the picker at the Adhan time, AGENTS rule); set shows the time
  with −5 −1 +1 +5 (the real app may use the platform time picker instead of steppers) and “The
  same time every day, whatever the Adhan.”
- “Jama’ah reminder” switch (“A nudge before the congregation starts”), disabled until there is
  a value; when on, chips 5/10/15/20/30 min and “Reminder at 6:41 PM, 10 min before the Iqama.”
  Default for a newly set prayer: on, 10 min.
- **Cancel** / **Save** (disabled until there is a value); **Clear this Iqama** (danger) only if
  one was set. Save → snackbar “Isha Iqama saved”.
- Jumu’ah preview: “On Fridays the Iqama is 20 min after the Dhuhr Adhan.”

### 4.6 Onboarding (one day in five steps)

The sky walks through a day: each step glides the sun to its moment (dawn 4:15, sunrise 5:48,
midday 11:40, late afternoon 4:00, sunset 5:28 in the sample; in the app use the day’s own
events). The SunPath shows markers, no labels, not interactive. Bottom: five-segment progress,
**Back**, **Continue** (dashed and disabled when blocked).

1. **Welcome:** “Pray together, on time.” / “Know when to pray. Know when your mosque starts.
   Get a nudge before the congregation.” Language `Segmented` English | العربية (Arabic switches
   the welcome block to RTL Naskh: «نصلّي معًا، في وقتها.» — draft, needs review). “You can
   change it later in Settings.”
2. **Place:** “Where are you?” + approximate-location explanation. **Use my location** →
   spinner “Finding you…” → “Found you near Kuwait City · Method: Kuwait · next Adhan Asr 2:49 PM”
   + “Not right? Choose a city”. **Choose a city**. Continue is blocked until a place exists.
   Failure states (denied, location off, timeout) reuse the existing copy as a quiet line with
   Choose a city still available.
3. **Your mosque:** “Jama’ah means praying together…”, the row of figures with one open place;
   **Find mosques nearby** / **Add one yourself**; after adding, the place fills and “Test
   Mosque added — its Iqama times are not configured yet”. The main button reads **Not now**
   until a mosque exists.
4. **Prayer alerts:** one switch “Alerts for the five prayers”; if on, the note “Android will
   ask if Jama’ah may send notifications…” + **Allow notifications** → “✓ Notifications
   allowed”; battery line with a “Battery settings” link.
5. **Travel:** “Do you travel often?” + explanation, the `TravelSwitch`, “The same switch sits
   at the top of Today.” Then **Start** → Today.

As built (Phase 5, 2026-10-16): the place is required — Continue stays dashed until a place is
found or a city chosen from the bundled list, which works offline (owner). Step 4 keeps
“Ring even when my phone is on silent” under the five-prayer switch (owner). Continue asks for
notifications once if **Allow notifications** was not tapped. The sky glides between the
day's own Fajr, sunrise, Dhuhr, Asr and Maghrib (the reference day before a place exists).

### 4.7 Qibla

- Sky header: “Qibla”, “From Kuwait City · 1,204 km to the Kaaba” (great-circle; Kuwait City →
  Kaaba is 224.6°, shown 225°).
- Live compass: 280 px dial (36 ticks, every third longer, N/E/S/W upright, N bold), the phone’s
  forward notch fixed at the top, a line to a small square (the Kaaba) at the Qibla bearing,
  centre dot. The dial turns with the phone heading. Status: “Turn right 65°” / “Turn left 12°” /
  within ±3°: “You’re facing the Qibla”, the ring thickens and a soft halo appears (and a light
  haptic in the app). Big “225°”, “Hold the phone flat, away from metal and magnets.”
- **Needs calibrating:** a figure-eight with a moving stroke, “The compass needs a moment”,
  instruction, “It’s steady now”.
- **No compass / no sensors:** a fixed dial with the arrow at the bearing, “225°”,
  “South-west, a little more west than south”, “This phone has no compass, so the arrow can’t
  follow you. Line it up with a direction you know, such as where the sun sets.”
- Stays a supporting tab: no extra decoration.

### 4.8 In-flight

The sky is the night/day outside the aircraft at its position, not the phone’s clock.

1. **Start:** “IN FLIGHT”, “Prayer times at 11,000 metres”, “…from your phone’s GPS. It works in
   airplane mode, with no network.”, a plane on a dotted route, **Start GPS**, “Sit by a window if
   you can. The first fix can take a few minutes.” Top right: **How it works** (sheet with four
   numbered points).
2. **Waiting:** pulsing rings, “Looking for satellites”, “2 of 4 satellites”, “Keep the phone
   near a window, screen up. It keeps looking while the screen is off.”, **Cancel**.
3. **Live:** fix line “21.5° N · 62.0° E · GPS fix 20 s ago”, “Aircraft time 9:40 PM (UTC+4),
   from your position”; **Now** Isha “since 7:28 PM” | **Next** Fajr “≈ 4:39 AM · in about 7 h”;
   **Qibla from your seat**: ring with the aircraft nose up and the Qibla line at the relative
   angle, words (“Behind you, to the right · 154°”), **Aircraft heading** number field (“From the
   seat-back map, or ask the crew.”); **Along the route** with an “Estimates” tag; “Times shift as
   the aircraft moves and if the route changes. Alerts in flight say they are estimates.”; **End
   in-flight mode**.

Relative direction words: <15° or >345° straight ahead; 15–75 ahead, to your right; 75–105 to
your right; 105–165 behind you, to the right; 165–195 behind you; 195–255 behind you, to the left;
255–285 to your left; 285–345 ahead, to your left.

### 4.9 Settings (reorganized)

A hub of six rows in three groups; each row shows its current state:

| Group | Row | Summary example | Page contents |
|---|---|---|---|
| Every day | **Prayer times** | Kuwait method · Asr standard | Calculation method (row → method list); Asr `Segmented` Standard / Hanafi; Hijri date `Segmented` −1 day / As calculated / +1 day with the live result and “Match the date your country announces after the moon sighting.”; Extra times on Today: Imsak, Duha, Last third of the night (switches); **Advanced** (collapsed): “Far north or south” (high-latitude rule), “Adjust times by minutes”. |
| | **Adhan alerts** | Short Adhan · 5 of 6 on | Default sound `RadioList` (Full, Short, Standard, Silent with descriptions); Each prayer (rows → `AlertSheet`, “Also from Today: tap the sound beside any prayer.”); Recordings (Full Adhan recording → recordings page; Short Adhan clip); Full-screen Adhan switch. |
| | **Jama’ah reminders** | Test Mosque · Chime | “Iqama times and which prayers remind you are set on each mosque.” + **Open Test Mosque**; Reminder sound `RadioList` (Chime, «حيّ على الصلاة», Standard sound, Silent); Vibrate; **Send a test reminder**; Pause all Jama’ah reminders (“From every mosque. Iqama times are kept, and Adhan alerts carry on.”). |
| Preferences | **Travel** | Off / On · following your location | `TravelSwitch`; Follow my location (greyed out until travel mode is on); In-flight mode row. |
| | **Language and look** | Same as the phone · Same as the phone | Language (Same as the phone / English / العربية); Theme (Same as the phone / Light / Dark); “The sky always follows the time of day. Dark keeps it dimmer.” |
| Help | **Help and about** | Introduction, late alerts, about | Show the introduction again; Alerts arriving late? (battery guidance); Scheduled notifications (the debug list, may stay plain); About text; version. |

Hub footer: “Iqama times live on each mosque, in the Mosques tab, not here.”

Settings pages use a sky header (back, title, one-line lead) and a `SurfacePanel`.

As built (Phase 4, 2026-10-16), beyond the table above:
- Hijri date keeps −2 … +2 days as a `RadioList`, each choice showing the date it gives (owner).
- Extra times: the three show-on-Today switches sit inline; **Alerts and timing** opens their
  page (alerts and minutes) (owner).
- Adhan alerts also holds the two "ring on silent" switches (every Adhan, every reminder before
  it); Jama’ah reminders keeps "Your own sound" beside the four sounds, and its own ring-on-silent.
- Help → **Alerts arriving late?** is a page: battery guidance, then the scheduled list, which
  states any missing permission with one line and the action.
- Sub-pages (method list, far north or south, minutes, extra times, each prayer, recordings,
  scheduled list) use the same sky header and surface; sheets are on `surface`.

### 4.10 Not designed: build from the system

Location sheet and city search, Find nearby (explainer, results labelled by source and
“not verified”, confirm step), Edit mosque details, Remove-mosque confirmation, method list,
high-latitude and minute-adjustment pages, recordings list with preview/stop, scheduled
notifications list. Use: sky header + `SurfacePanel`, `RadioList`/rows/switches, sheets on
`surface`, the same copy tone. States (searching, no results, no network, denied) are one quiet
line plus the next useful action, never an illustration or a red banner.

---

## 5. Arabic and RTL

- The layout mirrors. The sky does not: the SunPath keeps sunrise on the left and sunset on the
  right in both languages, like a picture of the sky, and the Qibla dial is never mirrored.
- Times keep their internal order (“٥:٣٠ م”); Arabic-Indic digits everywhere including the dial
  degrees and the Iqama editor numbers.
- Mosque names typed in English stay LTR inside Arabic (`<bdi>` / `TextDirection` isolation).
- Arabic display text uses Noto Naskh Arabic, UI text Noto Sans Arabic; no italics.
- Strings run longer: buttons wrap to two lines rather than truncate.

## 6. Accessibility checklist

- Touch targets ≥ 48 dp; the arc and the Qibla dial are sliders with value text.
- Alert modes are never told apart by colour: icon + word (Full, Short, Standard, Silent, Off).
- “Not configured” is a dashed outline plus words, not a colour.
- Switch semantics on every switch (including disabled reasons in the label: “available once an
  Iqama time is set”).
- Live regions: countdowns are not announced every second; status lines (“You’re facing the
  Qibla”, “Found you near …”, snackbars) are polite announcements.
- Contrast is checked by the ink rule (§3.2) on sky and by the static tokens on surfaces.
- Reduced motion honoured (§3.6).

## 7. Copy changes to approve (both languages)

| Where | Old | New |
|---|---|---|
| Settings | Higher latitudes | Far north or south |
| Settings | Manual adjustments | Adjust times by minutes |
| Settings | (long section intros) | One line each, as in §4.9 |
| Mosques | — | “There’s a place for you” empty state |
| Onboarding | tagline | “Pray together, on time.” / «نصلّي معًا، في وقتها.» |
| Iqama ticket | — | “Adhan + 20 min · set by you”, “Fixed time · set by you” |

## 8. Still open

1. **App icon / logo / splash:** must express praying together at the mosque. Concepts on the
   canvas: *Saff* (the row, one place lit for you), *Mihrab* (your mosque’s arch with the
   congregation), *Together* (rows around one centre). Not decided; revisit after the screens.
   Splash follows the chosen icon (Android 12 rules: icon on a plain background).
2. Arabic review of all new strings.
3. Font bundle size check (aim: only the weights in §2.1).
4. Real-device check that the sky + stars + grain stay smooth on a mid-range Android phone
   (Samsung A53 is the owner’s test device).
5. **Before release:** an in-app licences page with the Lucide icon licence
   (`docs/licences/lucide-LICENSE.txt`) and the four fonts’ OFL (`assets/fonts/licences/`).

## 9. Suggested build order

1. **Foundations:** bundle fonts; tokens as a `ThemeExtension` (surface tokens, type scale);
   domain `SkyModel` (keyframes anchored to the day, ink rule, stars), `SunPathGeometry`, `MoonPhase`,
   relative-direction words, with unit tests (contrast test across sample days).
2. **Today:** `SkyBackground` painter, `SunPath` (with drag), hero, `IqamaTicket`, rows with alert
   buttons, `AlertSheet`, `TravelSwitch`, snackbar; four-tab nav with Settings in it.
3. **Mosques:** tab + empty state, mosque page, Iqama editor (both modes; data model per AGENTS.md).
4. **Settings:** hub and the six pages; move existing sub-pages under them.
5. **Onboarding, Qibla, In-flight, Full-screen Adhan.**
6. **Pass:** Arabic/RTL, 2× text, TalkBack, reduced motion, dark theme, golden tests per screen.
