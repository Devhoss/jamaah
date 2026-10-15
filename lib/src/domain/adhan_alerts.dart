import 'iqama_editing.dart';
import 'adhan_recordings.dart';
import 'custom_sounds.dart';
import 'prayer.dart';

/// How a reminder sounds, when it is enabled at all.
///
/// `enabled = false` is a separate thing from any mode: no notification is shown.
/// - [full]: the whole Adhan recording.
/// - [short]: the opening of the Adhan only.
/// - [standard]: the platform's default notification sound, no bundled audio.
/// - [silent]: the notification is still shown, but makes no sound. On Android it
///   needs its own channel with sound disabled, because a channel's sound is fixed
///   at creation.
enum AdhanSoundMode { full, short, standard, silent }

extension AdhanSoundModeX on AdhanSoundMode {
  String get storageKey => name;

  static AdhanSoundMode fromStorageKey(String? key) =>
      AdhanSoundMode.values.firstWhere(
        (m) => m.name == key,
        orElse: () => AdhanSoundMode.standard,
      );
}

/// Global, per-prayer Adhan alerts. Completely independent of Iqama reminders,
/// which live on individual mosques (AGENTS.md).
class AdhanAlertSettings {
  const AdhanAlertSettings({
    this.defaultSoundMode = AdhanSoundMode.standard,
    this.alerts = const {},
    this.fullScreen = false,
    this.fullRecording = kDefaultAdhanRecording,
    this.shortAdhan = ShortAdhan.naghshbandi,
    this.customRecordings = const [],
  });

  /// Starting point used for a fresh install: nothing enabled.
  factory AdhanAlertSettings.defaults() => const AdhanAlertSettings();

  final AdhanSoundMode defaultSoundMode;

  /// Show the Adhan as a full-screen page with a Stop button when the phone is
  /// idle, instead of only a notification. Off by default: it takes over the
  /// screen, which is the user's call to make.
  final bool fullScreen;

  /// Per-prayer alerts. Absent entries mean "disabled, use the default mode".
  final Map<Prayer, AdhanAlert> alerts;

  /// Which bundled recording "Full Adhan" plays ([AdhanRecording.id]), for
  /// every prayer.
  final String fullRecording;

  /// Which clip "Short Adhan" plays, for every prayer. It is also the channel
  /// sound of a full Adhan's notification.
  final ShortAdhan shortAdhan;

  /// The user's own sounds (2026-10-15), filled in when the settings are read
  /// so a recording id can be resolved anywhere. Not saved with the alerts.
  final List<CustomSound> customRecordings;

  /// The recording [prayer]'s Full Adhan plays: its own, or the one for all.
  String recordingFor(Prayer prayer) =>
      alertFor(prayer).recording ?? fullRecording;

  /// What that recording plays, falling back to the bundled default when the
  /// user's sound was deleted.
  ({String name, String source, bool fallback}) recordingSourceFor(
    Prayer prayer,
  ) => resolveRecording(recordingFor(prayer), customRecordings);

  AdhanAlertSettings copyWith({
    AdhanSoundMode? defaultSoundMode,
    Map<Prayer, AdhanAlert>? alerts,
    bool? fullScreen,
    String? fullRecording,
    ShortAdhan? shortAdhan,
    List<CustomSound>? customRecordings,
  }) => AdhanAlertSettings(
    defaultSoundMode: defaultSoundMode ?? this.defaultSoundMode,
    alerts: alerts ?? this.alerts,
    fullScreen: fullScreen ?? this.fullScreen,
    fullRecording: fullRecording ?? this.fullRecording,
    shortAdhan: shortAdhan ?? this.shortAdhan,
    customRecordings: customRecordings ?? this.customRecordings,
  );

  /// The alert for [prayer]. Sunrise stays disabled unless explicitly turned on.
  AdhanAlert alertFor(Prayer prayer) =>
      alerts[prayer] ?? const AdhanAlert(enabled: false);

  AdhanAlertSettings withAlert(Prayer prayer, AdhanAlert alert) =>
      copyWith(alerts: {...alerts, prayer: alert});

  AdhanAlertSettings withSoundMode(AdhanSoundMode mode) =>
      copyWith(defaultSoundMode: mode);

  /// Sound that actually plays for [prayer]: the per-prayer override if set,
  /// otherwise the global default.
  AdhanSoundMode soundModeFor(Prayer prayer) =>
      alertFor(prayer).soundModeOverride ?? defaultSoundMode;

  List<Prayer> get enabledPrayers =>
      Prayer.adhanPrayers.where((p) => alertFor(p).enabled).toList();

  bool get hasAnyEnabled => enabledPrayers.isNotEmpty;

  /// Whether [target] rings on silent for all six prayers, none or some: the
  /// one switch in Settings reads this (2026-10-14).
  RingCoverage ringInSilentFor(RingTarget target) {
    final on = Prayer.adhanPrayers.where((p) => _rings(alertFor(p), target));
    return switch (on.length) {
      0 => RingCoverage.none,
      final n when n == Prayer.adhanPrayers.length => RingCoverage.all,
      _ => RingCoverage.some,
    };
  }

  /// [target] set to ring on silent, or not, for every prayer at once. Each
  /// prayer's page can still change its own afterwards.
  AdhanAlertSettings withRingInSilentForAll(
    RingTarget target, {
    required bool on,
  }) {
    var next = this;
    for (final p in Prayer.adhanPrayers) {
      final a = alertFor(p);
      next = next.withAlert(
        p,
        switch (target) {
          RingTarget.adhan => a.copyWith(ringInSilent: on),
          RingTarget.preAdhan => a.copyWith(preAdhanRingInSilent: on),
        },
      );
    }
    return next;
  }

  static bool _rings(AdhanAlert a, RingTarget target) => switch (target) {
    RingTarget.adhan => a.ringInSilent,
    RingTarget.preAdhan => a.preAdhanRingInSilent,
  };

  @override
  bool operator ==(Object other) =>
      other is AdhanAlertSettings &&
      other.defaultSoundMode == defaultSoundMode &&
      other.fullScreen == fullScreen &&
      other.fullRecording == fullRecording &&
      other.shortAdhan == shortAdhan &&
      _sameAlerts(other.alerts, alerts) &&
      _sameSounds(other.customRecordings, customRecordings);

  @override
  int get hashCode =>
      Object.hash(
        defaultSoundMode,
        fullScreen,
        fullRecording,
        shortAdhan,
        alerts.length,
      );
}

/// What rings on silent: the Adhan, or the reminder before it.
enum RingTarget { adhan, preAdhan }

/// How many of the six prayers ring on silent.
enum RingCoverage { none, some, all }

bool _sameSounds(List<CustomSound> a, List<CustomSound> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameAlerts(Map<Prayer, AdhanAlert> a, Map<Prayer, AdhanAlert> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// One prayer's alert config.
///
/// [enabled] decides whether the Adhan alert exists at all. The reminder before
/// the Adhan is a separate, optional notification, so it works whether or not
/// the Adhan alert itself is on.
class AdhanAlert {
  const AdhanAlert({
    required this.enabled,
    this.soundModeOverride,
    this.vibrate = true,
    this.preAdhanMinutes,
    this.ringInSilent = false,
    this.preAdhanRingInSilent = false,
    this.recording,
  }) : assert(
         preAdhanMinutes == null ||
             (preAdhanMinutes >= ReminderInterval.minMinutes &&
                 preAdhanMinutes <= ReminderInterval.maxMinutes),
       );

  final bool enabled;

  /// Null means "use the global default mode".
  final AdhanSoundMode? soundModeOverride;

  /// Whether the alert also vibrates. A silent alert with vibration off is shown
  /// without any sound or buzz.
  final bool vibrate;

  /// Minutes before the Adhan for a heads-up notification; null means none.
  final int? preAdhanMinutes;

  /// Play the Adhan even when the phone is on silent, through the alarm volume.
  /// Off by default, so the app never surprises anyone in a quiet room.
  final bool ringInSilent;

  /// The same for the reminder before the Adhan, on its own (2026-10-14).
  final bool preAdhanRingInSilent;

  /// This prayer's own Full Adhan recording (2026-10-15); null plays the one
  /// chosen for every prayer.
  final String? recording;

  bool get hasPreAdhanReminder => preAdhanMinutes != null;

  AdhanAlert copyWith({
    bool? enabled,
    AdhanSoundMode? soundModeOverride,
    bool clearOverride = false,
    bool? vibrate,
    int? preAdhanMinutes,
    bool clearPreAdhan = false,
    bool? ringInSilent,
    bool? preAdhanRingInSilent,
    String? recording,
    bool clearRecording = false,
  }) => AdhanAlert(
    enabled: enabled ?? this.enabled,
    soundModeOverride: clearOverride
        ? null
        : (soundModeOverride ?? this.soundModeOverride),
    vibrate: vibrate ?? this.vibrate,
    preAdhanMinutes: clearPreAdhan
        ? null
        : (preAdhanMinutes ?? this.preAdhanMinutes),
    ringInSilent: ringInSilent ?? this.ringInSilent,
    preAdhanRingInSilent: preAdhanRingInSilent ?? this.preAdhanRingInSilent,
    recording: clearRecording ? null : (recording ?? this.recording),
  );

  @override
  bool operator ==(Object other) =>
      other is AdhanAlert &&
      other.enabled == enabled &&
      other.soundModeOverride == soundModeOverride &&
      other.vibrate == vibrate &&
      other.preAdhanMinutes == preAdhanMinutes &&
      other.ringInSilent == ringInSilent &&
      other.preAdhanRingInSilent == preAdhanRingInSilent &&
      other.recording == recording;

  @override
  int get hashCode => Object.hash(
    enabled,
    soundModeOverride,
    vibrate,
    preAdhanMinutes,
    ringInSilent,
    preAdhanRingInSilent,
    recording,
  );
}

/// Reminder and travel preferences that are not per prayer.
///
/// [travelMode] (2026-10-13) is one switch, on the top bar and in Settings, that
/// turns on the travel options; today that is [followLocation], and more may
/// join it. An option only acts while travel mode is on.
///
/// [pauseAllIqamaReminders] (2026-10-13) stops every Iqama reminder at once;
/// each mosque can also be paused on its own ([Mosque.remindersPaused]). Adhan
/// alerts are never paused by either.
class TravelSettings {
  const TravelSettings({
    this.travelMode = false,
    this.followLocation = true,
    this.pauseAllIqamaReminders = false,
  });

  final bool travelMode;

  /// Travel option: refresh the place from the device when the app opens.
  final bool followLocation;

  /// Whether the place follows the device right now.
  bool get followsLocation => travelMode && followLocation;

  /// No Iqama reminders at all, whichever mosque is active. Iqama times and
  /// reminder settings are kept.
  final bool pauseAllIqamaReminders;

  TravelSettings copyWith({
    bool? travelMode,
    bool? followLocation,
    bool? pauseAllIqamaReminders,
  }) => TravelSettings(
    travelMode: travelMode ?? this.travelMode,
    followLocation: followLocation ?? this.followLocation,
    pauseAllIqamaReminders:
        pauseAllIqamaReminders ?? this.pauseAllIqamaReminders,
  );

  @override
  bool operator ==(Object other) =>
      other is TravelSettings &&
      other.travelMode == travelMode &&
      other.followLocation == followLocation &&
      other.pauseAllIqamaReminders == pauseAllIqamaReminders;

  @override
  int get hashCode =>
      Object.hash(travelMode, followLocation, pauseAllIqamaReminders);
}

/// What a Jama’ah (Iqama) reminder plays (2026-10-13). [chime] is the app's
/// own two-note chime; [hayya] the «حيّ على الصلاة» clip; [standard] the
/// phone's notification sound; [silent] shows the reminder without a sound.
enum ReminderSound { chime, hayya, standard, silent, custom }

/// How every Jama’ah reminder sounds. One global setting: the reminders
/// themselves (which prayers, how early) stay on each mosque.
class JamaahReminderSettings {
  const JamaahReminderSettings({
    this.sound = ReminderSound.chime,
    this.vibrate = true,
    this.ringInSilent = false,
    this.customSound,
  });

  final ReminderSound sound;
  final bool vibrate;

  /// The user's own sound for [ReminderSound.custom] (2026-10-15).
  final CustomSound? customSound;

  /// The file to play: only for [ReminderSound.custom] with its sound still
  /// there. Without it the reminder is the chime.
  String? get customSoundPath =>
      sound == ReminderSound.custom ? customSound?.path : null;

  /// Play through the alarm volume, so it is heard with the phone on silent
  /// (2026-10-14). The extra-time alerts, which share this sound, follow it.
  final bool ringInSilent;

  JamaahReminderSettings copyWith({
    ReminderSound? sound,
    bool? vibrate,
    bool? ringInSilent,
    CustomSound? customSound,
  }) => JamaahReminderSettings(
    sound: sound ?? this.sound,
    vibrate: vibrate ?? this.vibrate,
    ringInSilent: ringInSilent ?? this.ringInSilent,
    customSound: customSound ?? this.customSound,
  );

  @override
  bool operator ==(Object other) =>
      other is JamaahReminderSettings &&
      other.sound == sound &&
      other.vibrate == vibrate &&
      other.ringInSilent == ringInSilent &&
      other.customSound == customSound;

  @override
  int get hashCode => Object.hash(sound, vibrate, ringInSilent, customSound);
}
