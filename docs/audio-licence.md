# Adhan audio — source and licence

**Status: the app ships generated PLACEHOLDER tones, not an Adhan.**

| File | What it is | Used for |
| --- | --- | --- |
| `android/app/src/main/res/raw/adhan_short_placeholder.wav` | 6 s synthesised chime | notification-channel sound for "Short" and "Full" alerts |
| `assets/audio/adhan_short_placeholder.wav` | the same chime | preview in Settings |
| `assets/audio/adhan_full_placeholder.wav` | the chime four times, ~37 s | preview of the full Adhan in Settings |
| `android/app/src/main/res/raw/adhan_full_placeholder.wav` | the same | the full Adhan played by the app's Adhan service |

They are made by `tool/generate_placeholder_tones.dart` (soft sine tones), so
there is no third-party content and nothing to license.

## Choosing the real recording (open decision, AGENTS.md)

Candidates found on Wikimedia Commons (checked 2026-10-13):

- `File:Beautiful adhan.ogg`: CC0, 2:34. Best full-length candidate; may be
  trimmed for "Short" with no attribution required.
- `File:Adhan.ogg`: CC0, 0:42. Possible "Short" on its own.
- `File:The Adhan - Muslim Call to Prayer - Aaqib Azeez.mp3`: CC BY-SA 4.0, 1:27.
  Needs attribution in About; a trimmed version stays CC BY-SA.
- `File:Azan.ogg`: CC BY-SA 4.0, 3:03.

Not usable without written permission: the recordings listed on
praytimes.org/docs/adhan (no licence stated; the site's licence covers its code).

None of these is a Fajr Adhan (with "as-salatu khayrun min an-nawm").

Commons relies on the uploader's own-work claim: listen to each candidate and check
the uploader before shipping.

## Swapping a recording in

1. Fill in, here: the recording (reciter, mosque, duration, cut point for Short),
   source URL, exact licence text, and any attribution the licence requires.
2. Replace the four files above, keeping their names (convert to WAV or OGG).
3. Bump `kAdhanToneVersion` in `lib/src/domain/notification_channels.dart`.
   Android fixes a channel's sound when the channel is created, so a new version
   creates new channels and the app retires the old ones.
