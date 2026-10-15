# Custom Adhan and Jama’ah reminder sounds — design and plan

Agreed 2026-10-15. Users can add audio files from their phone and use them
alongside the bundled sounds.

## Behaviour

- **Adding:** "Add from your phone" opens Android's document picker (audio/*).
  The file is copied into the app's own storage (`files/sounds/<uuid>.<ext>`),
  named after the original file; it can be renamed and deleted. No storage
  permission: the picker grants only the chosen file.
- **Custom Adhan:** the Full Adhan recording page gets a "Your recordings"
  section (play/stop, choose, rename, delete) above the 17 bundled ones. Each
  prayer's page gets a "Recording" row: "Same as in Settings" (default) or any
  recording, used whenever that prayer plays a Full Adhan. Plays to the end;
  Stop, volume keys and face-down stop it as now.
- **Custom Jama’ah reminder:** "Your own sound" joins Chime / حيّ على الصلاة /
  Standard / Silent and picks (or replaces) the file. Used by all Jama’ah
  reminders and the extra-time alerts. Stops after 30 seconds.
- **Playback:** custom sounds always play through the app's own player
  (AdhanService); Android cannot use an arbitrary file as a channel sound.
  Ring on silent picks the alarm stream as before.
- **Fallbacks:** a deleted sound that is still chosen falls back to the bundled
  default (Naghshbandi / Chime); a file that fails to play at alert time falls
  back to the bundled short Adhan or chime, so an alert is never silent.

## Data (no schema change)

- `app_settings`: `custom_sounds` = JSON list `[{id, name, path}]`;
  `adhan_recording_<prayer>` per-prayer recording override;
  `jamaah_reminder_custom_sound` = the reminder's custom sound id.
- Ids: bundled recordings keep their ids; custom ones are `custom:<uuid>`.
- `AdhanAlertSettings.customRecordings` and
  `JamaahReminderSettings.customSound` are filled in on read, so the planner
  and the gateway need no new inputs.

## Plan (executed inline, TDD per task)

1. Domain: `CustomSound`, recording resolution (`recordingFor(prayer)`,
   `recordingSourceFor(prayer)` with fallback), `AdhanAlert.recording`,
   `ReminderSound.custom` + `JamaahReminderSettings.customSound`; planner and
   `playsInApp` / `inAppSound` (file + 30 s cap for reminders).
2. Storage: repository read/write of the keys above; add / rename / delete with
   clean-up of anything that used a deleted sound.
3. Native: picker + copy (`dev.jamaah.app/sounds`), AdhanService plays a file
   path, caps `maxSeconds`, falls back to the bundled sound on failure.
4. UI: recordings page section, per-prayer Recording row (page in "for one
   prayer" mode), reminder sheet choice; preview plays files. EN + AR strings.
5. Device check with a real file and the app closed; docs; report.
