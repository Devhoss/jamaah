# Jama’ah — design brief

> **Outcome (2026-10-15):** the agreed redesign is “Horizon”. Build from
> [`horizon-spec.md`](horizon-spec.md); this brief stays as the original request.

For a complete redesign of the app, its logo, app icon and splash screen.
What exists today is a working prototype: every screen works and is tested,
but the look was never designed. Screenshots of the current app are in
`screens/` (Android phone, dark theme, 12-hour clock, 1080 × 2400).

## The app in one line

**Know when to pray. Know when your mosque starts. Get reminded on time.**

A minimal prayer companion for Android, for users in Kuwait first (Arabic and
English). It must feel calm, fast and trustworthy, never like an overloaded
"Islamic super-app". Prayer times are worked out on the phone; there is no
account and nothing is uploaded.

People it is for: someone who prays at a regular mosque and wants its
Iqama times and a reminder before them; and people who travel a lot,
including cabin crew (travel mode, in-flight mode).

## What to design

1. **The app's visual language**: type, colour, spacing, components, light
   and dark themes, motion (quiet transitions only).
2. **Every screen and state** listed below, in English (left to right) and
   Arabic (right to left).
3. **Logo, app icon (Android adaptive icon), splash screen.** The current
   "Jama’ah" wordmark at the top left of the app is a placeholder: it will be
   removed or replaced by the icon/logo you design.

## Rules the design must keep

These are product rules, not style preferences. A design that breaks one
cannot be built.

- **Adhan and Iqama are separate things and must look separate.**
  - The Adhan time is calculated.
  - The Iqama is when the mosque's congregation starts. It belongs to one
    mosque and is entered by the user.
  - The Iqama is never filled in, guessed or copied from the Adhan.
- **"Not configured" is a normal state.** A new mosque has every Iqama time
  (and its Jumu’ah time) "Not configured". It needs a clear, calm look: not an
  error, not an empty field.
- **Three different things must never look alike:**
  - **Standard sound:** the phone's own notification sound.
  - **Silent:** the notification still appears, with no sound.
  - **Off:** no notification at all.
- **Sunrise** is shown with the prayers but is not one: it never has an Iqama.
- **Extra times** (Imsak, Duha, last third of the night) are quieter than
  the prayers. They never have an Iqama, a countdown or the "Next" mark.
- **Nothing is presented as verified.** Mosques found online show their
  source (Google / OpenStreetMap) and are not verified.
- **Avoid:** gold gradients, mosque silhouettes everywhere, ornate decorative
  patterns, glassmorphism, stacked floating cards, streaks, badges, feeds,
  gamification.
- **Accessibility:**
  - touch targets of at least 48 dp;
  - must work at 2× text size;
  - screen-reader friendly;
  - no meaning carried by colour alone.

## Language and direction

- **English and Arabic** (Modern Standard Arabic). Arabic is right to left
  and uses Arabic-Indic digits (٠١٢٣), including all times.
- **Default language** is the phone's; it can be changed in Settings.
- **Arabic strings run longer.** At 2× text size the onboarding buttons
  already wrap onto two lines.
- **Typefaces:** a bundled Arabic font is planned (Noto Sans Arabic, OFL).
  Please choose the Latin and Arabic typefaces as a pair.
- **Wordmark:** the app name is «جماعة» in Arabic.
- **Copy:** all copy lives in translation files. If you want different wording,
  list it separately from the visuals so it can be changed in both languages.

## Current visual language (for reference only: replace all of it)

This is a full redesign, colours included. Nothing below has to survive: the
palette, the green, the type sizes, the radii and the spacing are all open.
They are listed only so you can see what the screenshots are made of.

| Token | Light | Dark |
|---|---|---|
| Background | #FAF7F0 (warm off-white) | #0F1713 |
| Surface | #FFFDF8 | #17221B |
| Ink | #1B2A22 | #E8EFE9 |
| Muted | #6B7A70 | #93A398 |
| Primary | #1F4D3A (deep forest green) | #3F8F69 |
| Sage | #DCE6DA | #223A2D |
| Warning ("Not configured") | #B8741A on #F3E3C8 | #D89A45 on #3A2E17 |

- **Radii:** hero 22, card 18, sheet 24.
- **Spacing:** 4/8/12/16/20/24.
- **Type sizes:** title 28, row 17, body 14, hero time 40.
- **Themes:** both light and dark are needed. Most of the owner's testing is
  in dark.
- **Earlier exploration:** an interactive prototype is in
  `docs/prayer-prototype.html`. It is useful for tone. Its sample mosques and
  times are invented and must not appear in designs.

## Screens and states

Shots marked † are in `screens/`. Everything else is a state to design that
the shots don't show.

### Today (main tab)
- † `00-loading`: the moment before the day is read.
- † `01-today-top`, † `02-today-rows`.
- **Header:** the date at the place, with the Hijri date under it.
- **Place chip:** the current place; opens the location sheet.
- **Hero card:**
  - the next prayer's Adhan time and a countdown;
  - under a divider, the active mosque's next Iqama, its countdown, and
    whether its reminder is on;
  - the next prayer can be tomorrow's (marked "Tomorrow").
- **Prayer rows:** six rows (Fajr, Sunrise muted, Dhuhr, Asr, Maghrib, Isha).
  Each row shows:
  - the Adhan time on the right;
  - the mosque's Iqama, small, beside the name;
  - a bell when its reminder is on;
  - "Next" on the next prayer;
  - a highlight on the prayer in force.
- **Extra-time rows** (optional, chosen in Settings): Imsak above Fajr, Duha
  after Sunrise, last third of the night after Isha. Quiet, no Iqama.
- **Iqama card states:**
  - a time ahead;
  - none left today;
  - nothing entered (a prompt to add or set up a mosque instead);
  - no mosque yet.
- **Fridays:** Dhuhr is called **Jumu’ah** and shows the mosque's Jumu’ah
  time. If none is set, the card and row say "Jumu’ah time not set" and fall
  back to the Dhuhr Iqama.
- **Notes that can appear:**
  - **High-latitude rule:** it moved Fajr or Isha.
  - **Polar day/night:** times are estimated from another latitude.
  - **No times at all:** a day the place can't compute.
  - **Clock mismatch:** the place's time zone differs from the phone's clock
    ("Times are local time in Cairo (UTC+3). Your phone's clock is on
    UTC+4.").
  - **Reminders paused:** for this mosque, or all.
  - **"Following your location":** in travel mode, with when it last checked.
  - **In-flight hold:** "your alerts are paused until …", with an End button.
- **No place yet:** a prompt to set a location.
- **Error:** settings can't be read; a "Try again" button.
- **Travel mode on:** an "On a flight?" card († `20-travel-on-today`).

### Location sheet († `03-location-sheet`)
- **Use my location:**
  - while it searches: a spinner;
  - when found: "Found you near Cairo";
  - when it fails: denied, location off, or timeout.
- **Choose a city:** from a searchable bundled list.
- **Preview another city:** look without changing your place.
- **Name this place:** the user's own label.

### Mosques tab († `04-mosques-tab`)
- **List:** saved mosques, with the active one tagged and "3 of 5 Iqama set".
- **Add:** Find nearby, or add manually.
- **Empty state:** no mosques yet.
- **Paused tag:** a mosque whose reminders are paused.

### Mosque page († `05-mosque-detail-1`, `-2`)
- **Header:** name, source ("Added by you", "From Google Maps", "From
  OpenStreetMap"),
  Active tag or "Make active", Edit details.
- **Pause:** a switch for this mosque's Jama’ah reminders.
- **Iqama schedule:** Fajr, Dhuhr, Asr, Maghrib, Isha, then **Jumu’ah**
  ("Fridays, in place of Dhuhr"). Each row shows:
  - the Adhan time (small);
  - the Iqama or "Not configured";
  - the reminder line ("Reminder at 5:26 AM" / "Reminder off" / "Set an Iqama
    time to add a reminder");
  - a reminder switch, disabled until a time exists.
- **Footer:** "Set by you · last updated <date>", Remove mosque (with a
  confirmation).

### Iqama editor (bottom sheet, † `06-iqama-editor`)
- **Title:** "Maghrib Iqama · Editing Test Mosque".
- **Time field:** shows "Adhan 6:26 PM · tap to set". The time picker starts at
  the Adhan only as a convenience; nothing is saved until the user picks a time.
- **Reminder:** "Remind me before Iqama", with 5/10/15/20/30 minutes or Custom
  (and its validation messages).
- **Summary line:** "Reminder at 6:21 PM".
- **Buttons:** Cancel / Save / Clear time.

### Find nearby († `07-find-nearby-explainer`)
- **Explainer:** shown first, then a request for precise location.
- **Or search around a city.**
- **Results:** a list labelled by source and "not verified"; a confirm step
  before saving (the user confirms name and address).
- **States:** searching, no results, no network, location denied.

### Qibla tab († `08-qibla`)
- **Compass:** an arrow towards Makkah, with the bearing and the distance
  ("… km to the Kaaba").
- **Calibration prompt:** shown when the compass is unreliable.
- **Fallback:** a static bearing when there is no compass or location.
- **Prominence:** a supporting feature, never dominant.

### Settings († `10-settings-1` … `-4`)
- **Prayer times:**
  - method (25 methods + Auto detect + Custom angles);
  - Asr method;
  - higher latitudes;
  - manual adjustments;
  - Hijri date adjustment;
  - **Extra times** († `12-settings-extra-times`).
- **Adhan alerts:**
  - default sound;
  - short Adhan clip;
  - full Adhan recording († `14-adhan-recordings`: 17 recordings, with
    preview/stop);
  - a page per prayer († `13-prayer-alert-fajr`: alert on/off, sound with
    previews, vibrate, ring on silent, reminder before the Adhan);
  - full-screen Adhan.
- **Jama’ah reminders:**
  - a pointer to the active mosque;
  - the reminder sound (chime / «حيّ على الصلاة» / standard / silent) and
    vibrate, plus a test button;
  - pause all.
- **Travel:** travel mode, follow my location.
- **Appearance:** language, theme.
- **Notifications:** scheduled notifications († `16-scheduled-notifications`,
  a debug-style list that may stay plain).
- **Show the introduction again**, and a short About text.

### Onboarding († `30-onboarding-1` … `-5`)
1. **Welcome:** tagline, language choice.
2. **Place:** use my location, or choose a city; then "Found you near …".
3. **Your mosque:** add one, or Not now.
4. **Prayer alerts:** a switch for all five, the permission request, and battery
   guidance.
5. **Travel:** "Do you travel often?", with a travel-mode switch.

Step counter, Back / Continue / Not now / Start.

### Travel and in-flight
- **Top bar:** the airplane icon beside the gear toggles travel mode, with a
  snackbar.
- **In-flight screen** († `21-in-flight`):
  - Start GPS;
  - waiting for a fix (sit by a window);
  - "Now" and "Next" prayer for where the aircraft is;
  - the next prayers estimated along the route (marked as estimates);
  - the Qibla relative to the aircraft's nose (a heading can be typed in);
  - End in-flight mode.
- **How it works** page († `22-in-flight-help`).

### Full-screen Adhan (shown over the lock screen)
- **Content:** prayer name and time, a large Stop button.
- **Controls:** the volume keys and flipping the phone also stop it.
- **No screenshot:** it only appears when an alert fires.

### Notifications (system UI: only the wording can change)
- **Adhan:** "Fajr" / "It's time for Fajr" (Sunrise has its own wording).
- **Reminder before the Adhan.**
- **Jama’ah reminder:** title «حيّ على الصلاة», body "Asr Iqama in 10 min, at
  <mosque>".
- **Extra times:** "Last third of the night" / "The last third of the night
  has begun."
- **In flight:** marked as an estimate.

### Arabic († `40-ar-today`, `40-ar-today-rows`, `41-ar-settings`, `42-ar-mosque-detail`)
- **Layout:** mirrored. Times keep their order inside the number ("٥:٣٠ ص").
- **Mixed text:** mosque names entered in English stay left-to-right inside
  Arabic text.

## Branding to deliver

- **App icon:**
  - Android adaptive icon (foreground + background layers);
  - a monochrome version for Android 13 themed icons;
  - a small notification icon (white, single colour).
- **Splash screen:** Android 12+ uses the icon on a plain background.
- **Logo:** to replace the "Jama’ah" text at the top of the app, or nothing
  there at all.
- **Name:** "Jama’ah" (with the typographic apostrophe ’), «جماعة» in Arabic.
  The logo should work for both.

## Open questions for the owner

- The Arabic wording is a draft awaiting review: see
  `docs/arabic-strings-review.md`.
- Light first or dark first for the store screenshots.
