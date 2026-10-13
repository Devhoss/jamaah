# Adhan audio — source and licence

**Status (2026-10-13): 17 recordings supplied by the project owner. Their source
and licence are NOT yet recorded. Clear both before any public release
(AGENTS.md open question 1).**

| File | What it is | Used for |
| --- | --- | --- |
| `assets/audio/*.mp3` (17 files) | full Adhan recordings, mono, 11 kHz, 8 kbps, 1:36–5:47 | the user's choice in Settings → Full Adhan recording; preview, and played by the app's Adhan service straight from the APK's `flutter_assets/` |
| `android/app/src/main/res/raw/adhan_short.ogg` | the first 8 s of `Naghshbandi.mp3` (the opening phrase ends at 7.5 s), 0.6 s fade-out, Vorbis 22 kHz mono | notification-channel sound for "Short" and "Full" alerts |
| `assets/audio/short/adhan_short.ogg` | the same file, byte for byte | preview of "Short" in Settings |

The list the app shows lives in `lib/src/domain/adhan_recordings.dart` (id,
name, file, length). Ids are stored in settings, so never rename one.

To record for each file before release: reciter or mosque, where it was
downloaded from (URL), the licence text, and any attribution it requires.
None of the 17 is marked as a Fajr Adhan (with "as-salatu khayrun min an-nawm").

The short clip was made with:

    ffmpeg -i assets/audio/Naghshbandi.mp3 -t 8 -af "afade=t=out:st=7.4:d=0.6"       -ar 22050 -ac 1 -c:a libvorbis -q:a 4 android/app/src/main/res/raw/adhan_short.ogg

The earlier generated placeholder tones and their generator were removed.

## Other candidates with a known licence

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

## Adding or changing a recording

1. Put the file in `assets/audio/` and add it to `adhanRecordings`.
2. For a new short Adhan, cut it as above into both short files (they must stay
   identical; a test checks), then bump `kAdhanToneVersion` in
   `lib/src/domain/notification_channels.dart`. Android fixes a channel's sound
   when the channel is created, so a new version creates new channels and the
   app retires the old ones. A full recording needs no version bump: the app
   plays it itself.
3. Record its source and licence here.
